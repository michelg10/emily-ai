struct Action {
    struct InputParameter {
        let type: ActionDataType
        let displayTitle: String
        /// Should only contain ASCII characters + underscores. Identifiers should be unique between each parameter
        let identifier: String
        let description: String
    }
    
    struct Output {
        let type: ActionDataType
        let description: String
    }
    
    // MARK: For Assistant
    /// Should only contain ASCII characters + underscores
    let identifier: String
    let description: String
    let inputs: [InputParameter]
    let output: Output?
    
    // MARK: For User
    let displayTitle: String
    /// Used to show the user what action the language model is currently performing
    let defaultProgressDescription: String
    let progressIndicatorType: ActionProgressIndicator
    
    // MARK: Methods
    /// Description for the LLM
    func describe() -> String {
        return ""
    }
    
    struct ActionPerformParameters {
        let inputs: [Any?]
        let presentUserConfirmation: (ConfirmationDisplay) async -> Bool
        let setDescription: (String) -> Void
        let updateContinuousProgress: (Double) -> Void
    }
    
    /// Performs the action with the given inputs and handles user confirmation and progress updates.
    ///
    /// - Parameters:
    ///   - inputs: An array of input values required to perform the action.
    ///   - presentUserConfirmation: An asynchronous closure that presents a confirmation display to the user and returns a Boolean value indicating whether the user confirmed the action.
    ///   - setDescription: A closure that updates the description of the ongoing action for display to the user.
    ///   - updateContinuousProgress: A closure that updates the progress bar with a value between 0 and 1, indicating the progress of the action. This closure is only used when `progressIndicatorType` is set to `.continuous`.
    ///
    /// - Returns: The result of the action, if any, as an optional `Any` value.
    ///
    /// - Note: This method is asynchronous and should be called with `await` to handle the asynchronous nature of user confirmation and action execution.
    ///
    /// When the action is performed, it will:
    /// 1. Present a user confirmation dialog using the `presentUserConfirmation` closure, if necessary.
    /// 2. Update the progress description using the `setDescription` closure to inform the user about the ongoing action.
    /// 3. Update the progress bar using the `updateContinuousProgress` closure, if the `progressIndicatorType` is set to `.continuous`.
    /// 4. Perform the action asynchronously and return the result, if any.
    var perform: (ActionPerformParameters) async -> Any?
}
