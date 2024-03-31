//
//  OpenAIVoiceCommandProcessor.swift
//  emily-ai
//
//  Created by Anthony Zhai on 3/30/24.
//

import Foundation

class OpenAIVoiceCommandProcessor: VoiceCommandProcessor {
    private var mainObject: VoiceCommandProcessorMainObject?
    var processingCommand: Bool = false
    var executingCommand: Bool = false
    var commandText: String = ""
    
    func resetState() {
        processingCommand = false
        executingCommand = false
        commandText = ""
    }
    
    func registerMainObject(_ object: any VoiceCommandProcessorMainObject) {
        mainObject = object
    }
    
    func processNewVoiceChunk(_ chunks: [TranscribedChunk]) async -> [Command] {
        assert(chunks.count == 1)
        assert(mainObject != nil)
        // var processStartChunkIdx = 0
        var processStartWordIdx = 0
        let chunk = chunks[0]
        
        if await mainObject!.getAssistantStateForVoiceCommandProcessor() == VoiceCommandProcessorAssistantState.inactive {
            executingCommand = false
        }
        
        // If not processing yet, look for keywords "Hey Emily!" to start processing command or "Emily stop!" to stop command
        if !processingCommand {
            let chunkWords = chunk.text.components(separatedBy: " ")
            for (j, word) in chunkWords.enumerated() {
                if word == "Hey" {
                    if j < chunkWords.count - 1 && chunkWords[j+1].contains("Emily") {
                        processStartWordIdx = j
                        processingCommand = true
                        break
                    }
                } else if !executingCommand && word == "Emily" {
                    if j < chunkWords.count - 1 && chunkWords[j+1].contains("stop") {
                        processingCommand = false
                        // SEND STOP COMMAND
                        let commands: [Command] = [.StartCommand, .TextChunk("Emily, stop."), .EndCommand]
                        commandText = ""
                        return commands
                    }
                }
            }
        }
        
        // If processing or if keyword was just found, start adding the text and checking if it is a command
        if processingCommand && !executingCommand {
            let chunkWords = chunk.text.components(separatedBy: " ")
            commandText += chunkWords[processStartWordIdx...].joined(separator: " ")
            if !chunkWords[chunkWords.count - 1].contains("...") {
                executingCommand = true
                processingCommand = false
                // SEND COMMAND
                let commands: [Command] = [.StartCommand, .TextChunk(commandText), .EndCommand]
                commandText = ""
                return commands
            }
        }
        
        return []
    }
}
