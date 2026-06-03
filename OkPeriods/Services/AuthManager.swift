//
//  AuthManager.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

extension Notification.Name {
    static let emailLinkDidArrive = Notification.Name("emailLinkDidArrive")
}

enum AuthManagerError: LocalizedError {
    case missingGoogleClientID
    case invalidEmail
    case invalidEmailLink
    case missingVerificationLink
    case invalidPhoneNumber
    case missingPhoneVerificationID
    case invalidVerificationCode
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingGoogleClientID:
            return "Google Sign-In is not configured correctly for this build."
        case .invalidEmail:
            return "Enter a valid email address to continue."
        case .invalidEmailLink:
            return "That verification link is not valid for Firebase email sign-in."
        case .missingVerificationLink:
            return "Paste the verification link from your email or open it from the inbox on this device."
        case .invalidPhoneNumber:
            return "Enter a phone number with country code, for example +1 6505553434."
        case .missingPhoneVerificationID:
            return "Request a phone verification code first."
        case .invalidVerificationCode:
            return "Enter the 6-digit verification code from the SMS message."
        case .cancelled:
            return "The sign-in request was cancelled."
        }
    }
}

@MainActor
final class AuthenticationManager {
    static let shared = AuthenticationManager()

    private let auth = Auth.auth()
    private let defaults = UserDefaults.standard
    private let pendingEmailKey = "pending.email.address"
    private let pendingEmailLinkKey = "pending.email.link"
    private let pendingPhoneNumberKey = "pending.phone.number"
    private let pendingPhoneVerificationIDKey = "pending.phone.verificationID"

    private init() {
        #if targetEnvironment(simulator)
            auth.settings?.isAppVerificationDisabledForTesting = true
        #endif
    }

    var isUsingPhoneAuthTestingMode: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return auth.settings?.isAppVerificationDisabledForTesting ?? false
        #endif
    }

    var phoneAuthHelperText: String {
        if isUsingPhoneAuthTestingMode {
            return "Simulator testing mode is enabled. Use a fictional phone number and code configured in Firebase Authentication."
        }

        return "Enter a mobile number with country code to receive a one-time SMS verification code."
    }

    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthManagerError.missingGoogleClientID
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let signInResult: GIDSignInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        continuation.resume(throwing: AuthManagerError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthManagerError.cancelled)
                    return
                }

                continuation.resume(returning: result)
            }
        }

        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthManagerError.missingGoogleClientID
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: signInResult.user.accessToken.tokenString
        )

        _ = try await signIn(with: credential)
    }

    func sendEmailSignInLink(to email: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(normalizedEmail) else {
            throw AuthManagerError.invalidEmail
        }

        let actionCodeSettings = makeActionCodeSettings()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.sendSignInLink(toEmail: normalizedEmail, actionCodeSettings: actionCodeSettings) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        defaults.set(normalizedEmail, forKey: pendingEmailKey)
    }

    func completeEmailSignIn(email: String, link: String) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(normalizedEmail) else {
            throw AuthManagerError.invalidEmail
        }

        let normalizedLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedLink.isEmpty else {
            throw AuthManagerError.missingVerificationLink
        }
        guard auth.isSignIn(withEmailLink: normalizedLink) else {
            throw AuthManagerError.invalidEmailLink
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.signIn(withEmail: normalizedEmail, link: normalizedLink) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        clearPendingEmailFlow()
    }

    func handleIncomingEmailLink(_ url: URL) -> Bool {
        let link = url.absoluteString
        guard auth.isSignIn(withEmailLink: link) else {
            return false
        }

        defaults.set(link, forKey: pendingEmailLinkKey)
        NotificationCenter.default.post(name: .emailLinkDidArrive, object: nil)
        return true
    }

    func storedPendingEmail() -> String? {
        defaults.string(forKey: pendingEmailKey)
    }

    func storedPendingEmailLink() -> String? {
        defaults.string(forKey: pendingEmailLinkKey)
    }

    func rememberPendingEmail(_ email: String) {
        defaults.set(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), forKey: pendingEmailKey)
    }

    func signOut() throws {
        try auth.signOut()
        GIDSignIn.sharedInstance.signOut()
        clearPendingEmailFlow()
        clearPendingPhoneFlow()
    }

    func sendPhoneVerificationCode(to phoneNumber: String, presentingViewController: UIViewController) async throws {
        let normalizedPhoneNumber = Self.normalizePhoneNumber(phoneNumber)
        guard Self.isValidPhoneNumber(normalizedPhoneNumber) else {
            throw AuthManagerError.invalidPhoneNumber
        }

        let uiDelegate = ViewControllerAuthUIDelegate(viewController: presentingViewController)

        let verificationID: String = try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(normalizedPhoneNumber, uiDelegate: uiDelegate) { verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let verificationID else {
                    continuation.resume(throwing: AuthManagerError.missingPhoneVerificationID)
                    return
                }

                continuation.resume(returning: verificationID)
            }
        }

        defaults.set(normalizedPhoneNumber, forKey: pendingPhoneNumberKey)
        defaults.set(verificationID, forKey: pendingPhoneVerificationIDKey)
    }

    func completePhoneSignIn(verificationCode: String) async throws {
        let trimmedCode = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCode.count == 6, trimmedCode.allSatisfy(\.isNumber) else {
            throw AuthManagerError.invalidVerificationCode
        }
        guard let verificationID = defaults.string(forKey: pendingPhoneVerificationIDKey) else {
            throw AuthManagerError.missingPhoneVerificationID
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: trimmedCode
        )

        _ = try await signIn(with: credential)
        clearPendingPhoneFlow()
    }

    func storedPendingPhoneNumber() -> String? {
        defaults.string(forKey: pendingPhoneNumberKey)
    }

    func hasPendingPhoneVerification() -> Bool {
        defaults.string(forKey: pendingPhoneVerificationIDKey) != nil
    }

    func messageForPhoneAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        let errorName = (nsError.userInfo[AuthErrors.userInfoNameKey] as? String) ?? "UNKNOWN"
        let underlyingMessage = (nsError.userInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription
        let failureReason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String

        if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
            switch authErrorCode {
            case .appVerificationUserInteractionFailure, .webContextCancelled, .webContextAlreadyPresented, .webInternalError:
                if isUsingPhoneAuthTestingMode {
                    return "Simulator phone auth is running"
                }
                return "Phone auth couldn't complete app verification. On a real device, make sure Push Notifications/APNs are enabled for the app, or allow the reCAPTCHA screen to open and return."
            case .appNotAuthorized:
                return "This app build is not authorized for Firebase Auth. Check that the bundle ID matches the iOS app in Firebase and that the API key restrictions allow this bundle ID."
            case .captchaCheckFailed, .missingAppCredential, .invalidAppCredential:
                return "Firebase could not verify the app for phone auth. Re-check the iOS phone-auth setup in Firebase, then try again."
            case .quotaExceeded:
                return "Firebase phone-auth SMS quota has been exceeded for this project."
            case .invalidPhoneNumber:
                return AuthManagerError.invalidPhoneNumber.localizedDescription
            default:
                break
            }
        }

        let detailedReason = [failureReason, underlyingMessage].compactMap { $0 }.joined(separator: " ")
        if !detailedReason.isEmpty {
            return "\(nsError.localizedDescription) \(detailedReason) [\(errorName)]"
        }

        return "\(nsError.localizedDescription) [\(errorName)]"
    }

    private func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            auth.signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthManagerError.cancelled)
                    return
                }

                continuation.resume(returning: result)
            }
        }
    }

    private func clearPendingEmailFlow() {
        defaults.removeObject(forKey: pendingEmailKey)
        defaults.removeObject(forKey: pendingEmailLinkKey)
    }

    private func clearPendingPhoneFlow() {
        defaults.removeObject(forKey: pendingPhoneNumberKey)
        defaults.removeObject(forKey: pendingPhoneVerificationIDKey)
    }

    private func makeActionCodeSettings() -> ActionCodeSettings {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.anupambharti.OkPeriods"
        let projectID = FirebaseApp.app()?.options.projectID ?? "tasks-9b50a"

        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(bundleIdentifier)
        actionCodeSettings.url = URL(string: "https://\(projectID).firebaseapp.com/finishSignIn")
        return actionCodeSettings
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private static func normalizePhoneNumber(_ phoneNumber: String) -> String {
        phoneNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }

    private static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let pattern = #"^\+[0-9]{8,15}$"#
        return phoneNumber.range(of: pattern, options: .regularExpression) != nil
    }
}

private final class ViewControllerAuthUIDelegate: NSObject, AuthUIDelegate {
    weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        viewController?.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        viewController?.dismiss(animated: flag, completion: completion)
    }
}
