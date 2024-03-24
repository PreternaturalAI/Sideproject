

# Lite
[![Build all  platforms](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml/badge.svg)](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

Lite is a framework that allows you to rapidly build your AI/ML prototypes in Swift.

## Requirements

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
|macOS|13.0+|Swift Package Manager|

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/PreternaturalAI/Lite", branch: "main")
]
```

## Usage/Examples

### Streaming

```swift
let prompt = AbstractLLM.ChatPrompt(messages: [.user("Write me a story about...")])
            
let openAI = OpenAI.APIClient(apiKey: "API KEY GOES HERE")
let lite = Lite(services: [openAI])
let result = try await lite.stream(prompt)

for try await message in result.messagePublisher.values {
    do {
        let value = try String(message.content)
        self.chatPrompt = value
    } catch {
        print(error)
    }
}
```

## Support

For support, provide an issue on GitHub or [message me on Twitter.](https://twitter.com/vatsal_manot)
