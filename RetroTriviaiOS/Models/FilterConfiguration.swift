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

    // UserDefaults keys
    private static let difficultyKey = "trivia.filter.difficulty"

    init(difficulty: Difficulty = .any) {
        self.difficulty = difficulty
    }

    /// Load filter configuration from UserDefaults
    static func load() -> FilterConfiguration {
        let defaults = UserDefaults.standard

        let difficultyRawValue = defaults.string(forKey: difficultyKey) ?? Difficulty.any.rawValue
        let difficulty = Difficulty(rawValue: difficultyRawValue) ?? .any

        return FilterConfiguration(difficulty: difficulty)
    }

    /// Save filter configuration to UserDefaults
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(difficulty.rawValue, forKey: Self.difficultyKey)
    }
}
