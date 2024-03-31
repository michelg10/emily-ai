//
//  WhisperTranscriber.swift
//  emily-ai
//
//  Created by Kevin Zhu on 3/30/24.
//

import AVFoundation
import Combine
import Foundation
import WhisperKit

class WhisperTranscriber: Transcriber {
    /* State variables */
    private var state: TranscriberState = .stopped
    private var recordingActive = false

    private let audioEngine = AVAudioEngine()
    private let recordingFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
    private let bus = 0

    private let thresholdLevel: Float = -55.0 // dBFS. To be adjustable
    
    private var transcriptionStartTime: Date?
    private var transcriptionEndTime: Date?
    private var audioDataBuffer = [Float]()
    
    private var transcribedChunksSubject = PassthroughSubject<TranscribedChunk, Error>()

    init() {
        try! setupAudioEngine()
    }
        
    func getState() -> TranscriberState {
        return state
    }

    func startTranscription() async throws {
        guard state == .stopped else {
            print("Trying to start an already started transcription")
            return
        }
        state = .starting
        try audioEngine.start()
        state = .running
    }
    
    func stopTranscription() async throws {
        guard state == .running else {
            print("Trying to stop a stopped transcription")
            return
        }
        
        recordingActive = false
        state = .stopping
        try audioEngine.stop()
        state = .stopped
    }
    
    private func setupAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: bus)
        inputNode.installTap(onBus: bus, bufferSize: 16384, format: inputFormat) { [weak self] (buffer, when) in
            self?.processAudioBuffer(buffer: buffer, when: when)
        }
        audioEngine.prepare()
    }
    
    // MARK: Code above this point is OK
    private func processAudioBuffer(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        let level = analyzeAudioBuffer(buffer: buffer)

        if recordingActive {
            if level <= thresholdLevel {
                recordingActive = false
                let recordingEndTime = Date() // Get the current time when recording stops
                
                // Process the accumulated audio data for transcription
                transcribeAccumulatedAudioData(startTime: transcriptionStartTime, endTime: recordingEndTime)

                audioDataBuffer.removeAll() // Start with an empty buffer for new recording
                appendBufferToAudioData(buffer: buffer)
                // Clear the accumulated audio data buffer
                transcriptionStartTime = nil // Reset the start timestamp
            } else {
                // While recording is active, continue appending buffer data to the audioDataBuffer
                appendBufferToAudioData(buffer: buffer)
            }
        } else {
            if level > thresholdLevel {
                recordingActive = true
                transcriptionStartTime = Date() // Store the current time when recording starts
                audioDataBuffer.removeAll() // Start with an empty buffer for new recording
            }
            // If the audio level is below the threshold and recording is not active, do nothing.
        }
    }
    
    private func appendBufferToAudioData(buffer: AVAudioPCMBuffer) {
        guard let floatChannelData = buffer.floatChannelData else { return }
    
        let frames = Int(buffer.frameLength)
        let samples = floatChannelData[0]  // Take the first channel (Mono)
        print("Adding \(frames) samples...")
        for i in 0..<frames {
            audioDataBuffer.append(samples[i])
        }
    }

    private func transcribeAccumulatedAudioData(startTime: Date?, endTime: Date) {
        let audioFormat = recordingFormat // Your audio recording format

        // Ensure the format is valid and create the PCM buffer.
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioDataBuffer.count)) else {
            print("Failed to create PCM buffer")
            return
        }

        // Assign the frame length of the buffer.
        pcmBuffer.frameLength = AVAudioFrameCount(audioDataBuffer.count)
        
        // Copy the audioDataBuffer into the pcmBuffer's floatChannelData.
        if let channelData = pcmBuffer.floatChannelData {
            for channelIndex in 0..<Int(audioFormat.channelCount) {
                for sampleIndex in 0..<Int(pcmBuffer.frameLength) {
                    channelData[channelIndex][sampleIndex] = audioDataBuffer[sampleIndex]
                }
            }
        }

        // Create a new audio file at a temporary path to write the PCM buffer.
        let tempDir = FileManager.default.temporaryDirectory
        let outputFileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        
        Task {
            do {
                let audioFile = try AVAudioFile(forWriting: outputFileURL, settings: audioFormat.settings, commonFormat: audioFormat.commonFormat, interleaved: audioFormat.isInterleaved)
                
                // Write the buffer to the audio file.
                try audioFile.write(from: pcmBuffer)
                
                // Debugging: print the file's path
                print("Audio file saved: \(outputFileURL.path)")
                
                // After saving the file, you could also call the transcription service if needed
                // For now, let's just emit the data to the subject for any subscribers to handle
                
                let whisper = try await WhisperKit()
                let transcription = try? await whisper.transcribe(audioPath: outputFileURL.path)?.text
                
                print(transcription!)
                
                let chunk = TranscribedChunk(
                    text: transcription!,
                    startTimestamp: startTime ?? Date(),
                    endTimestamp: endTime
                )
                
                // Emit the chunk to subscribers
                transcribedChunksSubject.send(chunk)
                
            } catch {
                // Handle errors in file writing or buffer conversion
                print("Error writing audio data to file: \(error)")
                transcribedChunksSubject.send(completion: .failure(error))
            }
        }

        // Clear the audioDataBuffer for the next transcription session.
        audioDataBuffer.removeAll()
    }
    
    /*
    private func transcribeAccumulatedAudioData(startTime: Date?, endTime: Date) {
        guard !audioDataBuffer.isEmpty else {
            return
        }
        
        Task {
            do {
                let whisper = try await WhisperKit()
                let transcription = try await whisper.transcribe( audioArray: audioDataBuffer ) // use Whisper

                let chunk = TranscribedChunk(
                    text: transcription!.text,
                    startTimestamp: startTime ?? Date(),
                    endTimestamp: endTime
                )
                
                // audioDataBuffer.removeAll()
                
                // Emit the chunk to subscribers
                transcribedChunksSubject.send(chunk)
            } catch {
                transcribedChunksSubject.send(completion: .failure(error))
            }
        }
    } */
    
    private func analyzeAudioBuffer(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else {
            return -100.0
        }
        let frameLength = Int(buffer.frameLength)
        let rms = (0..<frameLength).compactMap { channelData.pointee[$0] }.map { $0 * $0 }.reduce(0, +) / Float(frameLength)
        print(rms)
        return 20 * log10(sqrt(rms))
    }
        
    func getTranscribedChunksStream() -> AsyncThrowingStream<TranscribedChunk, any Error> {
        AsyncThrowingStream<TranscribedChunk, Error> { continuation in
            // Subscription to the subject that emits new transcribed chunks
            let subscription = self.transcribedChunksSubject.sink(
                receiveCompletion: { completion in
                    // Handle the completion (either finished or failure with an error)
                    if case let .failure(error) = completion {
                        continuation.finish(throwing: error)
                    } else {
                        continuation.finish()
                    }
                },
                receiveValue: { chunk in
                    // Emit new chunks to the stream as they come in
                    continuation.yield(chunk)
                }
            )
            
            // Store the subscription so it doesn't get deallocated
            continuation.onTermination = { @Sendable _ in
                subscription.cancel()
            }
        }
    }
}

