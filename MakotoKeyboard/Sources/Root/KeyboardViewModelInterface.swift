//
//  KeyboardViewModelInterface.swift
//  MakotoKeyboard
//
//  Created by Malaar on 05.04.2023.
//

import Foundation
import Combine

protocol KeyboardViewModelType {
    func transform(input: AnyPublisher<KeyboardViewModel.Input, Never>) -> KeyboardViewModel.Output
}

extension KeyboardViewModel {
    
    enum Input {
        case appear
        case startRecognition
        case stopRecognition
    }
    
    struct Output {
        let recognizedText: AnyPublisher<String, Never>
        let keyboardState: AnyPublisher<KeyboardView.State, Never>
    }
}

