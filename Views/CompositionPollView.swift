// Copyright © 2021 Metabolist. All rights reserved.

import Combine
import UIKit
import ViewModels

final class CompositionPollView: UIView {
    private let viewModel: CompositionViewModel
    private let compositionInputAccessoryView: CompositionInputAccessoryView
    private let stackView = UIStackView()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: CompositionViewModel, inputAccessoryView: CompositionInputAccessoryView) {
        self.viewModel = viewModel
        self.compositionInputAccessoryView = inputAccessoryView

        super.init(frame: .zero)

        initialSetup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CompositionPollView {
    static let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .full

        return formatter
    }()

    static func format(expiry: CompositionViewModel.PollExpiry) -> String? {
        dateComponentsFormatter.string(from: TimeInterval(expiry.rawValue))
    }

    var pollOptionViews: [CompositionPollOptionView] {
        stackView.arrangedSubviews.compactMap({ $0 as? CompositionPollOptionView })
    }

    // swiftlint:disable:next function_body_length
    func initialSetup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .defaultSpacing

        let buttonsStackView = UIStackView()

        stackView.addArrangedSubview(buttonsStackView)
        buttonsStackView.distribution = .fillEqually

        let addChoiceButton = UIButton(primaryAction: UIAction { [weak self] _ in self?.viewModel.addPollOption() })

        buttonsStackView.addArrangedSubview(addChoiceButton)
        addChoiceButton.setImage(
            UIImage(systemName: "plus",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        addChoiceButton.setTitle(NSLocalizedString("compose.poll.add-choice", comment: ""), for: .normal)

        let expiresInButton = UIButton(type: .system)

        buttonsStackView.addArrangedSubview(expiresInButton)
        expiresInButton.setImage(
            UIImage(systemName: "clock",
                    withConfiguration: UIImage.SymbolConfiguration(scale: .medium)),
            for: .normal)
        expiresInButton.showsMenuAsPrimaryAction = true
        expiresInButton.menu = UIMenu(children: CompositionViewModel.PollExpiry.allCases.map { expiry in
            UIAction(title: Self.format(expiry: expiry) ?? "") { [weak self] _ in
                self?.viewModel.pollExpiresIn = expiry
            }
        })

        let switchStackView = UIStackView()

        switchStackView.spacing = .defaultSpacing

        stackView.addArrangedSubview(switchStackView)

        let allowMultipleLabel = UILabel()

        switchStackView.addArrangedSubview(allowMultipleLabel)
        allowMultipleLabel.adjustsFontForContentSizeCategory = true
        allowMultipleLabel.font = .preferredFont(forTextStyle: .callout)
        allowMultipleLabel.textColor = .secondaryLabel
        allowMultipleLabel.text = NSLocalizedString("compose.poll.allow-multiple-choices", comment: "")
        allowMultipleLabel.textAlignment = .right

        let allowMultipleSwitch = UISwitch()

        switchStackView.addArrangedSubview(allowMultipleSwitch)
        allowMultipleSwitch.addAction(
            UIAction { [weak self] _ in
                self?.viewModel.sensitive = allowMultipleSwitch.isOn
            },
            for: .valueChanged)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: .minimumButtonDimension)
        ])

        viewModel.$pollOptions.sink { [weak self] in
            guard let self = self else { return }

            addChoiceButton.isEnabled = $0.count < CompositionViewModel.maxPollOptionCount

            for (index, option) in $0.enumerated() {
                if !self.pollOptionViews.contains(where: { $0.option === option }) {
                    let optionView = CompositionPollOptionView(
                        viewModel: self.viewModel,
                        option: option,
                        inputAccessoryView: self.compositionInputAccessoryView)

                    self.stackView.insertArrangedSubview(optionView, at: index)
                }
            }

            for (index, optionView) in self.pollOptionViews.enumerated() {
                optionView.removeButton.isHidden = index < CompositionViewModel.minPollOptionCount

                if !$0.contains(where: { $0 === optionView.option }) {
                    optionView.removeFromSuperview()
                }
            }
        }
        .store(in: &cancellables)

        viewModel.$pollExpiresIn
            .sink { expiresInButton.setTitle(Self.format(expiry: $0), for: .normal) }
            .store(in: &cancellables)

        viewModel.$pollMultipleChoice
            .sink { allowMultipleSwitch.isEnabled = !$0 }
            .store(in: &cancellables)
    }
}