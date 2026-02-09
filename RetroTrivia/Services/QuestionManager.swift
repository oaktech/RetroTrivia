import Foundation

/// Manages the pool of trivia questions with CloudKit, cache, and bundled fallback
@Observable
class QuestionManager {
    // MARK: - Properties

    /// Active pool of questions (20-30 questions maintained)
    private(set) var questionPool: [TriviaQuestion] = []

    /// Set of question IDs that have been asked this session
    private var askedQuestionIDs: Set<String> = []

    /// CloudKit service for fetching online questions
    private let cloudKitService = CloudKitQuestionService()

    /// Legacy Open Trivia DB API service (fallback)
    private let openTriviaService = TriviaAPIService()

    /// Local cache manager for offline support
    private let cacheManager = QuestionCacheManager()

    /// User filter preferences
    var filterConfig: FilterConfiguration {
        didSet {
            filterConfig.save()
        }
    }

    /// Bundled questions cache (emergency fallback)
    private var bundledQuestions: [TriviaQuestion] = []

    /// Minimum pool size before refilling
    private let minPoolSize = 10

    /// Target pool size
    private let targetPoolSize = 25

    /// Maximum pool size
    private let maxPoolSize = 30

    /// Current question source for debugging
    private(set) var currentSource: QuestionSource = .bundle

    // MARK: - Initialization

    init() {
        self.filterConfig = FilterConfiguration.load()
        self.bundledQuestions = TriviaQuestion.loadFromBundle()
        print("DEBUG: QuestionManager initialized with \(bundledQuestions.count) bundled questions")
    }

    // MARK: - Public Methods

    /// Load initial questions into the pool
    func loadQuestions() async {
        print("DEBUG: Loading questions (online: \(filterConfig.enableOnlineQuestions), difficulty: \(filterConfig.difficulty.displayName))")

        if filterConfig.enableOnlineQuestions {
            // Priority 1: Try CloudKit first (uses random sampling for large datasets)
            do {
                let questions = try await cloudKitService.fetchRandomQuestions(
                    count: targetPoolSize,
                    difficulty: filterConfig.difficulty.apiValue,
                    excludeIDs: askedQuestionIDs
                )

                questionPool = questions
                currentSource = .cloudKit
                cacheManager.cacheQuestions(questions, forDifficulty: filterConfig.difficulty.apiValue)
                print("DEBUG: Loaded \(questionPool.count) questions from CloudKit")
                return
            } catch {
                print("DEBUG: CloudKit fetch failed: \(error.localizedDescription), trying Open Trivia DB")
            }

            // Priority 2: Try Open Trivia DB API as secondary online source
            do {
                let questions = try await openTriviaService.fetchQuestions(
                    amount: targetPoolSize,
                    category: 12, // Music
                    difficulty: filterConfig.difficulty.apiValue
                )

                questionPool = questions
                currentSource = .api
                cacheManager.cacheQuestions(questions, forDifficulty: filterConfig.difficulty.apiValue)
                print("DEBUG: Loaded \(questionPool.count) questions from Open Trivia DB")
                return
            } catch {
                print("DEBUG: Open Trivia DB fetch failed: \(error.localizedDescription), falling back to cache")
            }
        }

        // Priority 3: Try local cache
        let cached = cacheManager.getCachedQuestions(
            count: targetPoolSize,
            difficulty: filterConfig.difficulty.apiValue
        )
        if !cached.isEmpty {
            questionPool = cached
            currentSource = cached.first?.source ?? .bundle
            print("DEBUG: Loaded \(questionPool.count) questions from cache")
            return
        }

        // Priority 4: Fallback to bundled questions
        loadBundledQuestions()
    }

    /// Get the next unanswered question from the pool
    func getNextQuestion() -> TriviaQuestion? {
        // Auto-refill pool if running low
        if questionPool.count < minPoolSize {
            Task {
                await refillQuestionPool()
            }
        }

        // Find first unanswered question
        guard let nextQuestion = questionPool.first(where: { !askedQuestionIDs.contains($0.id) }) else {
            print("DEBUG: No unanswered questions available in pool")
            return nil
        }

        return nextQuestion
    }

    /// Mark a question as asked in this session
    func markQuestionAsked(_ questionID: String) {
        askedQuestionIDs.insert(questionID)
        print("DEBUG: Marked question \(questionID) as asked (\(askedQuestionIDs.count) total asked)")
    }

    /// Reset the session (clear asked questions)
    func resetSession() {
        askedQuestionIDs.removeAll()
        print("DEBUG: Session reset - cleared \(askedQuestionIDs.count) asked questions")
    }

    // MARK: - Private Methods

    /// Refill the question pool when running low
    private func refillQuestionPool() async {
        print("DEBUG: Refilling question pool (current: \(questionPool.count))")

        if filterConfig.enableOnlineQuestions {
            // Try CloudKit first (uses random sampling for large datasets)
            do {
                let newQuestions = try await cloudKitService.fetchRandomQuestions(
                    count: targetPoolSize,
                    difficulty: filterConfig.difficulty.apiValue,
                    excludeIDs: askedQuestionIDs
                )

                addUniqueQuestions(newQuestions)
                currentSource = .cloudKit
                cacheManager.cacheQuestions(newQuestions, forDifficulty: filterConfig.difficulty.apiValue)
                print("DEBUG: Refilled pool from CloudKit (total: \(questionPool.count))")
                return
            } catch {
                print("DEBUG: CloudKit refill failed: \(error.localizedDescription)")
            }

            // Try Open Trivia DB
            do {
                let newQuestions = try await openTriviaService.fetchQuestions(
                    amount: targetPoolSize,
                    category: 12,
                    difficulty: filterConfig.difficulty.apiValue
                )

                addUniqueQuestions(newQuestions)
                currentSource = .api
                cacheManager.cacheQuestions(newQuestions, forDifficulty: filterConfig.difficulty.apiValue)
                print("DEBUG: Refilled pool from Open Trivia DB (total: \(questionPool.count))")
                return
            } catch {
                print("DEBUG: Open Trivia DB refill failed: \(error.localizedDescription)")
            }
        }

        // Fallback: add bundled questions if pool is depleted
        if questionPool.isEmpty {
            loadBundledQuestions()
        }
    }

    /// Add unique questions to the pool
    private func addUniqueQuestions(_ newQuestions: [TriviaQuestion]) {
        let existingIDs = Set(questionPool.map { $0.id })
        let uniqueNewQuestions = newQuestions.filter { !existingIDs.contains($0.id) }

        questionPool.append(contentsOf: uniqueNewQuestions)

        // Trim to max size if needed
        if questionPool.count > maxPoolSize {
            questionPool = Array(questionPool.prefix(maxPoolSize))
        }
    }

    /// Load questions from bundled JSON with difficulty filtering
    private func loadBundledQuestions() {
        var questions = bundledQuestions

        // Apply difficulty filter if not "any"
        if filterConfig.difficulty != .any {
            questions = questions.filter { question in
                question.difficulty?.lowercased() == filterConfig.difficulty.rawValue
            }
        }

        // If no questions match filter, use all bundled questions
        if questions.isEmpty {
            print("DEBUG: No bundled questions match filter, using all bundled questions")
            questions = bundledQuestions
        }

        // Shuffle for variety
        questionPool = questions.shuffled()
        currentSource = .bundle
        print("DEBUG: Loaded \(questionPool.count) bundled questions")
    }

    /// Get pool status for debugging
    func getPoolStatus() -> String {
        let unanswered = questionPool.filter { !askedQuestionIDs.contains($0.id) }.count
        return "Pool: \(questionPool.count) total, \(unanswered) unanswered, \(askedQuestionIDs.count) asked, source: \(currentSource.rawValue)"
    }

    /// Clear the question cache
    func clearCache() {
        cacheManager.clearCache()
    }
}
