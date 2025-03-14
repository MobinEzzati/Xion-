# Xion - AI Chat Assistant

Xion is a modern iOS chat application that leverages OpenAI's GPT-3.5 API to provide intelligent, context-aware conversations. Built with SwiftUI, it offers a clean, intuitive interface and robust features for engaging with AI.

## Features

- 🤖 Powered by OpenAI's GPT-3.5 Turbo model
- 💬 Context-aware conversations with history management
- 🎨 Modern SwiftUI interface with smooth animations
- 🔄 Smart retry mechanism for API rate limiting
- 🧹 Conversation history management
- 🎯 Optimized token usage and response handling
- 📱 Native iOS design patterns and components

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- OpenAI API Key

## Installation

1. Clone the repository
```bash
git clone https://github.com/YourUsername/Xion.git
```

2. Open `Xion.xcodeproj` in Xcode

3. Add your OpenAI API key in `Services/OpenAIService.swift`

4. Build and run the project

## Configuration

The app can be configured by modifying the following parameters in `OpenAIService.swift`:

- `model`: The OpenAI model to use (default: "gpt-3.5-turbo")
- `maxRetries`: Number of retry attempts for rate-limited requests
- `maxTokens`: Maximum tokens per response
- Conversation history length and management settings

## Architecture

The app follows a clean architecture pattern with:

- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and state management
- **Services**: API integration and data handling
- **Models**: Data structures and types

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenAI for providing the GPT-3.5 API
- SwiftUI framework for the modern UI implementation
- The iOS development community for inspiration and resources

## Contact

<<<<<<< HEAD
Mobin Ezzati - [@MobinEzzati](https://www.linkedin.com/in/mobin-ezzati-84b753153/)

Project Link: [https://github.com/YourUsername/Xion](https://github.com/MobinEzzati/Xion)
=======
Your Name - [@YourTwitter](https://twitter.com/YourTwitter)

Project Link: [https://github.com/YourUsername/Xion](https://github.com/YourUsername/Xion) 
>>>>>>> 7c5542f (Resolved merge conflicts)
