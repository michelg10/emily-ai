/// Represents a chat thread containing text messages and actions.
struct ChatThread {
    /// Represents a text message in the chat thread.
    struct Text {
        /// The content of the text message.
        let text: String
    }
    
    /// Represents an action in the chat thread.
    struct Action {
        /// The unique identifier of the action.
        let id: String
        /// The user-facing description of the action.
        let userDescription: String
    }
}

/// Represents an item in the chat thread, which can be either a text message or an action.
enum ChatThreadItem {
    /// A text message item in the chat thread.
    case text(ChatThread.Text)
    /// An action item in the chat thread.
    case action(ChatThread.Action)
}

/// Defines the methods that the main object of the assistant should implement.
protocol AssistantMainObject {
    /// Sets the chat thread to the specified array of `ChatThreadItem`.
    /// - Parameter thread: The array of `ChatThreadItem` representing the chat thread.
    func setChatThread(_ thread: [ChatThreadItem])
    
    /// Appends a chunk of text to the chat thread.
    /// - Parameter text: The text chunk to be appended.
    func appendTextChunk(_ text: String)
    
    /// Updates the progress of an action identified by `id` with the specified `tokenCount`.
    /// - Parameters:
    ///   - id: The unique identifier of the action.
    ///   - tokenCount: The current token count indicating the progress of the action.
    func updateActionProgress(id: String, tokenCount: Int)
    
    /// Updates the user-facing text of an action identified by `id` with the specified `text`.
    /// - Parameters:
    ///   - id: The unique identifier of the action.
    ///   - text: The updated user-facing text for the action.
    func updateActionText(id: String, text: String)
}

/// Defines the methods that an assistant should implement.
protocol Assistant {
    /// Initializes a new instance of the assistant with the specified actions.
    /// - Parameter actions: An array of `Action` objects representing the available actions for the assistant.
    init(actions: [Action]) async
    
    /// Called when the user triggers the assistant.
    /// Perform any necessary setup or initialization here.
    func prepareForNewConversation() async
    
    /// Handles the user's message and generates a response.
    /// - Parameter message: The user's message to the assistant.
    /// - Returns: Void.
    /// - Note: This method is asynchronous.
    func handleUserQuery(message: String) async -> Void
    
    /// Registers the main object of the assistant.
    /// This method is typically called during initialization to establish the connection
    /// between the assistant and its main object.
    /// - Parameter object: The main object conforming to the `AssistantMainObject` protocol.
    func registerMainObject(_ object: AssistantMainObject) -> Void
}
