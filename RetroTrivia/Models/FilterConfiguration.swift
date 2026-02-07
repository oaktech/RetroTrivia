import Foundation

/// Difficulty levels for trivia questions
enum Difficulty: String, Codable, CaseIterable {
    case any = "any"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var displayName: String {
        switch self {
        case .any: return "Any"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Convert to API parameter (nil for "any")
    var apiValue: String? {
        switch self {
        case .any: return nil
        default: return rawValue
        }
    }
}

/// User preferences for trivia questions
struct FilterConfiguration: Codable {
    var difficulty: Difficulty
    var enableOnlineQuestions: Bool

    // UserDefaults keys
    private static let difficultyKey = "trivia.filter.difficulty"
    private static let onlineQuestionsKey = "trivia.filter.onlineQuestions"

    init(difficulty: Difficulty = .any, enableOnlineQuestions: Bool = true) {
        self.difficulty = difficulty
        self.enableOnlineQuestions = enableOnlineQuestions
    }

    /// Load filter configuration from UserDefaults
    static func load() -> FilterConfiguration {
        let defaults = UserDefaults.standard

        let difficultyRawValue = defaults.string(forKey: difficultyKey) ?? Difficulty.any.rawValue
        let difficulty = Difficulty(rawValue: difficultyRawValue) ?? .any

        let enableOnlineQuestions = defaults.object(forKey: onlineQuestionsKey) as? Bool ?? true

        return FilterConfiguration(
            difficulty: difficulty,
            enableOnlineQuestions: enableOnlineQuestions
        )
    }

    /// Save filter configuration to UserDefaults
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(difficulty.rawValue, forKey: Self.difficultyKey)
        defaults.set(enableOnlineQuestions, forKey: Self.onlineQuestionsKey)
    }
}
