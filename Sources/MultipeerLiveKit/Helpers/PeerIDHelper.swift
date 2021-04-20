//
//  PeerIDHelper.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/16.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity

public struct PeerIDHelper {
    public static func isContainsSameName(ids: [MCPeerID], target: MCPeerID) -> Bool {
        return ids.isIncludeSameName(peerID: target)
    }

    public static func isContainsSameInstance(ids: [MCPeerID], target: MCPeerID) -> Bool {
        return ids.isIncludeSameInstance(peerID: target)
    }

    public static func whereSameInstances(ids: [MCPeerID], target: MCPeerID) -> [Int] {
        return ids.whereSameInstances(peerID: target)
    }

    public static func whereSameNames(ids: [MCPeerID], target: MCPeerID) -> [Int] {
        return ids.whereSameNames(peerID: target)
    }

    public static func selectSameInstance(ids: [MCPeerID], target: MCPeerID) -> [MCPeerID] {
        return ids.filter {$0 === target}
    }

    public static func selectSameNames(ids: [MCPeerID], target: MCPeerID) -> [MCPeerID] {
        return ids.filter {$0.displayName == target.displayName}
    }
}
