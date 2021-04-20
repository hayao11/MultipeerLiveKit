//
//  AdvertiserModel.swift
//  MultipeeLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity

final class AdvertiserModel: NSObject, MultipeerHelper {

    private var advertiserAssistant: MCNearbyServiceAdvertiser?
    private var discoveryInfo: [String: String]?
    private var encryptionPreference: MCEncryptionPreference = .required

    var isAcceptInvitedCallback: ((MCPeerID, @escaping (Bool, MCSession) -> Void) -> Void)?

    init(encryptionPreference: MCEncryptionPreference = .required, discoveryInfo: [String: String]?=nil) {
        super.init()
        self.discoveryInfo = discoveryInfo
        self.encryptionPreference = encryptionPreference
    }

    private func advertiserInit(peerID: MCPeerID, serviceType: String) {
        advertiserAssistant = MCNearbyServiceAdvertiser.init(peer: peerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiserAssistant?.delegate = self
    }

    func start(peerID: MCPeerID, serviceType: String) {
        advertiserInit(peerID: peerID, serviceType: serviceType)
        advertiserAssistant?.startAdvertisingPeer()
    }

    func stop() {
        advertiserAssistant?.delegate = nil
        advertiserAssistant?.stopAdvertisingPeer()
        advertiserAssistant = nil
    }

    deinit {
       // Log("deinit:\(className)")
    }
}

extension AdvertiserModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        isAcceptInvitedCallback?(peerID, invitationHandler)
    }
}
