//
//  MultipeerLiveKitTests.swift
//  MultipeerLiveKitTests
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import XCTest
import MultipeerConnectivity
import MultipeerLiveKit
@testable import MultipeerLiveKit


class MultipeerLiveVideoKitTests: XCTestCase {
    
    func testSendText() {
        let serviceType = "sendTest"
        let name = "manager"
        let testTimeout:TimeInterval = 5.0

        let expect = XCTestExpectation.init(description: "test")
        expect.expectedFulfillmentCount = 2
        var managers: [MCSessionManager] = []
        let sendText = "test"
        let serviceProtocol:MCSessionManager.ServiceProtocol = .textAndVideo

        for i in 0...1 {
            let manager = MCSessionManager.init(displayName: name + String(i), serviceType: serviceType,serviceProtocol: serviceProtocol)
            let livePresenter = try! LivePresenter.init(mcSessionManager: manager, sendVideoInterval: 0.1)

            manager.onStateChanaged(connecting: { (peerID, state) in
                
                switch state {
                case .connected:
                    livePresenter.updateTargetPeerID(peerID)
                    try! livePresenter.send(text: sendText, sendMode: .reliable)
                case .tryConnecting:break
                case .connectionFail:break
                }
                
            }) { (foundIDs) in
                foundIDs.forEach {
                    manager.inviteTo(peerID: $0, timeout: 10)
                }
            }
            manager.onInvited { (_, acceptAnswer) in
                acceptAnswer(true)
            }

            livePresenter.bindReceivedCallbacks(gotImage: { (_, _) in
                //
            }, gotAudioData: {(_, _) in
                //
            }, gotTextMessage: {(msg, fromPeerID) in
                if msg == sendText {
                    expect.fulfill()
                } else {
                    XCTAssert(false)
                }
            })

            manager.needsToRunSession = true
            manager.needsAdvertising = true
            manager.needsBrowsing = true
            managers.append(manager)
        }

        wait(for: [expect], timeout: testTimeout)
    }
}
