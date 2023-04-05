//
//  RecognitionError.swift
//  SpeechRecognition
//
//  Created by Malaar on 05.04.2023.
//

import Foundation

public enum RecognitionError: Error {
    
    /// User doesn't grant access to voice recognition
    case recognitionDisabled
    
    /// Recognizer is unavailable because of frequency usage limitation or other reasons
    case recognizerIsUnavailable
    
    /// Audio engine failed
    case audioEngineFailure
    
    /// Voice recognition failed
    case recognitionFailure
}
