//
//  BrowsingModel.swift
//  MultipeeLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miayzaki. All rights reserved.
//

import MultipeerConnectivity

final class BrowserModel: NSObject, MultipeerHelper {

    private enum BrowsingState {
        case invalid
        case valid
        case found
        case lost
    }

    private var browser: MCNearbyServiceBrowser?
    private var isAllowDupplicationID = false
    private (set) var foundPeerIDs: [MCPeerID] = []

    private var browserState: BrowsingState = .invalid {
        didSet {
            self.changedFoundPeerState?(self.foundPeerIDs)
        }
    }

    var changedFoundPeerState: (([MCPeerID]) -> Void)?

    init(isAllowDupplicationID: Bool=false) {
        super.init()
        self.isAllowDupplicationID = isAllowDupplicationID
    }

    private func browswerInit(peerID: MCPeerID, serviceType: String) {
        self.browser = MCNearbyServiceBrowser.init(peer: peerID, serviceType: serviceType)
        self.browser?.delegate = self
    }

    func start(peerID: MCPeerID, serviceType: String) {
        self.browswerInit(peerID: peerID, serviceType: serviceType)
        self.browser?.startBrowsingForPeers()
        self.browserState = .valid
    }

    func stop() {
        self.browser?.delegate = nil
        self.browser?.stopBrowsingForPeers()
        self.foundPeerIDs = []
        self.browser = nil
        self.browserState = .invalid
    }

    func inivitation(peerID: MCPeerID, session: MCSession, timeout: TimeInterval, withContext: Data?=nil) {
        self.browser?.invitePeer(peerID, to: session, withContext: withContext, timeout: timeout)
    }

    deinit {
       // Log("deinit:\(className)")
    }
}

extension BrowserModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if isAllowDupplicationID {
            foundPeerIDs.append(peerID)
        } else {
            foundPeerIDs.toUniqueAndUpdate(peerID: peerID)
        }
        self.browserState = .found
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.foundPeerIDs.deleteDeepEqual(peerID: peerID)
        self.browserState = .lost
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Log("did not Browsing for peers:\(error)")
    }
}
