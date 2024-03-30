/// Represents the state of the assistant in the context of the voice command processor.
enum VoiceCommandProcessorAssistantState {
    /// The model is currently unavailable.
    case unavailable
    /// The model is currently inactive and awaiting user input.
    case inactive
    /// The model is currently responding to a user query.
    case responding
}

/// Represents a message in the context of the main singleton and the voice command processor.
struct VoiceCommandProcessorMainSingletonContextMessage {
    /// Represents the sender of the message.
    enum Sender {
        /// The message is sent by the user.
        case user
        /// The message is sent by the assistant.
        case assistant
    }
    
    /// The sender of the message.
    let sender: Sender
    /// The content of the message.
    let content: String
}

/// Defines the methods that the main singleton of the app should implement for the voice command processor to communicate with it.
protocol VoiceCommandProcessorMainObject {
    /// Retrieves the current state of the assistant in the context of the voice command processor.
    /// - Returns: The current state of the assistant as `VoiceCommandProcessorAssistantState`.
    func getAssistantStateForVoiceCommandProcessor() async -> VoiceCommandProcessorAssistantState
    
    /// Retrieves the conversation context for the voice command processor.
    /// - Returns: An array of `VoiceCommandProcessorMainSingletonContextMessage` representing the conversation context.
    /// - Note: This method may be missing out on some context, such as specific actions performed by the assistant, but it should be sufficient for most purposes.
    func getConversationContextForVoiceCommandProcessor() -> [VoiceCommandProcessorMainSingletonContextMessage]
}

/// Represents a command that can be processed by the voice command processor.
enum Command {
    /// Indicates the start of a new command.
    /// - Note: If the assistant is currently saying something, this command would be considered an "Interrupt".
    case StartCommand
    
    /// Represents a chunk of text in a user command.
    /// - Parameter String: The chunk of text.
    case TextChunk(String)
    
    /// Indicates the end of a user command.
    case EndCommand
}

/// Defines the methods that a voice command processor should implement.
protocol VoiceCommandProcessor {
    /// Resets the state of the voice command processor.
    func resetState()
    
    /// Registers the main object that the voice command processor should communicate with.
    /// - Parameter object: The main object conforming to the `VoiceCommandProcessorMainObject` protocol.
    func registerMainObject(_ object: VoiceCommandProcessorMainObject)
    
    /// Processes new voice chunks and generates corresponding commands.
    /// - Parameter chunks: An array of `TranscribedChunk` objects representing the new voice chunks.
    /// - Returns: An array of `Command` objects generated from the processed voice chunks.
    func processNewVoiceChunk(_ chunks: [TranscribedChunk]) async -> [Command]
}
