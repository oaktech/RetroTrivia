//
//  CloudKitQuestionService.swift
//  RetroTrivia
//
//  Optimized for large question pools (10K+ questions)
//

import CloudKit
import Foundation

/// Errors that can occur when fetching questions from CloudKit
enum CloudKitQuestionError: Error {
    case containerNotConfigured
    case networkError(Error)
    case noResults
    case invalidRecord
    case permissionDenied
    case serverError(Error)

    var localizedDescription: String {
        switch self {
        case .containerNotConfigured:
            return "CloudKit container not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResults:
            return "No questions available"
        case .invalidRecord:
            return "Invalid question record"
        case .permissionDenied:
            return "CloudKit access denied"
        case .serverError(let error):
            return "Server error: \(error.localizedDescription)"
        }
    }
}

/// Service for fetching trivia questions from CloudKit Public Database
/// Optimized for large datasets (10,000+ questions)
@Observable
class CloudKitQuestionService {
    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase

    /// CloudKit container identifier
    private static let containerIdentifier = "iCloud.com.oak-tech.RetroTrivia"

    /// Record type name in CloudKit
    private static let recordType = "Question"

    /// Maximum records per CloudKit query (CloudKit limit is 400)
    private static let maxResultsPerQuery = 400

    /// Default batch size for fetching
    private static let defaultBatchSize = 50

    // MARK: - Initialization

    init() {
        container = CKContainer(identifier: Self.containerIdentifier)
        database = container.publicCloudDatabase
    }

    // MARK: - Public Methods

    /// Fetch random questions using sortOrder field for efficient random sampling
    /// This is the preferred method for large datasets (10K+ questions)
    ///
    /// Requires `sortOrder` field (Int64, 0-9999) on Question records for true randomization.
    /// Falls back to createdAt sorting if sortOrder not available.
    ///
    /// - Parameters:
    ///   - count: Number of questions to fetch (default 25)
    ///   - difficulty: Optional difficulty filter ("easy", "medium", "hard")
    ///   - excludeIDs: Set of question IDs to exclude (kept small for efficiency)
    /// - Returns: Array of TriviaQuestion objects
    func fetchRandomQuestions(
        count: Int = 25,
        difficulty: String? = nil,
        excludeIDs: Set<String> = []
    ) async throws -> [TriviaQuestion] {
        // Generate a random range to sample from (for 10K questions with sortOrder 0-9999)
        let rangeSize = 1000  // Sample from a random 10% slice
        let maxSortOrder = 9999
        let rangeStart = Int.random(in: 0...(maxSortOrder - rangeSize))
        let rangeEnd = rangeStart + rangeSize

        // Build predicate for active questions in random range
        var predicates: [NSPredicate] = [
            NSPredicate(format: "isActive == 1"),
            NSPredicate(format: "sortOrder >= %d AND sortOrder <= %d", rangeStart, rangeEnd)
        ]

        // Add difficulty filter if specified
        if let difficulty = difficulty, difficulty != "any", !difficulty.isEmpty {
            predicates.append(NSPredicate(format: "difficulty == %@", difficulty))
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Self.recordType, predicate: compound)

        // Sort by sortOrder for variety within the range
        query.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: Bool.random())]

        // Fetch more than needed to allow for exclusions and shuffling
        let fetchLimit = min(count * 3, Self.maxResultsPerQuery)

        do {
            let (results, _) = try await database.records(
                matching: query,
                desiredKeys: nil,
                resultsLimit: fetchLimit
            )

            // Convert and filter
            var questions = results.compactMap { recordID, result -> TriviaQuestion? in
                guard case .success(let record) = result else { return nil }
                guard !excludeIDs.contains(record.recordID.recordName) else { return nil }
                return TriviaQuestion(from: record)
            }

            // Shuffle for additional randomness
            questions.shuffle()

            let finalQuestions = Array(questions.prefix(count))
            print("DEBUG: CloudKit - Fetched \(finalQuestions.count) random questions (range: \(rangeStart)-\(rangeEnd))")

            if finalQuestions.isEmpty {
                // Fall back to standard fetch if sortOrder range returned nothing
                return try await fetchQuestions(count: count, difficulty: difficulty, excludeIDs: excludeIDs)
            }

            return finalQuestions

        } catch {
            // If sortOrder query fails (field doesn't exist), fall back to standard fetch
            print("DEBUG: CloudKit - Random fetch failed, falling back to standard: \(error.localizedDescription)")
            return try await fetchQuestions(count: count, difficulty: difficulty, excludeIDs: excludeIDs)
        }
    }

    /// Fetch questions from CloudKit (standard method)
    /// - Parameters:
    ///   - count: Number of questions to fetch (default 25)
    ///   - difficulty: Optional difficulty filter ("easy", "medium", "hard")
    ///   - excludeIDs: Set of question IDs to exclude (already asked)
    /// - Returns: Array of TriviaQuestion objects
    func fetchQuestions(
        count: Int = 25,
        difficulty: String? = nil,
        excludeIDs: Set<String> = []
    ) async throws -> [TriviaQuestion] {
        // Build predicate for active questions
        var predicates: [NSPredicate] = [
            NSPredicate(format: "isActive == 1")
        ]

        // Add difficulty filter if specified
        if let difficulty = difficulty, difficulty != "any", !difficulty.isEmpty {
            predicates.append(NSPredicate(format: "difficulty == %@", difficulty))
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Self.recordType, predicate: compound)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        // For small exclusion sets, fetch extra. For large sets, fetch max and filter client-side.
        let fetchLimit: Int
        if excludeIDs.count < 100 {
            fetchLimit = min(count + excludeIDs.count + 10, Self.maxResultsPerQuery)
        } else {
            // Large exclusion set - fetch max batch and filter
            fetchLimit = Self.maxResultsPerQuery
        }

        do {
            let (results, _) = try await database.records(
                matching: query,
                desiredKeys: nil,
                resultsLimit: fetchLimit
            )

            // Convert records to TriviaQuestion, filtering out excluded IDs
            let questions = results.compactMap { recordID, result -> TriviaQuestion? in
                guard case .success(let record) = result else {
                    print("DEBUG: CloudKit - Failed to fetch record: \(recordID)")
                    return nil
                }

                // Skip if this question was already asked
                if excludeIDs.contains(record.recordID.recordName) {
                    return nil
                }

                return TriviaQuestion(from: record)
            }

            // Shuffle for variety and return requested count
            let shuffled = questions.shuffled()
            let finalQuestions = Array(shuffled.prefix(count))
            print("DEBUG: CloudKit - Fetched \(finalQuestions.count) questions")

            if finalQuestions.isEmpty {
                throw CloudKitQuestionError.noResults
            }

            return finalQuestions

        } catch let error as CKError {
            print("DEBUG: CloudKit error: \(error.localizedDescription)")
            throw mapCloudKitError(error)
        } catch let error as CloudKitQuestionError {
            throw error
        } catch {
            print("DEBUG: CloudKit fetch error: \(error)")
            throw CloudKitQuestionError.networkError(error)
        }
    }

    /// Fetch questions using cursor-based pagination for very large result sets
    /// Use this when you need to process more than 400 questions
    /// - Parameters:
    ///   - difficulty: Optional difficulty filter
    ///   - batchHandler: Called for each batch of questions
    func fetchAllQuestions(
        difficulty: String? = nil,
        batchHandler: @escaping ([TriviaQuestion]) -> Bool  // Return false to stop
    ) async throws {
        var predicates: [NSPredicate] = [
            NSPredicate(format: "isActive == 1")
        ]

        if let difficulty = difficulty, difficulty != "any", !difficulty.isEmpty {
            predicates.append(NSPredicate(format: "difficulty == %@", difficulty))
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Self.recordType, predicate: compound)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        var cursor: CKQueryOperation.Cursor? = nil
        var totalFetched = 0

        repeat {
            let (results, nextCursor): ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)

            if let existingCursor = cursor {
                (results, nextCursor) = try await database.records(
                    continuingMatchFrom: existingCursor,
                    desiredKeys: nil,
                    resultsLimit: Self.maxResultsPerQuery
                )
            } else {
                (results, nextCursor) = try await database.records(
                    matching: query,
                    desiredKeys: nil,
                    resultsLimit: Self.maxResultsPerQuery
                )
            }

            let questions = results.compactMap { _, result -> TriviaQuestion? in
                guard case .success(let record) = result else { return nil }
                return TriviaQuestion(from: record)
            }

            totalFetched += questions.count
            print("DEBUG: CloudKit - Batch fetched \(questions.count) questions (total: \(totalFetched))")

            // Call handler and check if we should continue
            let shouldContinue = batchHandler(questions)
            if !shouldContinue {
                break
            }

            cursor = nextCursor
        } while cursor != nil

        print("DEBUG: CloudKit - Finished fetching all questions: \(totalFetched) total")
    }

    /// Get total question count (approximate, for UI purposes)
    func getQuestionCount(difficulty: String? = nil) async throws -> Int {
        var predicates: [NSPredicate] = [
            NSPredicate(format: "isActive == 1")
        ]

        if let difficulty = difficulty, difficulty != "any", !difficulty.isEmpty {
            predicates.append(NSPredicate(format: "difficulty == %@", difficulty))
        }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Self.recordType, predicate: compound)

        // Fetch just record IDs for counting (more efficient)
        var count = 0
        var cursor: CKQueryOperation.Cursor? = nil

        repeat {
            let result: ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)

            if let existingCursor = cursor {
                result = try await database.records(
                    continuingMatchFrom: existingCursor,
                    desiredKeys: [],  // Don't fetch any fields, just count
                    resultsLimit: Self.maxResultsPerQuery
                )
            } else {
                result = try await database.records(
                    matching: query,
                    desiredKeys: [],
                    resultsLimit: Self.maxResultsPerQuery
                )
            }

            count += result.0.count
            cursor = result.1
        } while cursor != nil

        print("DEBUG: CloudKit - Total question count: \(count)")
        return count
    }

    /// Check if CloudKit is available
    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                print("DEBUG: CloudKit account available")
                return true
            case .noAccount:
                print("DEBUG: No iCloud account")
                return false
            case .restricted:
                print("DEBUG: iCloud account restricted")
                return false
            case .couldNotDetermine:
                print("DEBUG: Could not determine iCloud status")
                return false
            case .temporarilyUnavailable:
                print("DEBUG: iCloud temporarily unavailable")
                return false
            @unknown default:
                print("DEBUG: Unknown iCloud status")
                return false
            }
        } catch {
            print("DEBUG: Error checking CloudKit status: \(error)")
            return false
        }
    }

    // MARK: - Private Methods

    /// Map CKError to CloudKitQuestionError
    private func mapCloudKitError(_ error: CKError) -> CloudKitQuestionError {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return .networkError(error)
        case .notAuthenticated, .permissionFailure:
            return .permissionDenied
        case .serverRejectedRequest, .serviceUnavailable:
            return .serverError(error)
        default:
            return .networkError(error)
        }
    }
}
