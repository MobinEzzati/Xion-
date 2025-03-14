import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let openAIService = OpenAIService()
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)
        
        let userInput = inputMessage
        inputMessage = ""
        
        Task {
            isLoading = true
            error = nil
            
            do {
                let response = try await openAIService.generateResponse(for: userInput)
                let aiMessage = ChatMessage(content: response, isUser: false)
                messages.append(aiMessage)
            } catch let error as NSError {
                let errorMessage = error.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                self.error = "Error: \(errorMessage)"
                let errorResponse = ChatMessage(content: "Sorry, I encountered an error: \(errorMessage)", isUser: false)
                messages.append(errorResponse)
            } catch {
                self.error = "Failed to get response: \(error.localizedDescription)"
                let errorMessage = ChatMessage(content: "Sorry, I encountered an error. Please try again.", isUser: false)
                messages.append(errorMessage)
            }
            
            isLoading = false
        }
    }
    
    func clearChat() {
        messages.removeAll()
        openAIService.clearHistory()
    }
} 