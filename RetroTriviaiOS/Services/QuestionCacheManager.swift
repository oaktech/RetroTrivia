//
//  QuestionCacheManager.swift
//  RetroTrivia
//

import Foundation

/// Manages local caching of questions for offline use
/// Uses UserDefaults with Data Protection for encryption at rest
class QuestionCacheManager {
    // MARK: - Properties

    private let cacheKey = "cachedQuestions"
    private let cacheTimestampKey = "cachedQuestionsTimestamp"
    private let cacheDifficultyKey = "cachedQuestionsDifficulty"

    /// Maximum age of cache before it's considered stale (24 hours)
    private let maxCacheAge: TimeInterval = 24 * 60 * 60

    /// Maximum number of questions to cache
    private let maxCacheSize = 100

    // MARK: - Public Methods

    /// Cache questions locally
    /// - Parameter questions: Array of questions to cache
    func cacheQuestions(_ questions: [TriviaQuestion]) {
        guard !questions.isEmpty else { return }

        do {
            let data = try JSONEncoder().encode(questions)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            print("DEBUG: QuestionCache - Cached \(questions.count) questions")
        } catch {
            print("DEBUG: QuestionCache - Failed to encode questions: \(error)")
        }
    }

    /// Cache questions with difficulty tag for filtered retrieval
    /// - Parameters:
    ///   - questions: Array of questions to cache
    ///   - difficulty: The difficulty level of these questions
    func cacheQuestions(_ questions: [TriviaQuestion], forDifficulty difficulty: String?) {
        guard !questions.isEmpty else { return }

        // Get existing cache
        var allCached = getAllCachedQuestions()

        // Add new questions (avoiding duplicates)
        let existingIDs = Set(allCached.map { $0.id })
        let newQuestions = questions.filter { !existingIDs.contains($0.id) }
        allCached.append(contentsOf: newQuestions)

        // Trim to max size (keep most recent)
        if allCached.count > maxCacheSize {
            allCached = Array(allCached.suffix(maxCacheSize))
        }

        // Save
        cacheQuestions(allCached)
    }

    /// Get cached questions, optionally filtered by difficulty
    /// - Parameters:
    ///   - count: Maximum number of questions to return
    ///   - difficulty: Optional difficulty filter
    /// - Returns: Array of cached questions
    func getCachedQuestions(count: Int, difficulty: String?) -> [TriviaQuestion] {
        guard isCacheValid() else {
            print("DEBUG: QuestionCache - Cache is stale or empty")
            return []
        }

        var questions = getAllCachedQuestions()

        // Apply difficulty filter
        if let difficulty = difficulty, difficulty != "any", !difficulty.isEmpty {
            questions = questions.filter { $0.difficulty?.lowercased() == difficulty.lowercased() }
        }

        // Shuffle for variety
        questions.shuffle()

        // Return requested count
        let result = Array(questions.prefix(count))
        print("DEBUG: QuestionCache - Returning \(result.count) cached questions")
        return result
    }

    /// Clear the question cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        print("DEBUG: QuestionCache - Cache cleared")
    }

    /// Check if cache has valid, non-stale data
    func isCacheValid() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date else {
            return false
        }

        let cacheAge = Date().timeIntervalSince(timestamp)
        let isValid = cacheAge < maxCacheAge

        if !isValid {
            print("DEBUG: QuestionCache - Cache is stale (\(Int(cacheAge / 3600)) hours old)")
        }

        return isValid
    }

    /// Get the number of cached questions
    var cachedQuestionCount: Int {
        return getAllCachedQuestions().count
    }

    /// Get cache timestamp
    var cacheTimestamp: Date? {
        return UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
    }

    // MARK: - Private Methods

    /// Get all cached questions without filtering
    private func getAllCachedQuestions() -> [TriviaQuestion] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([TriviaQuestion].self, from: data)
        } catch {
            print("DEBUG: QuestionCache - Failed to decode cached questions: \(error)")
            return []
        }
    }
}
