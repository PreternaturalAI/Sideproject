

# Lite
[![Build all  platforms](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml/badge.svg)](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

Explanation about Lite goes here.

## Features

|  | Main Features |
| :-------- | :-----------|
| 📖 | Open Source |
|🙅‍♂️|No Account Required|


## Requirements

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
|macOS|13.0+|Swift Package Manager|

## Installation


The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Once you have your Swift package set up, adding Lite as a dependency is as easy as adding it to the dependencies value of your Package.swift or the Package list in Xcode.

```swift
dependencies: [
    .package(url: "https://github.com/PreternaturalAI/Lite", branch: "main")
]
```

## Usage/Examples

To create a request to an LLM, just create a prompt, enter in the services you'd like to use (OpenAI, Claude, Gemeni, etc...) and based on the prompt Lite will find which one will work best for your request.

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
## Demo

A demo application is provided to showcase the core mechanism.

## Support

For support, provide an issue on GitHub or [message me on Twitter.](https://twitter.com/vatsal_manot)
