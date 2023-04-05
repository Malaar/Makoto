//
//  RecognitionError.swift
//  SpeechRecognition
//
//  Created by Malaar on 05.04.2023.
//

import Foundation

public enum RecognitionError: Error {
    case recognitionDisabled
    case recognizerIsUnavailable
    case audioEngineFailure
    case recognitionFailure
}
