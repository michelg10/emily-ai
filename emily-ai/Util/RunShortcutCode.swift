import Foundation

func runShortcutActionCrude(
    name: String,
    inputs: [String: Encodable]
) -> String {
    // Clear output file
    let outputFilePath = "/Users/michel/Desktop/AssistantComms/ShortcutOutput.txt"
    try? FileManager.default.removeItem(atPath: outputFilePath)
    
    // Write out inputs
    let inputFilePath = "/Users/michel/Desktop/AssistantComms/ShortcutInput.json"
    let jsonData = try! JSONSerialization.data(withJSONObject: inputs, options: [])
    do {
        try jsonData.write(to: URL(fileURLWithPath: inputFilePath))
        print("File written successfully")
    } catch {
        print("Error writing file: \(error)")
    }
    
    // Run shortcut
    let task = Process()
    task.launchPath = "/usr/bin/shortcuts"
    task.arguments = ["run", name]
    task.launch()
    task.waitUntilExit()
    
    // Wait for output
    while !FileManager.default.fileExists(atPath: outputFilePath) {
        usleep(50000)
    }
    
    // Return outputs
    let outputData = try? Data(contentsOf: URL(fileURLWithPath: outputFilePath))
    return String(data: outputData ?? Data(), encoding: .utf8) ?? ""
}
