//
//  TriviaQuestion.swift
//  RetroTrivia
//

import Foundation

enum QuestionSource: String, Codable {
    case bundle
    case api
    case cloudKit
}

struct TriviaQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    var category: String?
    var difficulty: String?
    var source: QuestionSource

    // Custom initializer for programmatic creation (e.g., from API)
    init(
        id: String = UUID().uuidString,
        question: String,
        options: [String],
        correctIndex: Int,
        category: String? = nil,
        difficulty: String? = nil,
        source: QuestionSource = .bundle
    ) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.category = category
        self.difficulty = difficulty
        self.source = source
    }

    // Custom decoder to provide default source value for bundled questions
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        question = try container.decode(String.self, forKey: .question)
        options = try container.decode([String].self, forKey: .options)
        correctIndex = try container.decode(Int.self, forKey: .correctIndex)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        source = (try? container.decode(QuestionSource.self, forKey: .source)) ?? .bundle
    }

    private enum CodingKeys: String, CodingKey {
        case id, question, options, correctIndex, category, difficulty, source
    }

    static func loadFromBundle() -> [TriviaQuestion] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Failed to find questions.json in bundle")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let questions = try JSONDecoder().decode([TriviaQuestion].self, from: data)
            return questions
        } catch {
            print("Failed to load questions: \(error)")
            return []
        }
    }
}
