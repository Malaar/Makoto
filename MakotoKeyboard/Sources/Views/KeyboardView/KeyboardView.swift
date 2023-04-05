//
//  KeyboardView.swift
//  MakotoKeyboard
//
//  Created by Malaar on 05.04.2023.
//

import UIKit
import Combine
import Lottie
import Reusable

final class KeyboardView: UIView, NibLoadable {
    
    /// Represent state of `KeyboardView`. View is self-configured based on state
    enum State: Equatable {
        
        /// Recognition is enabled
        case enabled
        
        /// Recognition is disabled
        case disabled
        
        /// Recognition is in progress
        case inProgress
        
        /// Recognition is failed. Error message displays on the view
        case failed(_ message: String)
    }
    
    /// Action produced by `KeyboardView`
    enum Action {
        
        /// Microphone button was pressed
        case micPressed
        
        /// Microphone button was released
        case micReleased
    }
    
    // MARK: - Input & Output
    
    /// Setup state to configure this view
    var state: State = .disabled {
        didSet { updateState(state) }
    }
    
    /// Action emitting by this view
    var action: AnyPublisher<Action, Never> {
        actionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var animationView: LottieAnimationView!
    @IBOutlet private weak var errorLabel: UILabel!
    
    // MARK: - Subjects
    
    private let actionSubject = PassthroughSubject<Action, Never>()
    
    // MARK: - View lifecycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
}

// MARK: - Configuration

private extension KeyboardView {
    func setup() {
        errorLabel.isHidden = true
        animationView.isHidden = true
    }
    
    func updateState(_ state: State) {
        switch state {
        case .disabled:
            disableRecognition()
            
        case .enabled:
            enableRecognition()
            
        case .inProgress:
            inProgressRecognition()
            
        case .failed(let message):
            failRecognition(with: message)
        }
    }
    
    func disableRecognition() {
        stopAnimation()
        showError("Speech recognition is disabled. Please grant access for speech recognition in Settings app")
        titleLabel.isHidden = true
        micButton.isEnabled = false
    }
    
    func enableRecognition() {
        stopAnimation()
        hideError()
        titleLabel.isHidden = false
        micButton.isEnabled = true
    }
    
    func inProgressRecognition() {
        startAnimation()
        hideError()
        titleLabel.isHidden = false
        micButton.isEnabled = true
    }
    
    func failRecognition(with message: String) {
        showError(message)
        titleLabel.isHidden = false
        micButton.isEnabled = true
    }
}

// MARK: - Errors displaying

private extension KeyboardView {
    func showError(_ message: String) {
        stopAnimation()
        errorLabel.isHidden = false
        errorLabel.text = message
    }
    
    func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
    }
}

// MARK: - Animation

private extension KeyboardView {
    func loadAnimation() -> LottieAnimation? {
        guard
            let url = Bundle(for: Self.self).url(forResource: "voice", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        
        let animation = try? JSONDecoder().decode(LottieAnimation.self, from: data)
        return animation
    }
    
    func startAnimation() {
        animationView.isHidden = false
        if animationView.animation == nil {
            animationView.animation = loadAnimation()
            animationView.loopMode = .loop
        }
        animationView.play()
    }
    
    func stopAnimation() {
        animationView.stop()
        animationView.isHidden = true
    }
}

// MARK: - Actions

private extension KeyboardView {
    @IBAction func micPressed(_ sender: UIButton) {
        if state == .disabled || state == .inProgress { return }
        
        actionSubject.send(.micPressed)
    }
    
    @IBAction func micReleased(_ sender: UIButton) {
        if state != .inProgress { return }
        
        actionSubject.send(.micReleased)
    }
}

