//
//  SettingViewController.swift
//  MultiPeerKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import MultipeerLiveKit

final class SettingViewController: UIViewController {
    private var sessionManager: MCSessionManager!
    private var peerTableViewModel: PeerTableViewModel!
    private var settingViewPresener: SettingViewPresenter!
    private var connectionButtonModel: ConnectionButtonModel!
    private var alertPresenter = AlertPresenter.init()

    private let margin: CGFloat = 5
    private let timeout: TimeInterval = 5
    
    private let serviceType = "debug-demo"
    private let displayName = UIDevice.current.name
    private let serviceProtocol:MCSessionManager.ServiceProtocol = .textAndVideo

    private func setUpSessionManager() {
        sessionManager = MCSessionManager.init(displayName: displayName, serviceType: serviceType,serviceProtocol: serviceProtocol)
        sessionManager.onStateChanaged(connecting: {[weak self] (peerID, state) in
            guard let self = self else {return}
            self.updateConnectedPeerIDs()
            self.updateCellDataIfStateChanged(peerID: peerID, state: state)
            }, foundPeerIDs: {[weak self](ids) in
                guard let self = self else {return}
                self.updateFoundCell(ids)
        })
        setUpOnInvited()
    }

    private func setUpOnInvited() {
        let title = "Invitation from"
        let acceptTitle = "Accept"
        let cancelTitle = "Decline"
        sessionManager.onInvited {[weak self] (fromPeerID, answerCallback) in
            let message = "\(fromPeerID.displayName)"
            self?.alertPresenter.confirmAlert(title: title, message: message, acceptTitle: acceptTitle, cancelTitle: cancelTitle, acceptCallback: { (isAccept) in
                answerCallback(isAccept)
            })
        }
    }

    private func setUpViewPresenter() {
        settingViewPresener = SettingViewPresenter.init(margin: margin)
        self.view = settingViewPresener.setUpViews()
    }

    private func setUpButtonPresenter() {
        connectionButtonModel = ConnectionButtonModel.init(mcSessionManger: sessionManager)
        connectionButtonModel.setUpButtons(browsingButton: settingViewPresener.browserButton, advertiserButton: settingViewPresener.advertiserButton, connectionButton: settingViewPresener.connectionControlButton)
    }

    private func setUpFoundCellContents(cell: PeerIDTableCell, row: Int) {
        let foundCellData = self.peerTableViewModel.foundCellData
        guard foundCellData.isEmpty == false else {
            return
        }

        let data = foundCellData[row]
        let labelMessage = self.sessionManager.connectedPeerIDs.contains(data.peerID) ? "disconnect" : "invite"

        cell.cellContentCoordinator.displayName = data.peerID.displayName
        cell.cellContentCoordinator.buttonLabel = labelMessage
        cell.cellContentCoordinator.connectedState = data.connectionState

        cell.cellContentCoordinator.onTappedButton = {[weak self] (button) in
            guard let self = self else { return}
            let sameNameIndexes = PeerIDHelper.whereSameNames(ids: self.sessionManager.connectedPeerIDs, target: data.peerID)
            if sameNameIndexes.isEmpty {
                self.sessionManager.inviteTo(peerID: data.peerID, timeout: self.timeout)
            } else {
                self.sessionManager.canselConectRequestTo(peerID: data.peerID)
            }
        }
    }

    private func setUpConnectedCellContents(cell: PeerIDTableCell, row: Int) {
        let connectedCellData = self.peerTableViewModel.connectedCellData
        guard connectedCellData.isEmpty == false else {
            return
        }
        let data = connectedCellData[row]
        cell.cellContentCoordinator.displayName = data.peerID.displayName
        cell.cellContentCoordinator.buttonLabel = "Live"
        cell.cellContentCoordinator.connectedState = ""
        cell.cellContentCoordinator.onTappedButton = {[weak self](button) in
            guard let self = self else {return}
            let vc = LiveViewController.init(mcSessionManager: self.sessionManager, targetPeerID: data.peerID)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func setUpTableViewModel() {
        self.peerTableViewModel = PeerTableViewModel.init( tableView: settingViewPresener.peersTableView)

        self.peerTableViewModel.onSetUpCellContents = {[weak self](cell, indexPath) in
            guard let self = self else { return }
            guard self.sessionManager != nil else {
                return
            }

            let section = indexPath.section
            let row = indexPath.row

            if cell.cellContentCoordinator == nil {
                cell.cellContentCoordinator = CellContentCoodinator.init(margin: self.margin)
                cell.selectionStyle = .none
            }

            switch section {
            case 0:
                self.setUpFoundCellContents(cell: cell, row: row)
            case 1:
                self.setUpConnectedCellContents(cell: cell, row: row)
            default:break
            }
        }
    }

    private func updateCellDataIfStateChanged(peerID: MCPeerID, state: MCConnectionState) {
        self.peerTableViewModel.foundCellData =  self.peerTableViewModel.foundCellData.map {(idData) in
            guard idData.peerID == peerID && idData.connectionState != state.rawValue else {
                return idData
            }

            var stateDescription = state
            let sameInstances = self.sessionManager.connectedPeerIDs.filter { $0 === idData.peerID }

            if sameInstances.isEmpty == false {
                stateDescription = MCConnectionState.connected
            }

            let cellData = PeerIDCellData.init(peerID: idData.peerID, connectionState: stateDescription.rawValue)
            return cellData
        }

        DispatchQueue.main.async {[weak self] in
            self?.settingViewPresener.reloadData()
        }
    }

    private func updateFoundCell(_ ids: [MCPeerID]) {
        self.peerTableViewModel.foundCellData = ids.map {
            let isContains = PeerIDHelper.isContainsSameName(ids: self.sessionManager.connectedPeerIDs, target: $0)
            let description = isContains ? MCConnectionState.connected : MCConnectionState.connectionFail
            return PeerIDCellData.init(peerID: $0, connectionState: description.rawValue)
        }

        DispatchQueue.main.async {[weak self] in
            self?.settingViewPresener.reloadData()
        }
    }

    private func updateConnectedPeerIDs() {
        self.peerTableViewModel.connectedCellData = self.sessionManager.connectedPeerIDs.map {
            return PeerIDCellData.init(peerID: $0, connectionState: "")
        }
        DispatchQueue.main.async {[weak self] in
            self?.settingViewPresener.reloadData()
        }
    }

    private func setNavBar() {
        guard let navBar = navigationController?.navigationBar else {
            return
        }
        navBar.isTranslucent = false
        let customBackButton = UIBarButtonItem()
        customBackButton.title = ""
        customBackButton.isEnabled = true
        navigationItem.backBarButtonItem = customBackButton
    }

    override func loadView() {
        setNavBar()
        setUpViewPresenter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableViewModel()
        setUpSessionManager()
        setUpButtonPresenter()
    }
}
