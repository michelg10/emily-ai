import Foundation

struct TranscribedBit {
    let text: String
    let audioSegment: Data
    let startTimestamp: Date
    let endTimestamp: Date
}

enum TranscriberState {
    case stopped
    case starting
    case running
    case stopping
}

protocol Transcriber {
    func startTranscription() async throws
    func stopTranscription() async throws
    func getState() -> TranscriberState
    func getTranscribedBitsStream() -> AsyncThrowingStream<TranscribedBit, Error>
}
