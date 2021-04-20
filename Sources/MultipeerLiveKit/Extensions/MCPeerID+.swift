//
//  MCPeerID+.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miayzaki. All rights reserved.
//

import MultipeerConnectivity


public extension MCPeerID {

    var rawPointerHash: Int {
        return Unmanaged.passUnretained(self).toOpaque().hashValue
    }

    static func isBothSameName(_ l: MCPeerID, _ r: MCPeerID) -> Bool {
        return l.displayName == r.displayName
    }

}

extension Array where Element == MCPeerID {

    func isIncludeSameInstance(peerID: MCPeerID) -> Bool {
        for ele in self {
            if peerID === ele {return true}
        }
        return false
    }

    func isIncludeSameName(peerID: MCPeerID) -> Bool {
        return self.filter {MCPeerID.isBothSameName($0, peerID)}.isEmpty == false
    }

    func whereSameNames(peerID: MCPeerID) -> [Int] {
        let res = self.enumerated().compactMap {(arg) -> Int? in
            if MCPeerID.isBothSameName(peerID, arg.element) {return arg.offset}
            return nil
        }
        return res
    }

    func whereSameInstances(peerID: MCPeerID) -> [Int] {
        let res = self.enumerated().compactMap {(arg) -> Int? in
            if peerID === arg.element { return arg.offset}
            return nil
        }
        return res
    }

    mutating func deleteSameNames(peerID: MCPeerID) {
        let indexes = self.whereSameNames(peerID: peerID).reversed()
        guard indexes.isEmpty == false else {return}
        indexes.forEach {
            self.remove(at: $0)
        }
    }

    mutating func deleteDeepEqual(peerID: MCPeerID) {
        let res = self.enumerated().compactMap { (arg) -> Int? in
            if arg.element === peerID { return arg.offset }
            return nil
        }
        res.forEach {self.remove(at: $0)}
    }

    mutating func toUniqueAndUpdate(peerID: MCPeerID) {
        self.deleteSameNames(peerID: peerID)
        self.append(peerID)
    }
}
