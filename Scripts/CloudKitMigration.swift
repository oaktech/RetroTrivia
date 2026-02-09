#!/usr/bin/env swift

//
//  CloudKitMigration.swift
//  RetroTrivia
//
//  Script to upload questions to CloudKit
//  Optimized for large datasets (10K+ questions)
//
//  Usage:
//  1. Create a new macOS Command Line Tool target in Xcode
//  2. Add CloudKit framework to the target
//  3. Copy this file to the new target
//  4. Ensure you're signed in to iCloud on the Mac
//  5. Run the target
//

import Foundation
import CloudKit

// MARK: - Question Model (for JSON decoding)

struct Question: Codable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    let category: String?
    let difficulty: String?
}

// MARK: - CloudKit Migration

class CloudKitMigration {
    let container: CKContainer
    let database: CKDatabase
    let containerIdentifier = "iCloud.com.oak-tech.RetroTrivia"

    /// Batch size for uploads (CloudKit recommends <400)
    let batchSize = 200

    init() {
        container = CKContainer(identifier: containerIdentifier)
        database = container.publicCloudDatabase
    }

    func run() async throws {
        print("CloudKit Question Migration Tool")
        print("================================")
        print("Optimized for 10K+ questions\n")

        // Check account status
        let status = try await container.accountStatus()
        guard status == .available else {
            print("Error: iCloud account not available. Status: \(status)")
            print("Please sign in to iCloud in System Settings.")
            return
        }
        print("iCloud account: Available\n")

        // Load questions from backup file
        let questionsPath = "Data/questions_full_backup.json"
        guard FileManager.default.fileExists(atPath: questionsPath) else {
            print("Error: questions_full_backup.json not found at \(questionsPath)")
            print("Run this script from the RetroTrivia project directory.")
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: questionsPath))
        let questions = try JSONDecoder().decode([Question].self, from: data)
        print("Loaded \(questions.count) questions from backup file.")

        // Analyze distribution
        analyzeDifficultyDistribution(questions)

        print("\nEstimated upload time: ~\(max(1, questions.count / 100)) seconds\n")

        // Upload in batches for efficiency
        var successCount = 0
        var errorCount = 0
        let totalBatches = (questions.count + batchSize - 1) / batchSize

        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, questions.count)
            let batch = Array(questions[startIndex..<endIndex])

            print("Uploading batch \(batchIndex + 1)/\(totalBatches) (\(batch.count) questions)...")

            do {
                let (saved, failed) = try await uploadBatch(batch, startingSortOrder: startIndex)
                successCount += saved
                errorCount += failed
            } catch {
                print("  Batch failed: \(error.localizedDescription)")
                errorCount += batch.count
            }

            // Rate limiting between batches
            if batchIndex < totalBatches - 1 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
        }

        print("\n================================")
        print("Migration Complete!")
        print("  Success: \(successCount)")
        print("  Errors:  \(errorCount)")
        print("================================")

        if successCount > 0 {
            print("\nIMPORTANT: Add these indexes in CloudKit Dashboard:")
            print("  - sortOrder: Queryable, Sortable")
            print("  - difficulty: Queryable")
            print("  - isActive: Queryable")
            print("  - category: Queryable")
        }
    }

    /// Upload a batch of questions using CKModifyRecordsOperation
    func uploadBatch(_ questions: [Question], startingSortOrder: Int) async throws -> (saved: Int, failed: Int) {
        var records: [CKRecord] = []

        for (index, question) in questions.enumerated() {
            let record = CKRecord(recordType: "Question")
            record["questionText"] = question.question
            record["options"] = question.options
            record["correctIndex"] = Int64(question.correctIndex)
            record["category"] = question.category ?? "Music"
            record["difficulty"] = question.difficulty ?? "medium"
            record["isActive"] = Int64(1)

            // sortOrder: Random value 0-9999 for efficient random sampling
            // Distributes questions evenly across the range for 10K questions
            let sortOrder = (startingSortOrder + index) % 10000
            record["sortOrder"] = Int64(sortOrder)

            records.append(record)
        }

        // Use batch save
        let modifyResult = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .allKeys
        )

        var saved = 0
        var failed = 0

        for (_, result) in modifyResult.saveResults {
            switch result {
            case .success:
                saved += 1
            case .failure(let error):
                print("  Record failed: \(error.localizedDescription)")
                failed += 1
            }
        }

        print("  Batch result: \(saved) saved, \(failed) failed")
        return (saved, failed)
    }

    /// Verify the upload by counting records
    func verifyUpload() async throws {
        print("\nVerifying upload...")

        let predicate = NSPredicate(format: "isActive == 1")
        let query = CKQuery(recordType: "Question", predicate: predicate)

        var count = 0
        var cursor: CKQueryOperation.Cursor? = nil

        repeat {
            let result: ([(CKRecord.ID, Result<CKRecord, Error>)], CKQueryOperation.Cursor?)

            if let existingCursor = cursor {
                result = try await database.records(
                    continuingMatchFrom: existingCursor,
                    desiredKeys: [],
                    resultsLimit: 400
                )
            } else {
                result = try await database.records(
                    matching: query,
                    desiredKeys: [],
                    resultsLimit: 400
                )
            }

            count += result.0.count
            cursor = result.1
        } while cursor != nil

        print("Total questions in CloudKit: \(count)")
    }

    /// Analyze difficulty distribution
    func analyzeDifficultyDistribution(_ questions: [Question]) {
        var distribution: [String: Int] = [:]

        for question in questions {
            let difficulty = question.difficulty ?? "unknown"
            distribution[difficulty, default: 0] += 1
        }

        print("\nDifficulty Distribution:")
        for (difficulty, count) in distribution.sorted(by: { $0.key < $1.key }) {
            let percentage = Double(count) / Double(questions.count) * 100
            print("  \(difficulty): \(count) (\(String(format: "%.1f", percentage))%)")
        }
    }
}

// MARK: - Main

@main
struct MigrationTool {
    static func main() async {
        let migration = CloudKitMigration()
        do {
            try await migration.run()
            try await migration.verifyUpload()
        } catch {
            print("Migration failed: \(error)")
        }
    }
}
