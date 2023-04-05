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
        
        /// View was appeared
        case appear
        
        /// Need start speech recognition
        case startRecognition
        
        /// Need stop speech recognition
        case stopRecognition
    }
    
    struct Output {
        
        /// Recognize some text
        let recognizedText: AnyPublisher<String, Never>
        
        /// New state for keyboard
        let keyboardState: AnyPublisher<KeyboardView.State, Never>
    }
}

