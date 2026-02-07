import Foundation

/// Errors that can occur when fetching questions from Open Trivia DB
enum TriviaAPIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noResults
    case invalidParameter
    case tokenNotFound
    case tokenExhausted
    case rateLimitExceeded
    case decodingError(Error)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid API response"
        case .noResults:
            return "No questions available with current filters"
        case .invalidParameter:
            return "Invalid API parameter"
        case .tokenNotFound:
            return "Session token not found"
        case .tokenExhausted:
            return "All questions in session have been used"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

/// Service for fetching trivia questions from Open Trivia Database API
@Observable
class TriviaAPIService {
    private let baseURL = "https://opentdb.com/api.php"
    private let tokenURL = "https://opentdb.com/api_token.php"
    private var sessionToken: String?
    private var lastRequestTime: Date?
    private let rateLimitCooldown: TimeInterval = 5.0 // 5 seconds between requests

    /// Fetch questions from Open Trivia DB
    /// - Parameters:
    ///   - amount: Number of questions to fetch (10-50)
    ///   - category: Category ID (12 for Music)
    ///   - difficulty: Optional difficulty filter (easy/medium/hard)
    /// - Returns: Array of TriviaQuestion objects
    func fetchQuestions(amount: Int = 20, category: Int = 12, difficulty: String? = nil) async throws -> [TriviaQuestion] {
        // Rate limiting: enforce cooldown between requests
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < rateLimitCooldown {
                let waitTime = rateLimitCooldown - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        // Ensure we have a session token
        if sessionToken == nil {
            try await requestSessionToken()
        }

        // Build URL with parameters
        var components = URLComponents(string: baseURL)
        guard components != nil else {
            throw TriviaAPIError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "amount", value: "\(amount)"),
            URLQueryItem(name: "category", value: "\(category)"),
            URLQueryItem(name: "type", value: "multiple") // Only multiple choice
        ]

        if let difficulty = difficulty {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }

        if let token = sessionToken {
            queryItems.append(URLQueryItem(name: "token", value: token))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw TriviaAPIError.invalidURL
        }

        print("DEBUG: Fetching questions from API: \(url)")

        // Make the request
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(from: url)
            lastRequestTime = Date()
        } catch {
            throw TriviaAPIError.networkError(error)
        }

        // Verify HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TriviaAPIError.invalidResponse
        }

        // Parse and convert to TriviaQuestion objects
        let questions = try parseAPIResponse(data)
        print("DEBUG: Successfully fetched \(questions.count) questions from API")

        return questions
    }

    /// Request a new session token from the API
    private func requestSessionToken() async throws {
        var components = URLComponents(string: tokenURL)
        components?.queryItems = [URLQueryItem(name: "command", value: "request")]

        guard let url = components?.url else {
            throw TriviaAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct TokenResponse: Decodable {
            let response_code: Int
            let token: String?
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard tokenResponse.response_code == 0, let token = tokenResponse.token else {
            throw TriviaAPIError.invalidResponse
        }

        sessionToken = token
        print("DEBUG: Acquired new session token")
    }

    /// Reset the session token (useful when token is exhausted)
    func resetSessionToken() async throws {
        guard let token = sessionToken else {
            return
        }

        var components = URLComponents(string: tokenURL)
        components?.queryItems = [
            URLQueryItem(name: "command", value: "reset"),
            URLQueryItem(name: "token", value: token)
        ]

        guard let url = components?.url else {
            throw TriviaAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct TokenResponse: Decodable {
            let response_code: Int
        }

        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        if response.response_code == 0 {
            print("DEBUG: Session token reset successfully")
        }
    }

    /// Parse API response and convert to TriviaQuestion objects
    private func parseAPIResponse(_ data: Data) throws -> [TriviaQuestion] {
        struct APIResponse: Decodable {
            let response_code: Int
            let results: [APIQuestion]?
        }

        struct APIQuestion: Decodable {
            let type: String
            let difficulty: String
            let category: String
            let question: String
            let correct_answer: String
            let incorrect_answers: [String]
        }

        let apiResponse: APIResponse
        do {
            apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        } catch {
            throw TriviaAPIError.decodingError(error)
        }

        // Handle API response codes
        switch apiResponse.response_code {
        case 0: break // Success
        case 1: throw TriviaAPIError.noResults
        case 2: throw TriviaAPIError.invalidParameter
        case 3: throw TriviaAPIError.tokenNotFound
        case 4:
            // Token exhausted - try to reset it
            Task {
                try? await resetSessionToken()
            }
            throw TriviaAPIError.tokenExhausted
        case 5: throw TriviaAPIError.rateLimitExceeded
        default: throw TriviaAPIError.invalidResponse
        }

        guard let results = apiResponse.results, !results.isEmpty else {
            throw TriviaAPIError.noResults
        }

        // Convert API questions to TriviaQuestion objects
        return results.compactMap { apiQuestion in
            // Decode HTML entities in question and answers
            let decodedQuestion = decodeHTMLEntities(apiQuestion.question)
            let decodedCorrectAnswer = decodeHTMLEntities(apiQuestion.correct_answer)
            let decodedIncorrectAnswers = apiQuestion.incorrect_answers.map { decodeHTMLEntities($0) }

            // Shuffle options and track correct index
            let (shuffledOptions, correctIndex) = shuffleOptions(
                correctAnswer: decodedCorrectAnswer,
                incorrectAnswers: decodedIncorrectAnswers
            )

            return TriviaQuestion(
                id: UUID().uuidString,
                question: decodedQuestion,
                options: shuffledOptions,
                correctIndex: correctIndex,
                category: apiQuestion.category,
                difficulty: apiQuestion.difficulty,
                source: .api
            )
        }
    }

    /// Shuffle correct answer into incorrect answers and return the correct index
    private func shuffleOptions(correctAnswer: String, incorrectAnswers: [String]) -> (options: [String], correctIndex: Int) {
        var allOptions = incorrectAnswers
        allOptions.append(correctAnswer)

        // Shuffle the options
        allOptions.shuffle()

        // Find the index of the correct answer after shuffling
        guard let correctIndex = allOptions.firstIndex(of: correctAnswer) else {
            // This should never happen, but fallback to last index
            return (allOptions, allOptions.count - 1)
        }

        return (allOptions, correctIndex)
    }

    /// Decode HTML entities in a string
    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text

        // Common named entities
        let entities: [String: String] = [
            "&quot;": "\"",
            "&#039;": "'",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&apos;": "'",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&nbsp;": " ",
            "&eacute;": "é",
            "&Eacute;": "É",
            "&egrave;": "è",
            "&uuml;": "ü",
            "&ouml;": "ö",
            "&auml;": "ä"
        ]

        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        // Decode numeric entities (&#123; or &#x7B; format)
        let numericPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))

            // Process matches in reverse order to maintain correct ranges
            for match in matches.reversed() {
                if match.numberOfRanges >= 2 {
                    let entityRange = match.range(at: 0)
                    let numberRange = match.range(at: 1)

                    if let swiftNumberRange = Range(numberRange, in: result),
                       let swiftEntityRange = Range(entityRange, in: result) {
                        let numberString = result[swiftNumberRange]
                        if let unicodeValue = Int(numberString),
                           let scalar = UnicodeScalar(unicodeValue) {
                            let character = String(Character(scalar))
                            result.replaceSubrange(swiftEntityRange, with: character)
                        }
                    }
                }
            }
        }

        return result
    }
}
