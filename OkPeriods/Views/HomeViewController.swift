//
//  HomeViewController.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import UIKit
import FirebaseAuth

final class HomeViewController: UIViewController {
    private let user: User
    private let authenticationManager = AuthenticationManager.shared

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStack = UIStackView()
    private let heroView = GradientHeroView()
    private let welcomeLabel = UILabel()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let detailsCard = SurfaceCardView()
    private let signOutButton = ActionButton(title: "Sign out", style: .primary)

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLayout()
        configureContent()
    }

    private func configureView() {
        view.backgroundColor = AppTheme.background
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        heroView.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = 24

        contentStack.addArrangedSubview(heroView)
        contentStack.addArrangedSubview(detailsCard)
        contentStack.addArrangedSubview(signOutButton)

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

            heroView.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func configureContent() {
        welcomeLabel.text = "Authenticated"
        welcomeLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        welcomeLabel.font = .roundedStyle(.caption1, weight: .semibold)

        nameLabel.text = user.displayName ?? user.email ?? "Signed in successfully"
        nameLabel.textColor = .white
        nameLabel.font = .roundedStyle(.title1, weight: .bold)
        nameLabel.numberOfLines = 0

        subtitleLabel.text = "Your Firebase session is active"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        subtitleLabel.font = .roundedStyle(.body)
        subtitleLabel.numberOfLines = 0

        let heroTextStack = UIStackView(arrangedSubviews: [welcomeLabel, nameLabel, subtitleLabel])
        heroTextStack.axis = .vertical
        heroTextStack.spacing = 12
        heroTextStack.translatesAutoresizingMaskIntoConstraints = false
        heroView.addSubview(heroTextStack)

        NSLayoutConstraint.activate([
            heroTextStack.leadingAnchor.constraint(equalTo: heroView.leadingAnchor, constant: 24),
            heroTextStack.trailingAnchor.constraint(equalTo: heroView.trailingAnchor, constant: -24),
            heroTextStack.bottomAnchor.constraint(equalTo: heroView.bottomAnchor, constant: -24)
        ])

        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 18
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.addSubview(detailsStack)

        NSLayoutConstraint.activate([
            detailsStack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 24),
            detailsStack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 20),
            detailsStack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -20),
            detailsStack.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -24)
        ])

        let header = UILabel()
        header.text = "Session details"
        header.textColor = AppTheme.primaryText
        header.font = .roundedStyle(.headline, weight: .semibold)

        let provider = providerLabelText()
        detailsStack.addArrangedSubview(header)
        detailsStack.addArrangedSubview(makeFactRow(title: "Email", value: user.email ?? "Unavailable"))
        detailsStack.addArrangedSubview(makeFactRow(title: "Provider", value: provider))
        detailsStack.addArrangedSubview(makeFactRow(title: "User ID", value: user.uid))

        signOutButton.addTarget(self, action: #selector(handleSignOut), for: .touchUpInside)
    }

    private func makeFactRow(title: String, value: String) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = AppTheme.secondaryText
        titleLabel.font = .roundedStyle(.footnote, weight: .semibold)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = AppTheme.primaryText
        valueLabel.font = .roundedStyle(.body)
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func providerLabelText() -> String {
        let providerIDs = Set(user.providerData.map(\.providerID))

        if providerIDs.contains("google.com") {
            return "Google Sign-In"
        }

        if providerIDs.contains("password") {
            return "Email link verification"
        }

        return providerIDs.first ?? "Firebase Auth"
    }

    @objc private func handleSignOut() {
        do {
            try authenticationManager.signOut()
        } catch {
            showAlert(title: "Sign Out Failed", message: error.localizedDescription)
        }
    }
}
