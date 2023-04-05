//
//  KeyboardViewModel.swift
//  MakotoKeyboard
//
//  Created by Malaar on 05.04.2023.
//

import Foundation
import Combine
import SpeechRecognition

final class KeyboardViewModel: KeyboardViewModelType {
    
    // MARK: - Dependencies
    
    private let speechRecognizer: SpeechRecognizing
    
    // MARK: - State
    
    private let recognizedText = PassthroughSubject<String, Never>()
    private let keyboardState = CurrentValueSubject<KeyboardView.State, Never>(.disabled)
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Initialization & configuration
    
    init(speechRecognizer: SpeechRecognizing) {
        self.speechRecognizer = speechRecognizer
    }
    
    func transform(input: AnyPublisher<Input, Never>) -> Output {
        input
            .sink { [weak self] input in
                switch input {
                case .appear:
                    self?.prepare()
                
                case .startRecognition:
                    self?.startRecognition()
                    
                case .stopRecognition:
                    self?.stopRecognition()
                }
            }
            .store(in: &subscriptions)
        
        return Output(
            recognizedText: makeRecognizedTextStream(),
            keyboardState: makeKeyboardStateStream()
        )
    }
}

// MARK: - Streams

private extension KeyboardViewModel {
    func makeRecognizedTextStream() -> AnyPublisher<String, Never> {
        recognizedText
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func makeKeyboardStateStream() -> AnyPublisher<KeyboardView.State, Never> {
        keyboardState
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Voice recognition

private extension KeyboardViewModel {
    func prepare() {
        speechRecognizer.authorize { [weak self] error in
            if let error = error {
                self?.handleError(error)
                return
            }
            
            self?.speechRecognizer.prepare(for: Locale.current)
            self?.keyboardState.send(.enabled)
        }
    }
    
    func startRecognition() {
        keyboardState.send(.inProgress)
        speechRecognizer.startRecognition { [weak self] result in
            switch result {
            case .success(let text):
                self?.recognizedText.send(text)
                
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    func stopRecognition() {
        keyboardState.send(.enabled)
        speechRecognizer.stopRecognition()
    }
}

// MARK: - Error handling

private extension KeyboardViewModel {
    func handleError(_ error: RecognitionError) {
        switch error {
        case .recognitionDisabled:
            keyboardState.send(.disabled)
        
        case .recognitionFailure, .audioEngineFailure:
            let message = "Error speech recognition. Please try again"
            keyboardState.send(.failed(message))
            
        case .recognizerIsUnavailable:
            let message = "Speech recognizer is unavailable. Please try again later"
            keyboardState.send(.failed(message))
        }
    }
}
