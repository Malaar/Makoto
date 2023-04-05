//
//  KeyboardViewController.swift
//  MakotoKeyboard
//
//  Created by Malaar on 05.04.2023.
//

import UIKit
import Combine
import Lottie
import Reusable
import SpeechRecognition

final class KeyboardViewController: UIInputViewController {

    private var nextKeyboardButton: UIButton!
    private lazy var keyboardView = KeyboardView.loadFromNib()
    
    private let viewModel = KeyboardViewModel(speechRecognizer: SpeechRecognizer())
    
    private let isAppeared = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Next button
        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.nextKeyboardButton)
        self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        // Keyboard
        view.addSubview(keyboardView)
        keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0).isActive = true
        keyboardView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hasDictationKey = true
        isAppeared.send(())
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
}

// MARK: - Bindings

private extension KeyboardViewController {
    func makeInputStream() -> AnyPublisher<KeyboardViewModel.Input,Never> {
        let keyboardAction = keyboardView.action
            .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
            .map { action -> KeyboardViewModel.Input in
                switch action {
                case .micPressed: return .startRecognition
                case .micReleased: return .stopRecognition
                }
            }
            .eraseToAnyPublisher()
        
        let appearAction = isAppeared
            .map { _ -> KeyboardViewModel.Input in .appear }
            .eraseToAnyPublisher()
        
        return keyboardAction
            .merge(with: appearAction)
            .eraseToAnyPublisher()
    }
    
    func bind() {
        let output = viewModel.transform(input: makeInputStream())
        
        output.recognizedText
            .sink { [weak self] text in
                self?.setText(text)
            }
            .store(in: &subscriptions)
        
        output.keyboardState
            .assign(to: \.state, on: keyboardView)
            .store(in: &subscriptions)
    }
}

// MARK: - Text management

private extension KeyboardViewController {
    func setText(_ text: String) {
        while textDocumentProxy.hasText {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(text)
    }
}
