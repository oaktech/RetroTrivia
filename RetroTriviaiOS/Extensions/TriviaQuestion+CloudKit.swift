//
//  TriviaQuestion+CloudKit.swift
//  RetroTrivia
//

import CloudKit
import Foundation

extension TriviaQuestion {
    /// Initialize a TriviaQuestion from a CloudKit record
    /// - Parameter record: CKRecord with Question data
    init?(from record: CKRecord) {
        // Validate required fields
        guard let questionText = record["questionText"] as? String,
              let options = record["options"] as? [String],
              let correctIndex = record["correctIndex"] as? Int64,
              options.count == 4 else {
            print("DEBUG: CloudKit - Invalid record: missing required fields")
            return nil
        }

        // Validate correctIndex is within bounds
        guard correctIndex >= 0 && correctIndex < 4 else {
            print("DEBUG: CloudKit - Invalid correctIndex: \(correctIndex)")
            return nil
        }

        // Extract optional fields
        let category = record["category"] as? String
        let difficulty = record["difficulty"] as? String

        self.init(
            id: record.recordID.recordName,
            question: questionText,
            options: options,
            correctIndex: Int(correctIndex),
            category: category,
            difficulty: difficulty,
            source: .cloudKit
        )
    }

    /// Convert TriviaQuestion to a CloudKit record
    /// - Parameter sortOrder: Optional sort order for random sampling (1-6008)
    /// - Returns: CKRecord representing this question
    func toCloudKitRecord(sortOrder: Int? = nil) -> CKRecord {
        let record = CKRecord(recordType: "Question")
        record["questionText"] = question
        record["options"] = options
        record["correctIndex"] = Int64(correctIndex)
        record["category"] = category ?? "Song Trivia"
        record["difficulty"] = difficulty ?? "medium"
        record["isActive"] = Int64(1)
        // sortOrder enables efficient random sampling for large datasets (6K+)
        record["sortOrder"] = Int64(sortOrder ?? Int.random(in: 1...6008))
        return record
    }
}
