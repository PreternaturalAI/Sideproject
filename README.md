
# Lite
[![Build all  platforms](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml/badge.svg)](https://github.com/PreternaturalAI/Lite/actions/workflows/swift.yml)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

Lite is a toolkit designed for developers looking to quickly prototype AI applications. It provides basic, high-performance UI components for platforms like iOS and macOS, allowing for fast experimentation and development without the complexities of full-scale customization. Targeted at simplifying common development challenges, such as file handling and UI creation, Lite is ideal for rapid testing and iteration of AI concepts. 

Lite is not meant for detailed customization or large-scale applications, serving instead as a temporary foundation while more personalized solutions are developed.

#### Supported Platforms
<p align="left">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/macos.svg">
  <source media="(prefers-color-scheme: light)" srcset="Images/macos-active.svg">
  <img alt="macos" src="Images/macos-active.svg" height="24">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/ios.svg">
  <source media="(prefers-color-scheme: light)" srcset="Images/ios-active.svg">
  <img alt="macos" src="Images/ios-active.svg" height="24">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/ipados.svg">
  <source media="(prefers-color-scheme: light)" srcset="Images/ipados-active.svg">
  <img alt="macos" src="Images/ipados-active.svg" height="24">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/tvos.svg">
  <source media="(prefers-color-scheme: light)" srcset="Images/tvos-active.svg">
  <img alt="macos" src="Images/tvos-active.svg" height="24">
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Images/watchos.svg">
  <source media="(prefers-color-scheme: light)" srcset="Images/watchos-active.svg">
  <img alt="macos" src="Images/watchos-active.svg" height="24">
</picture>
</p>

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
// Initializes a chat prompt with user-provided text.
let prompt = AbstractLLM.ChatPrompt(messages: [.user("PROMPT GOES HERE")])

// Creates an API client instance with your unique API key.
let openAI = OpenAI.APIClient(apiKey: "API KEY GOES HERE")

// Wraps the OpenAI client in a 'Lite' service layer for streamlined API access.
let lite = Lite(services: [openAI])

// Initiates a streaming request to the OpenAI service with the user's prompt.
let result = try await lite.stream(prompt)

// Iterates over incoming messages from the OpenAI service as they arrive.
for try await message in result.messagePublisher.values {
    do {
        // Attempts to convert each message's content to a String.
        let value = try String(message.content)
        // Updates a local variable with the new message content.
        self.chatPrompt = value
    } catch {
        // Prints any errors that occur during the message handling.
        print(error)
    }
}
```

### Using GPT4 Vision (Sending Images/Files)
```swift
// Initializes an image-based prompt for the language model.
let imageLiteral = try PromptLiteral(image: image)

// Constructs a series of chat messages combining a predefined text prompt with the image literal.
let messages: [AbstractLLM.ChatMessage] = [
    .user {
        .concatenate(separator: nil) {
            PromptLiteral(Prompts.isThisAMealPrompt)
            imageLiteral
        }
    }
]

// Asynchronously sends the constructed messages to the LLM service and awaits the response.
// It specifies the maximum number of tokens (words) that the response can contain.
let completion = try await Lite.shared.complete(
    prompt: .chat(
        .init(messages: messages)
    ),
    parameters: AbstractLLM.ChatCompletionParameters(
        tokenLimit: .fixed(1000)
    )
)

// Extracts text from the completion response and attempts to convert it to a Boolean.
// This could be used, for example, to determine if the image is recognized as a meal.
let text = try completion._chatCompletion!._stripToText()
return Bool(text) ?? false
```

## Demo

See demos on the Preternatural Cookbook - https://github.com/PreternaturalAI/Cookbook

## Support

For support, provide an issue on GitHub or [message me on Twitter.](https://twitter.com/vatsal_manot)
