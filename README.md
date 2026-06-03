# OkPeriods Authentication Assessment

UIKit-based iOS authentication app for the OkPeriods internship assessment.

## What’s included

- Google Sign-In using Firebase Authentication
- Phone number OTP sign-in using Firebase Authentication
- Programmatic UIKit UI
- Auth state persistence and a signed-in success screen

## Requirements

- Xcode 26.5+
- iOS 26.5 simulator or device
- The included `GoogleService-Info.plist`

## Firebase notes

Google Sign-In is already wired to the included Firebase project.

On a real device, the app uses standard Firebase phone auth with APNs / app verification and can fall back to the Firebase reCAPTCHA flow when needed.

## How to run

1. Open `OkPeriods.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve dependencies.
3. Select an iPhone simulator or device.
4. Build and run.

## Architecture

- `AppDelegate` configures Firebase
- `SceneDelegate` owns root navigation and auth-state switching
- `AuthenticationManager` wraps FirebaseAuth and GoogleSignIn logic
- `AuthenticationViewController` renders the login experience
- `HomeViewController` shows successful authentication state
