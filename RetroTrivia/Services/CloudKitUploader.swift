//
//  CloudKitUploader.swift
//  RetroTrivia
//
//  Temporary utility for uploading questions to CloudKit
//  Remove this file after migration is complete
//

import CloudKit
import Foundation

@Observable
class CloudKitUploader {
    private let container: CKContainer
    private let database: CKDatabase

    private(set) var isUploading = false
    private(set) var progress: String = ""
    private(set) var uploadedCount = 0
    private(set) var totalCount = 0
    private(set) var errorCount = 0

    init() {
        container = CKContainer(identifier: "iCloud.com.oak-tech.RetroTrivia")
        database = container.publicCloudDatabase
    }

    /// Upload all questions from the full backup JSON file
    func uploadAllQuestions() async {
        isUploading = true
        uploadedCount = 0
        errorCount = 0
        progress = "Loading questions..."

        // Load questions from backup file
        guard let url = Bundle.main.url(forResource: "questions_full_backup", withExtension: "json") else {
            progress = "Error: questions_full_backup.json not found in bundle"
            isUploading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let questions = try JSONDecoder().decode([TriviaQuestion].self, from: data)
            totalCount = questions.count
            progress = "Loaded \(totalCount) questions. Uploading..."

            // Upload in batches
            let batchSize = 200
            let totalBatches = (questions.count + batchSize - 1) / batchSize

            for batchIndex in 0..<totalBatches {
                let startIndex = batchIndex * batchSize
                let endIndex = min(startIndex + batchSize, questions.count)
                let batch = Array(questions[startIndex..<endIndex])

                progress = "Batch \(batchIndex + 1)/\(totalBatches)..."

                do {
                    let (saved, failed) = try await uploadBatch(batch, startingSortOrder: startIndex)
                    uploadedCount += saved
                    errorCount += failed
                    progress = "Uploaded \(uploadedCount)/\(totalCount)"
                } catch {
                    errorCount += batch.count
                    progress = "Batch \(batchIndex + 1) failed: \(error.localizedDescription)"
                    print("DEBUG: Batch \(batchIndex + 1) error: \(error)")
                }

                // Rate limiting
                if batchIndex < totalBatches - 1 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }

            progress = "Done! \(uploadedCount) uploaded, \(errorCount) errors"

        } catch {
            progress = "Error loading questions: \(error.localizedDescription)"
        }

        isUploading = false
    }

    /// Upload a batch of questions
    private func uploadBatch(_ questions: [TriviaQuestion], startingSortOrder: Int) async throws -> (saved: Int, failed: Int) {
        var records: [CKRecord] = []

        for (index, question) in questions.enumerated() {
            let record = CKRecord(recordType: "Question")
            record["questionText"] = question.question
            record["options"] = question.options
            record["correctIndex"] = Int64(question.correctIndex)
            record["category"] = question.category ?? "Music"
            record["difficulty"] = question.difficulty ?? "medium"
            record["isActive"] = Int64(1)
            record["sortOrder"] = Int64((startingSortOrder + index) % 6008 + 1)
            records.append(record)
        }

        let modifyResult = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .allKeys
        )

        var saved = 0
        var failed = 0

        for (recordID, result) in modifyResult.saveResults {
            switch result {
            case .success:
                saved += 1
            case .failure(let error):
                failed += 1
                if failed <= 3 {
                    print("DEBUG: CloudKit upload error for \(recordID): \(error)")
                }
            }
        }

        return (saved, failed)
    }

    /// Delete all questions from CloudKit (use with caution!)
    func deleteAllQuestions() async {
        isUploading = true
        progress = "Fetching records to delete..."

        do {
            // Use isActive field (queryable) to match all records
            let predicate = NSPredicate(format: "isActive >= 0")
            let query = CKQuery(recordType: "Question", predicate: predicate)

            var recordIDs: [CKRecord.ID] = []
            var cursor: CKQueryOperation.Cursor? = nil

            // Fetch all record IDs
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

                recordIDs.append(contentsOf: result.0.map { $0.0 })
                cursor = result.1
                progress = "Found \(recordIDs.count) records..."
            } while cursor != nil

            totalCount = recordIDs.count
            progress = "Deleting \(totalCount) records..."

            // Delete in batches
            let batchSize = 200
            for i in stride(from: 0, to: recordIDs.count, by: batchSize) {
                let batch = Array(recordIDs[i..<min(i + batchSize, recordIDs.count)])
                _ = try await database.modifyRecords(saving: [], deleting: batch)
                uploadedCount = min(i + batchSize, recordIDs.count)
                progress = "Deleted \(uploadedCount)/\(totalCount)"
            }

            progress = "Deleted all \(totalCount) records"

        } catch {
            progress = "Delete error: \(error.localizedDescription)"
        }

        isUploading = false
    }
}
