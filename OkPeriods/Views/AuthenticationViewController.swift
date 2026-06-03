//
//  AuthenticationViewController.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import UIKit

final class AuthenticationViewController: UIViewController {
    private let authenticationManager = AuthenticationManager.shared

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()

    private let heroView = GradientHeroView()
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let authCard = SurfaceCardView()
    private let authStack = UIStackView()
    private let googleButton = ActionButton(title: "Continue with Google", style: .secondary)
    private let helperLabel = UILabel()
    private let dividerView = UIView()
    private let statusBanner = UILabel()
    private let phoneSectionTitleLabel = UILabel()
    private let phoneSectionDescriptionLabel = UILabel()
    private let phoneField = InsetTextField()
    private let sendPhoneCodeButton = ActionButton(title: "Send SMS verification code", style: .primary)
    private let phoneVerificationStack = UIStackView()
    private let phoneCodeField = InsetTextField()
    private let verifyPhoneCodeButton = ActionButton(title: "Verify phone code", style: .primary)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
        configureContent()
        configureActions()
        populatePendingState()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardSize = keyboardFrame.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
        
        scrollView.contentInset = contentInsets
        scrollView.verticalScrollIndicatorInsets = contentInsets
        
        if let activeTextField = findActiveTextField(in: view) {
            var rect = activeTextField.convert(activeTextField.bounds, to: scrollView)
            rect.size.height += 80
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }

    private func findActiveTextField(in view: UIView) -> UITextField? {
        if let textField = view as? UITextField, textField.isFirstResponder {
            return textField
        }
        for subview in view.subviews {
            if let active = findActiveTextField(in: subview) {
                return active
            }
        }
        return nil
    }

    private func configureView() {
        view.backgroundColor = AppTheme.background
        navigationItem.hidesBackButton = true

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissKeyboardTap)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        heroView.translatesAutoresizingMaskIntoConstraints = false
        authCard.translatesAutoresizingMaskIntoConstraints = false
        authStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = 24

        contentStack.addArrangedSubview(heroView)
        contentStack.addArrangedSubview(authCard)

        authCard.addSubview(authStack)
        authStack.axis = .vertical
        authStack.spacing = 16

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),

            heroView.heightAnchor.constraint(equalToConstant: 260),

            authStack.topAnchor.constraint(equalTo: authCard.topAnchor, constant: 24),
            authStack.leadingAnchor.constraint(equalTo: authCard.leadingAnchor, constant: 20),
            authStack.trailingAnchor.constraint(equalTo: authCard.trailingAnchor, constant: -20),
            authStack.bottomAnchor.constraint(equalTo: authCard.bottomAnchor, constant: -24)
        ])
    }

    private func configureContent() {
       
        let imageView = UIImageView(image: UIImage(named: "Icon-iOS-Default-1024x1024"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        
        badgeLabel.text = "UIKit + Firebase Authentication"
        badgeLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        badgeLabel.font = .roundedStyle(.caption1, weight: .semibold)

        titleLabel.text = "OkPeriods"
        titleLabel.textColor = .white
        titleLabel.font = .roundedStyle(.largeTitle, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.text = "iOS Development Internship Assessment"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        subtitleLabel.font = .roundedStyle(.body)
        subtitleLabel.numberOfLines = 0

        let heroTextStack = UIStackView(arrangedSubviews: [imageView, badgeLabel, titleLabel, subtitleLabel])
        heroTextStack.axis = .vertical
        heroTextStack.alignment = .leading
        heroTextStack.spacing = 12
        heroTextStack.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(heroTextStack)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 72),
            imageView.heightAnchor.constraint(equalToConstant: 72),
            
            heroTextStack.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
            heroTextStack.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -24),
            heroTextStack.bottomAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -24)
        ])

        let authTitleLabel = UILabel()
        authTitleLabel.text = "Welcome"
        authTitleLabel.textColor = AppTheme.primaryText
        authTitleLabel.font = .roundedStyle(.title2, weight: .bold)

        helperLabel.text = "Choose the quickest way to continue into your account."
        helperLabel.textColor = AppTheme.secondaryText
        helperLabel.font = .roundedStyle(.subheadline)
        helperLabel.numberOfLines = 0

        dividerView.backgroundColor = AppTheme.border
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        statusBanner.backgroundColor = AppTheme.accent
        statusBanner.textColor = AppTheme.primaryText
        statusBanner.font = .roundedStyle(.footnote, weight: .medium)
        statusBanner.numberOfLines = 0
        statusBanner.layer.cornerRadius = 18
        statusBanner.layer.cornerCurve = .continuous
        statusBanner.clipsToBounds = true
        statusBanner.isHidden = true
        statusBanner.translatesAutoresizingMaskIntoConstraints = false

        phoneSectionTitleLabel.text = "Sign in with phone number"
        phoneSectionTitleLabel.textColor = AppTheme.primaryText
        phoneSectionTitleLabel.font = .roundedStyle(.headline, weight: .semibold)

        phoneSectionDescriptionLabel.text = authenticationManager.phoneAuthHelperText
        phoneSectionDescriptionLabel.textColor = AppTheme.secondaryText
        phoneSectionDescriptionLabel.font = .roundedStyle(.subheadline)
        phoneSectionDescriptionLabel.numberOfLines = 0

        phoneField.placeholder = "+1 6505553434"
        phoneField.keyboardType = .phonePad
        phoneField.textContentType = .telephoneNumber
        phoneField.returnKeyType = .done
        phoneField.delegate = self

        phoneCodeField.placeholder = "6-digit code"
        phoneCodeField.keyboardType = .numberPad
        phoneCodeField.textContentType = .oneTimeCode
        phoneCodeField.returnKeyType = .done
        phoneCodeField.delegate = self

        let phoneStepsLabel = UILabel()
        phoneStepsLabel.text = "After the SMS arrives, enter the 6-digit code to finish Firebase phone authentication."
        phoneStepsLabel.textColor = AppTheme.secondaryText
        phoneStepsLabel.font = .roundedStyle(.footnote)
        phoneStepsLabel.numberOfLines = 0

        phoneVerificationStack.axis = .vertical
        phoneVerificationStack.spacing = 12
        phoneVerificationStack.isHidden = true
        phoneVerificationStack.addArrangedSubview(phoneStepsLabel)
        phoneVerificationStack.addArrangedSubview(phoneCodeField)
        phoneVerificationStack.addArrangedSubview(verifyPhoneCodeButton)

        authStack.addArrangedSubview(authTitleLabel)
        authStack.addArrangedSubview(helperLabel)
        authStack.addArrangedSubview(googleButton)
        authStack.addArrangedSubview(dividerView)
        authStack.addArrangedSubview(statusBanner)
        authStack.addArrangedSubview(phoneSectionTitleLabel)
        authStack.addArrangedSubview(phoneSectionDescriptionLabel)
        authStack.addArrangedSubview(phoneField)
        authStack.addArrangedSubview(sendPhoneCodeButton)
        authStack.addArrangedSubview(phoneVerificationStack)

        let footerLabel = UILabel()
        footerLabel.text = "Your Firebase session is persisted automatically after a successful sign-in."
        footerLabel.textColor = AppTheme.secondaryText
        footerLabel.font = .roundedStyle(.footnote)
        footerLabel.numberOfLines = 0
        authStack.addArrangedSubview(footerLabel)
    }

    private func configureActions() {
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        sendPhoneCodeButton.addTarget(self, action: #selector(handleSendPhoneCode), for: .touchUpInside)
        verifyPhoneCodeButton.addTarget(self, action: #selector(handleCompletePhoneSignIn), for: .touchUpInside)
    }

    private func populatePendingState() {
        if let pendingPhoneNumber = authenticationManager.storedPendingPhoneNumber() {
            phoneField.text = pendingPhoneNumber
        }

        if authenticationManager.hasPendingPhoneVerification() {
            revealPhoneVerificationStep(animated: false)
        }
    }

    private func revealPhoneVerificationStep(animated: Bool) {
        phoneVerificationStack.isHidden = false

        guard animated else { return }

        phoneVerificationStack.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.phoneVerificationStack.alpha = 1
        }
    }

    private func setStatus(_ message: String, color: UIColor, textColor: UIColor = AppTheme.primaryText) {
        statusBanner.text = "  \(message)  "
        statusBanner.backgroundColor = color
        statusBanner.textColor = textColor
        statusBanner.isHidden = false
    }

    @objc private func handleGoogleSignIn() {
        googleButton.setLoading(true)
        setStatus("Launching Google Sign-In…", color: AppTheme.secondarySurface)

        Task {
            defer { googleButton.setLoading(false) }

            do {
                try await authenticationManager.signInWithGoogle(presentingViewController: self)
            } catch AuthManagerError.cancelled {
                setStatus("Google Sign-In was cancelled.", color: AppTheme.accent)
            } catch {
                setStatus(error.localizedDescription, color: AppTheme.danger.withAlphaComponent(0.14), textColor: AppTheme.danger)
            }
        }
    }

    @objc private func handleSendPhoneCode() {
        dismissKeyboard()

        let phoneNumber = phoneField.text ?? ""
        sendPhoneCodeButton.setLoading(true)
        let loadingMessage = authenticationManager.isUsingPhoneAuthTestingMode
            ? "Preparing Firebase phone-auth test verification…"
            : "Requesting an SMS verification code…"
        setStatus(loadingMessage, color: AppTheme.secondarySurface)

        Task {
            defer { sendPhoneCodeButton.setLoading(false) }

            do {
                try await authenticationManager.sendPhoneVerificationCode(to: phoneNumber, presentingViewController: self)
                revealPhoneVerificationStep(animated: true)
                let successMessage = authenticationManager.isUsingPhoneAuthTestingMode
                    ? "Firebase verification is ready. Enter the 6-digit code"
                    : "SMS code sent. Enter the 6-digit code to complete sign-in."
                setStatus(successMessage, color: AppTheme.accent)
            } catch {
                setStatus(authenticationManager.messageForPhoneAuthError(error), color: AppTheme.danger.withAlphaComponent(0.14), textColor: AppTheme.danger)
            }
        }
    }

    @objc private func handleCompletePhoneSignIn() {
        dismissKeyboard()
        verifyPhoneCodeButton.setLoading(true)
        setStatus("Verifying SMS code…", color: AppTheme.secondarySurface)

        Task {
            defer { verifyPhoneCodeButton.setLoading(false) }

            do {
                try await authenticationManager.completePhoneSignIn(verificationCode: phoneCodeField.text ?? "")
            } catch {
                setStatus(authenticationManager.messageForPhoneAuthError(error), color: AppTheme.danger.withAlphaComponent(0.14), textColor: AppTheme.danger)
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        var rect = textField.convert(textField.bounds, to: scrollView)
        rect.size.height += 80
        scrollView.scrollRectToVisible(rect, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === phoneField {
            handleSendPhoneCode()
        } else if textField === phoneCodeField {
            handleCompletePhoneSignIn()
        }
        return true
    }
}
