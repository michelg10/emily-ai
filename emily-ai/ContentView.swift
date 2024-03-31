//
//  ContentView.swift
//  emily-ai
//
//  Created by Michel Guo on 3/29/24.
//

import SwiftUI

struct ContentView: View {
    @State var whisperTranscriber: WhisperTranscriber = .init()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            Task.detached {
                try! await whisperTranscriber.startTranscription()
            }
            Task.detached {
                let stream = whisperTranscriber.getTranscribedChunksStream()
                
                do {
                    for try await value in stream {
                        print(value)
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
