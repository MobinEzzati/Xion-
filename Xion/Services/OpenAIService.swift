import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-3.5-turbo"
    private let maxRetries = 3
    private let initialRetryDelay: TimeInterval = 5.0
    
    // Store conversation history for context
    private var conversationHistory: [[String: String]] = []
    
    init() {
        self.apiKey = Config.openAIApiKey
        // Add system message to optimize the conversation
        conversationHistory.append([
            "role": "system",
            "content": "You are a helpful AI assistant. Keep your responses concise and focused. Use minimal tokens while maintaining clarity."
        ])
    }
    
    func generateResponse(for prompt: String) async throws -> String {
        // Add user message to history
        conversationHistory.append([
            "role": "user",
            "content": prompt
        ])
        
        // Limit history to last 5 messages to keep context manageable and reduce token usage
        if conversationHistory.count > 6 { // 1 system message + 5 conversation messages
            // Keep the system message and the most recent messages
            let systemMessage = conversationHistory[0]
            conversationHistory = [systemMessage] + Array(conversationHistory.suffix(5))
        }
        
        var currentRetry = 0
        var lastError: Error?
        
        while currentRetry < maxRetries {
            do {
                return try await performRequest()
            } catch let error as NSError where error.domain == "OpenAIService" && error.code == 429 {
                currentRetry += 1
                lastError = error
                if currentRetry < maxRetries {
                    // Exponential backoff: 5s, 10s, 20s
                    let delay = initialRetryDelay * pow(2.0, Double(currentRetry - 1))
                    print("Rate limit exceeded, retrying in \(delay) seconds... (Attempt \(currentRetry + 1)/\(maxRetries))")
                    print("This might be due to:")
                    print("1. API key has reached its rate limit")
                    print("2. Free tier limitations")
                    print("3. Shared API key usage")
                    print("Consider using a different API key or waiting longer between requests.")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            } catch {
                lastError = error
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        throw NSError(domain: "OpenAIService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded after \(maxRetries) attempts. Please try again later or use a different API key."])
    }
    
    private func performRequest() async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": conversationHistory,
            "temperature": 0.7,
            "max_tokens": 100,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.6
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Print response headers for debugging
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        // Check for specific error status codes
        switch httpResponse.statusCode {
        case 401:
            throw NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key. Please check your OpenAI API key."])
        case 429:
            // Try to parse rate limit information from headers
            if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After") {
                print("Rate limit retry after: \(retryAfter) seconds")
            }
            throw NSError(domain: "OpenAIService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."])
        case 500...599:
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try again later."])
        default:
            break
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(OpenAIResponse.self, from: data)
            if let response = result.choices.first?.message.content {
                // Add AI response to history
                conversationHistory.append([
                    "role": "assistant",
                    "content": response
                ])
                return response
            }
            return "Sorry, I couldn't generate a response."
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
    
    // Add method to clear conversation history
    func clearHistory() {
        // Keep the system message when clearing history
        let systemMessage = conversationHistory[0]
        conversationHistory = [systemMessage]
    }
}

// Response models for OpenAI API
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
} 