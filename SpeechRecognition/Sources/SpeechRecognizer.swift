//
//  SpeechRecognizer.swift
//  SpeechRecognition
//
//  Created by Malaar on 05.04.2023.
//

import Foundation
import AVFoundation
import Speech

public protocol SpeechRecognizing {
    var isAuthorized: Bool { get }
    func authorize(_ callback: @escaping (RecognitionError?) -> Void)
    func prepare(for locale: Locale)
    func startRecognition(_ callback: @escaping (Result<String, RecognitionError>) -> Void)
    func stopRecognition()
}

public final class SpeechRecognizer: SpeechRecognizing {
    
    // MARK: - State
    
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Authorization
    
    public func authorize(_ callback: @escaping (RecognitionError?) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard case .authorized = status else { return callback(.recognitionDisabled) }
            callback(nil)
        }
    }
    
    public var isAuthorized: Bool {
        guard case .authorized = SFSpeechRecognizer.authorizationStatus() else { return false }
        return true
    }
    
    // MARK: - Recognition
    
    public func prepare(for locale: Locale) {
        stopRecognition()
        
        recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.queue = OperationQueue()
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
    }
    
    public func startRecognition(_ callback: @escaping (Result<String, RecognitionError>) -> Void) {
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true
        
        guard isAuthorized else {
            return callback(.failure(.recognitionDisabled))
        }
        
        guard let recognizer = recognizer,
              let request = request,
              recognizer.isAvailable
        else {
            return callback(.failure(.recognizerIsUnavailable))
        }
        
        do {
            try audioEngine.start()
        } catch {
            print(error)
            callback(.failure(.recognitionFailure))
            return
        }
        
//        try? audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
//        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        task = recognizer.recognitionTask(with: request, resultHandler: { result, error in
            guard let result = result else {
                // TODO: Test on real device to determine while receive this error when recognition was finished
                if let error = (error as? NSError), error.code == 216 {
                    return
                }
                return callback(.failure(.recognitionFailure))
            }
            callback(.success(result.bestTranscription.formattedString))
        })
    }
    
    public func stopRecognition() {
        task?.cancel()
        task = nil
        
        request?.endAudio()
        request = nil
        
        audioEngine.stop()
        
        try? audioSession.setActive(false)
    }
}
