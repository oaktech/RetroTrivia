import Foundation

/// Manages the pool of trivia questions with API and bundled fallback
@Observable
class QuestionManager {
    // MARK: - Properties

    /// Active pool of questions (20-30 questions maintained)
    private(set) var questionPool: [TriviaQuestion] = []

    /// Set of question IDs that have been asked this session
    private var askedQuestionIDs: Set<String> = []

    /// API service for fetching online questions
    private let apiService = TriviaAPIService()

    /// User filter preferences
    var filterConfig: FilterConfiguration {
        didSet {
            filterConfig.save()
        }
    }

    /// Bundled questions cache
    private var bundledQuestions: [TriviaQuestion] = []

    /// Minimum pool size before refilling
    private let minPoolSize = 10

    /// Target pool size
    private let targetPoolSize = 25

    /// Maximum pool size
    private let maxPoolSize = 30

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
            // Try to fetch from API first
            do {
                let questions = try await apiService.fetchQuestions(
                    amount: targetPoolSize,
                    category: 12, // Music
                    difficulty: filterConfig.difficulty.apiValue
                )

                questionPool = questions
                print("DEBUG: Loaded \(questionPool.count) questions from API")
                return
            } catch {
                print("DEBUG: API fetch failed: \(error.localizedDescription), falling back to bundled questions")
            }
        }

        // Fallback to bundled questions
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
            // Try to fetch more from API
            do {
                let newQuestions = try await apiService.fetchQuestions(
                    amount: targetPoolSize,
                    category: 12,
                    difficulty: filterConfig.difficulty.apiValue
                )

                // Add new questions that aren't already in the pool
                let existingIDs = Set(questionPool.map { $0.id })
                let uniqueNewQuestions = newQuestions.filter { !existingIDs.contains($0.id) }

                questionPool.append(contentsOf: uniqueNewQuestions)

                // Trim to max size if needed
                if questionPool.count > maxPoolSize {
                    questionPool = Array(questionPool.prefix(maxPoolSize))
                }

                print("DEBUG: Refilled pool with \(uniqueNewQuestions.count) new questions (total: \(questionPool.count))")
                return
            } catch {
                print("DEBUG: Refill from API failed: \(error.localizedDescription)")
            }
        }

        // Fallback: add bundled questions if pool is depleted
        if questionPool.isEmpty {
            loadBundledQuestions()
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
        print("DEBUG: Loaded \(questionPool.count) bundled questions")
    }

    /// Get pool status for debugging
    func getPoolStatus() -> String {
        let unanswered = questionPool.filter { !askedQuestionIDs.contains($0.id) }.count
        return "Pool: \(questionPool.count) total, \(unanswered) unanswered, \(askedQuestionIDs.count) asked"
    }
}
