//
//  SessionHelper.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/22.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity

final class SessionHelper:NSObject,SessionHelperProtocol{
    
    private let readQueue: DispatchQueue
    private let waitIntervalForReadStream: TimeInterval = 0.1
    private let encryptionPreference: MCEncryptionPreference
    private let readBufferSize:Int
    private var streamHelper:MCStreamHelper
    
    var connectingStateCallback: ((MCPeerID, MCConnectionState) -> Void)?
    var gotDataCallback: ((Data, MCPeerID) -> Void)?
    var receivedDataCallback: ((Data?, MCPeerID) -> Void)?
    
    init(readQueue:DispatchQueue,streamHelper:MCStreamHelper,readBufferSize:Int,encryptionPreference:MCEncryptionPreference = .required){
        self.readQueue = readQueue
        self.encryptionPreference = encryptionPreference
        self.streamHelper = streamHelper
        self.readBufferSize = readBufferSize
    }
}


extension SessionHelper: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            connectingStateCallback?(peerID, .tryConnecting)
        case .connected:
            connectingStateCallback?(peerID, .connected)
        case .notConnected:
            connectingStateCallback?(peerID, .connectionFail)
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        gotDataCallback?(data, peerID)
    }
    
    private func readStream(_ stream: InputStream, fromPeerID: MCPeerID) {
        readQueue.asyncAfter(deadline: .now() + waitIntervalForReadStream, execute: {[weak self] in
            guard let self = self else {return}
            self.streamHelper.openStream(stream, readBufferSize: self.readBufferSize, receivedCallback: {[weak self] (data) in
                guard let self = self else {return}
                self.receivedDataCallback?(data, fromPeerID)
            })
        })
        
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        guard stream.streamError == nil else {return}
        if stream.streamStatus == .notOpen {
            self.readStream(stream, fromPeerID: peerID)
        }
    }
    
    private func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        if encryptionPreference == .required {
            certificateHandler(true)
        }
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

