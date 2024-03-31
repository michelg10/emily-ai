import Foundation

/// Represents a transcribed chunk of audio.
struct TranscribedChunk {
    /// The transcribed text of the audio chunk.
    let text: String
    /// The timestamp indicating the start time of the audio chunk.
    let startTimestamp: Date
    /// The timestamp indicating the end time of the audio chunk.
    let endTimestamp: Date
}

/// Represents the state of the transcriber.
enum TranscriberState {
    /// The transcriber is stopped and not currently transcribing.
    case stopped
    /// The transcriber is in the process of starting.
    case starting
    /// The transcriber is currently running and actively transcribing.
    case running
    /// The transcriber is in the process of stopping.
    case stopping
}

/// Defines the methods that a transcriber should implement.
protocol Transcriber {
    /// Starts the transcription process.
    /// - Throws: An error if the transcription process fails to start.
    func startTranscription() async throws
    
    /// Stops the transcription process.
    /// - Throws: An error if the transcription process fails to stop.
    func stopTranscription() async throws
    
    /// Retrieves the current state of the transcriber.
    /// - Returns: The current state of the transcriber as `TranscriberState`.
    func getState() -> TranscriberState
    
    /// Retrieves a stream of transcribed chunks.
    /// - Returns: An `AsyncThrowingStream` that emits `TranscribedChunk` objects.
    ///            The stream can throw an error if there's an issue with the transcription process.
    func getTranscribedChunksStream() -> AsyncThrowingStream<TranscribedChunk, Error>
}
