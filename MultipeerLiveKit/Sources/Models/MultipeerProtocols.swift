//
//  MultipeerProtocols.swift
//  MultipeeLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity


public enum MCConnectionState: String {
    case tryConnecting
    case connected
    case connectionFail
}

public enum RunStateType: String {
    case advertising
    case browsing
    case connectionRunning = "connection"
}


enum MultipeerHelperRunState: String {
    case valid
    case invalid
}

protocol MultipeerHelper {
    func start(peerID: MCPeerID, serviceType: String)
    func stop()
}

protocol MultipeerControlDelegate {
    var connectedPeerIDs: [MCPeerID] { get }
    var stateCallback: ((MCHelperType, MCSessionState, MCPeerID) -> Void)? { get set }
    func start()
    func stop()
    func disconnect()
}

protocol SessionHelperProtocol:MCSessionDelegate {
    var connectingStateCallback: ((MCPeerID, MCConnectionState) -> Void)?{get set}
    var gotDataCallback: ((Data, MCPeerID) -> Void)?{get set}
    var receivedDataCallback: ((Data?, MCPeerID) -> Void)?{get set}
}

enum MCHelperType: String {
    case browser
    case advertiser
}
