extension BuiltInActions {
    func getContacts() -> Action {
        return .init(
            identifier: "find_contacts",
            description: "Searches for the contacts in your library that match the given criteria",
            inputs: [
                .init(
                    type: .optional(of: .string),
                    displayTitle: "Name",
                    identifier: "name",
                    description: "Finds contacts with full names matching the given string. Leave empty to fetch all contacts."
                ),
                .init(
                    type: .optional(of: .int),
                    displayTitle: "Limit",
                    identifier: "limit",
                    description: "Limit search to a small number of contacts"
                )
            ],
            output: .init(
                type: .array(of: .string),
                description: "The full names of contacts that match the search"
            ),
            displayTitle: "Find Contacts",
            defaultProgressDescription: "Searching Contacts",
            progressIndicatorType: .indeterminate,
            perform: { parameters in
                let name = parameters.inputs[0]
                let limit = parameters.inputs[1]
                
                var inputs: [String: Encodable] = [:]
                
                if let name = name as? String {
                    inputs["Name"] = name
                }
                
                let result = runShortcutActionCrude(name: "Assistant - Find Contacts", inputs: inputs)
                
                var contacts = result.components(separatedBy: "\n")
                
                if let limitValue = limit as? Int {
                    contacts = Array(contacts.prefix(limitValue))
                }
                
                return contacts
            }
        )
    }
}
