//
//  ConnectionButtonView.swift
//  MultiPeerKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//
import UIKit
import MultipeerLiveKit

final class ConnectionButtonModel: NSObject {
    private weak var mcSessionManager: MCSessionManager!
    private let gradientName = "hitotsunaColor"
    private let gradientColors = [Colors.deepPink, Colors.lightPink]

    init(mcSessionManger: MCSessionManager?) {
        self.mcSessionManager = mcSessionManger
    }

    func setUpButtons(browsingButton: UIButton, advertiserButton: UIButton, connectionButton: UIButton) {

        browsingButton.addTarget(self, action: #selector(self.toggleBrwosing), for: .touchUpInside)
        advertiserButton.addTarget(self, action: #selector(self.toogleAdvertising), for: .touchUpInside)
        connectionButton.addTarget(self, action: #selector(self.togggleConnectionRunState), for: .touchUpInside)

        browsingButton.setTitle(RunStateType.browsing.rawValue, for: .normal)
        advertiserButton.setTitle(RunStateType.advertising.rawValue, for: .normal)
        connectionButton.setTitle(RunStateType.connectionRunning.rawValue, for: .normal)

        self.setGradient(isRun: mcSessionManager.needsToRunSession, button: connectionButton)

        mcSessionManager.onRunStateChange {[weak self] (stateType, isRun) in
            guard let self = self else {return}
            switch stateType {
            case .advertising:
                self.setGradient(isRun: isRun, button: advertiserButton)
            case .browsing:
                self.setGradient(isRun: isRun, button: browsingButton)
            case .connectionRunning:
                self.setGradient(isRun: isRun, button: connectionButton)
            }
        }
    }

    private func setGradient(isRun: Bool, button: UIButton) {
        if isRun {
            button.setUpGradient(colors: gradientColors, name: gradientName)
        } else {
            button.removeLayer(name: gradientName)
        }
    }

    @objc private func toogleAdvertising(_ sender: UIButton) {
        self.mcSessionManager?.needsAdvertising.toggle()
    }

    @objc private func toggleBrwosing(_ sender: UIButton) {
        self.mcSessionManager?.needsBrowsing.toggle()
    }

    @objc private func togggleConnectionRunState(_ sender: UIButton) {
        self.mcSessionManager?.needsToRunSession.toggle()
    }
}
