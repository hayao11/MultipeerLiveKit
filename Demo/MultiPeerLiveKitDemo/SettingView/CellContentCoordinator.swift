//
//  CellContentCoordinator.swift
//  MultiPeerKitDemo
//
//  Created by hayaoMac on 2019/03/13.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit

final class CellContentCoodinator: NSObject {
    private let button = UIButton()
    private let labelStackView = UIStackView()
    private let displayNameLabel = UILabel()
    private let connectedStateLabel = UILabel()
    private let baseStackView = UIStackView()
    private var margin: CGFloat

    var displayName: String {
        set {
            DispatchQueue.main.async {[weak self] in
                self?.displayNameLabel.text = newValue
            }
        }
        get {
            guard let text = displayNameLabel.text else {
                return ""
            }
            return text
        }

    }

    var connectedState: String {
        set {
            DispatchQueue.main.async {[weak self] in
                self?.connectedStateLabel.text = newValue
            }
        }
        get {
            guard let text = connectedStateLabel.text else {
                return ""
            }
            return text
        }
    }

    var buttonLabel: String {
        set {
            DispatchQueue.main.async {[weak self] in
                self?.button.setTitle(newValue, for: .normal)
            }
        }

        get {
            guard let text = button.titleLabel?.text else {
                return ""
            }
            return text
        }
    }

    var onTappedButton: ((UIButton) -> Void)?

    init(margin: CGFloat) {
        self.margin = margin
    }

    func attachViews(cell: PeerIDTableCell) {
        cell.contentView.addSubview(baseStackView)
        setUpCellContents()
    }

    @objc private func onTapped(_ sender: UIButton) {
        onTappedButton?(button)
    }

    private func setUpCellContents() {
        margin *= 2
        baseStackView.addArrangedSubview(labelStackView)
        baseStackView.addArrangedSubview(button)

        baseStackView.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview().offset(margin)
            make.bottom.trailing.equalToSuperview().offset(-margin)
        }

        labelStackView.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.7)
        }

        button.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.3)
        }

        labelStackView.addArrangedSubview(displayNameLabel)
        labelStackView.addArrangedSubview(connectedStateLabel)

        setUpProperties()
        setColors()

    }

    private func setUpProperties() {
        baseStackView.axis = .horizontal
        baseStackView.distribution = .fill

        labelStackView.axis = .vertical
        labelStackView.distribution = .fillProportionally

        button.addTarget(self, action: #selector(self.onTapped(_:)), for: .touchUpInside)
        button.toRoundly(margin)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontSizeToFitWidth = true

        displayNameLabel.adjustsFontSizeToFitWidth = true
        displayNameLabel.textAlignment = .left

        connectedStateLabel.adjustsFontSizeToFitWidth = true
        connectedStateLabel.textAlignment = .left

    }

    private func setColors() {
        button.backgroundColor = .red
    }
}
