//
//  SettingViewPresenter.swift
//  MultiPeerKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit

final class SettingViewPresenter: NSObject {
    private let view:UIView = .init(frame: UIScreen.main.bounds)
    private let containerStackView = UIStackView()
    let peersTableView = UITableView()
    let browserButton = UIButton()
    let advertiserButton = UIButton()
    let connectionControlButton = UIButton()

    private let margin: CGFloat

    init(margin: CGFloat) {
        self.margin = margin
    }

    func reloadData() {
        self.peersTableView.reloadData()
    }

    func setUpViews() -> UIView {

        view.addSubview(containerStackView)
        view.addSubview(peersTableView)

        let sides = (view.bounds.width - (margin * 4)) / 3

        containerStackView.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeArea.bottom).offset(-margin)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-margin*2)
            make.height.equalTo(sides+margin*2)
        }

        peersTableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(containerStackView.snp.top).offset(-margin)
        }
        self.tableToJustSize()
        self.setUpContainer(margin: margin, roundly: margin)
        view.backgroundColor = .groupTableViewBackground
        return view
    }

    private func tableToJustSize() {
        peersTableView.backgroundColor = .groupTableViewBackground
        let tableFooterView = UIView(frame: CGRect.zero)
        peersTableView.tableFooterView = tableFooterView
    }

    private func setUpContainer(margin: CGFloat, roundly: CGFloat) {
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        containerStackView.spacing = margin

        containerStackView.addArrangedSubview(browserButton)
        containerStackView.addArrangedSubview(advertiserButton)
        containerStackView.addArrangedSubview(connectionControlButton)
        containerStackView.arrangedSubviews.forEach {
            $0.toRoundly(roundly)
            $0.backgroundColor = .black
        }
    }
}
