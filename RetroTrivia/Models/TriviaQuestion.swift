//
//  TriviaQuestion.swift
//  RetroTrivia
//

import Foundation

struct TriviaQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    var category: String?
    var difficulty: String?

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
