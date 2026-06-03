//
//  UIComponents.swift
//  OkPeriods
//
//  Created by Anu on 03/06/26.
//

import UIKit

final class GradientHeroView: UIView {
    private let glowTop = UIView()
    private let glowBottom = UIView()

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        gradientLayer.colors = [AppTheme.heroStart.cgColor, AppTheme.heroEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.2)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.9)
        layer.cornerRadius = 32
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        [glowTop, glowBottom].forEach { glow in
            glow.backgroundColor = UIColor.white.withAlphaComponent(0.18)
            glow.translatesAutoresizingMaskIntoConstraints = false
            glow.layer.cornerRadius = 90
            addSubview(glow)
        }

        NSLayoutConstraint.activate([
            glowTop.widthAnchor.constraint(equalToConstant: 180),
            glowTop.heightAnchor.constraint(equalToConstant: 180),
            glowTop.topAnchor.constraint(equalTo: topAnchor, constant: -60),
            glowTop.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 48),

            glowBottom.widthAnchor.constraint(equalToConstant: 140),
            glowBottom.heightAnchor.constraint(equalToConstant: 140),
            glowBottom.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -36),
            glowBottom.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 52)
        ])
    }
}

final class SurfaceCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppTheme.surface
        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.borderColor = AppTheme.border.cgColor
        layer.borderWidth = 1
        layer.shadowColor = AppTheme.shadow.cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ActionButton: UIButton {
    enum Style {
        case primary
        case secondary
        case ghost
    }

    private let storedTitle: String
    private let style: Style

    init(title: String, style: Style) {
        self.storedTitle = title
        self.style = style
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ isLoading: Bool) {
        var updatedConfiguration = configuration
        updatedConfiguration?.showsActivityIndicator = isLoading
        updatedConfiguration?.title = storedTitle
        configuration = updatedConfiguration
        isEnabled = !isLoading
        alpha = isLoading ? 0.8 : 1.0
    }

    private func configure() {
        var buttonConfiguration: UIButton.Configuration
        let shouldApplyMinimumHeight: Bool
        switch style {
        case .primary:
            buttonConfiguration = .filled()
            buttonConfiguration.baseBackgroundColor = AppTheme.primaryAction
            buttonConfiguration.baseForegroundColor = .white
            shouldApplyMinimumHeight = true
        case .secondary:
            buttonConfiguration = .filled()
            buttonConfiguration.baseBackgroundColor = AppTheme.secondarySurface
            buttonConfiguration.baseForegroundColor = AppTheme.primaryText
            shouldApplyMinimumHeight = true
        case .ghost:
            buttonConfiguration = .plain()
            buttonConfiguration.baseForegroundColor = AppTheme.primaryAction
            shouldApplyMinimumHeight = false
        }

        var attributes = AttributeContainer()
        attributes.font = UIFont.roundedStyle(.headline, weight: .semibold)

        buttonConfiguration.title = storedTitle
        buttonConfiguration.cornerStyle = .capsule
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        buttonConfiguration.attributedTitle = AttributedString(storedTitle, attributes: attributes)
        configuration = buttonConfiguration
        translatesAutoresizingMaskIntoConstraints = false

        if shouldApplyMinimumHeight {
            heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        }
    }
}

final class InsetTextField: UITextField {
    private let textInset = UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInset)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInset)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInset)
    }

    private func configure() {
        backgroundColor = AppTheme.secondarySurface
        textColor = AppTheme.primaryText
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = AppTheme.border.cgColor
        font = .roundedStyle(.body)
        autocorrectionType = .no
        autocapitalizationType = .none
        spellCheckingType = .no
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
