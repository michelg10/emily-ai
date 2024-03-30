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
    private var state: TranscriberState = .stopped
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var audioFilePath: URL?
    private let bus = 0
    private var transcribedChunksSubject = PassthroughSubject<TranscribedChunk, Error>()
    private let thresholdLevel: Float = -40.0 // Adjust this threshold based on your needs
    private let recordingFormat: AVAudioFormat
    private var cancellables = Set<AnyCancellable>()
    
    init() throws {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            throw NSError(domain: "WhisperTranscriber", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recording format"])
        }
        recordingFormat = format
        try setupAudioEngine()
    }
    
    private func setupAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: bus)
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, when) in
            self?.processAudioBuffer(buffer: buffer, when: when)
        }
        try audioEngine.start()
    }
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        let level = analyzeAudioBuffer(buffer: buffer)
        
        switch state {
        case .stopped, .stopping:
            if level > thresholdLevel {
                Task {
                    do {
                        try await startTranscription()
                    } catch {
                        transcribedChunksSubject.send(completion: .failure(error))
                    }
                }
            }
        case .running, .starting:
            if level <= thresholdLevel {
                Task {
                    do {
                        try await stopTranscription()
                    } catch {
                        transcribedChunksSubject.send(completion: .failure(error))
                    }
                }
            } else {
                appendAudioData(buffer: buffer)
            }
        }
    }
    
    private func appendAudioData(buffer: AVAudioPCMBuffer) {
        do {
            try audioFile?.write(from: buffer)
        } catch {
            transcribedChunksSubject.send(completion: .failure(error))
        }
    }
    
    private func analyzeAudioBuffer(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return -100.0 }
        let frameLength = Int(buffer.frameLength)
        let rms = (0..<frameLength).compactMap { channelData.pointee[$0] }.map { $0 * $0 }.reduce(0, +) / Float(frameLength)
        return 20 * log10(sqrt(rms))
    }
    
    func startTranscription() async throws {
        guard state == .stopped else { return }
        state = .starting
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
        audioFile = try AVAudioFile(forWriting: filePath, settings: recordingFormat.settings)
        audioFilePath = filePath
        state = .running
    }
    
    func stopTranscription() async throws {
        guard state == .running else { return }
        state = .stopping
        audioFile = nil
        guard let filePath = audioFilePath else { return }
        
        transcribeAudioFile(at: filePath)
        
        state = .stopped
    }
    
    func getState() -> TranscriberState {
        return state
    }
    
    func getTranscribedChunksStream() -> AnyPublisher<TranscribedChunk, Error> {
        return transcribedChunksSubject.eraseToAnyPublisher()
    }
    
    private func transcribeAudioFile(at path: URL) {
        Task {
            do {
                let pipe = try? await WhisperKit()
                   let transcription = try? await pipe!.transcribe(audioPath: URL)?.text
                    print(transcription)
                
                let chunk = TranscribedChunk(
                    text: transcription,
                    audioSegmentData: try Data(contentsOf: path),
                    startTimestamp: Date().addingTimeInterval(-5), // Assuming 5 seconds ago
                    endTimestamp: Date()
                )
                
                // Emit the chunk to subscribers
                transcribedChunksSubject.send(chunk)
                
                // Cleanup the resources
                cleanupTranscriptionResources()
            } catch {
                transcribedChunksSubject.send(completion: .failure(error))
            }
        }
    }
    
    private func cleanupTranscriptionResources() {
        if let path = audioFilePath {
            try? FileManager.default.removeItem(at: path)
            audioFilePath = nil
        }
    }
}
