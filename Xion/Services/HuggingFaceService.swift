import Foundation

class HuggingFaceService {
    // TODO: Replace this with your actual Hugging Face API key from https://huggingface.co/settings/tokens
    // The key should start with "hf_"
    private let apiKey = "YOUR_HUGGINGFACE_API_KEY"
    private let model = "microsoft/DialoGPT-small"  // Changed to a chat-optimized model
    private let baseURL = "https://api-inference.huggingface.co/models"
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    // Store conversation history for context
    private var conversationHistory: [String] = []
    
    func generateResponse(for prompt: String) async throws -> String {
        // Add user message to history
        conversationHistory.append(prompt)
        
        // Limit history to last 2 messages to keep context manageable
        if conversationHistory.count > 2 {
            conversationHistory.removeFirst(conversationHistory.count - 2)
        }
        
        var currentRetry = 0
        var lastError: Error?
        
        while currentRetry < maxRetries {
            do {
                return try await performRequest(prompt: prompt)
            } catch let error as NSError where error.domain == "HuggingFaceService" && error.code == 503 {
                currentRetry += 1
                lastError = error
                if currentRetry < maxRetries {
                    print("Model is loading, retrying in \(retryDelay) seconds... (Attempt \(currentRetry + 1)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                }
            } catch {
                lastError = error
            }
        }
        
        if let error = lastError {
            throw error
        }
        
        throw NSError(domain: "HuggingFaceService", code: 503, userInfo: [NSLocalizedDescriptionKey: "Model is still loading after \(maxRetries) attempts. Please try again later."])
    }
    
    private func performRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(model)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a context from conversation history
        let context = conversationHistory.joined(separator: " ")
        
        let body: [String: Any] = [
            "inputs": context,
            "parameters": [
                "max_length": 100,
                "temperature": 0.7,
                "top_p": 0.9,
                "do_sample": true,
                "return_full_text": false,
                "repetition_penalty": 1.2,
                "num_return_sequences": 1,
                "clean_up_tokenization_spaces": true,
                "pad_token_id": 50256,
                "eos_token_id": 50256,
                "no_repeat_ngram_size": 3
            ]
        ]
        
        // Print request details for debugging
        print("Sending request to model: \(model)")
        print("Request body: \(String(data: try JSONSerialization.data(withJSONObject: body), encoding: .utf8) ?? "nil")")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Print response status and headers for debugging
        print("Response status code: \(httpResponse.statusCode)")
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        // Print raw response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw response: \(responseString)")
        }
        
        // Check for specific error status codes
        switch httpResponse.statusCode {
        case 401:
            throw NSError(domain: "HuggingFaceService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key. Please check your Hugging Face API key."])
        case 403:
            throw NSError(domain: "HuggingFaceService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied. You may not have access to this model."])
        case 404:
            throw NSError(domain: "HuggingFaceService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found. Please check the model name."])
        case 429:
            throw NSError(domain: "HuggingFaceService", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."])
        case 503:
            throw NSError(domain: "HuggingFaceService", code: 503, userInfo: [NSLocalizedDescriptionKey: "Model is currently loading. Please try again in a few seconds."])
        case 500...599:
            throw NSError(domain: "HuggingFaceService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try again later."])
        default:
            break
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode([[String: String]].self, from: data)
            if let response = result.first?["generated_text"] {
                // Clean up the response
                let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                // Add AI response to history
                conversationHistory.append(cleanedResponse)
                return cleanedResponse
            }
            return "Sorry, I couldn't generate a response."
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
    
    // Add method to clear conversation history
    func clearHistory() {
        conversationHistory.removeAll()
    }
} 
