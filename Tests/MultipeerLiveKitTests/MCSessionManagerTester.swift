//
//  MCSessionManagerTester.swift
//  MultipeerLiveKitTests
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import XCTest
import MultipeerConnectivity
import MultipeerLiveKit

final class MCSessionManagerTester: XCTestCase {

    func connectionTest() {
        let serviceType = "test"
        let timeout: TimeInterval = 3
        let serviceProtocol:MCSessionManager.ServiceProtocol = .textAndVideo
        let advertiser = MCSessionManager.init(displayName: "adv", serviceType: serviceType,serviceProtocol: serviceProtocol)
        let browser = MCSessionManager.init(displayName: "brow", serviceType: serviceType,serviceProtocol: serviceProtocol)
        let expect = XCTestExpectation.init(description: "connectionTest")
        expect.expectedFulfillmentCount = 2
        advertiser.onInvited { (id, isAccept) in
            XCTAssertEqual(id, browser.myPeerID!)
            isAccept(true)
        }

        advertiser.onStateChanaged(connecting: { (id, state) in
            switch state {
            case .connected:
                XCTAssertEqual(id, browser.myPeerID!)
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertEqual(browser.connectedPeerIDs.isEmpty, false)
                XCTAssertEqual(advertiser.connectedPeerIDs.isEmpty, false)
                expect.fulfill()
            case .connectionFail:
                print("fail")
            case .tryConnecting:
                print("try")
            }
        }) { _ in }

        browser.onStateChanaged(connecting: { (id, state) in
            switch state {
            case .connected:
                XCTAssertEqual(id, advertiser.myPeerID!)
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertEqual(browser.connectedPeerIDs.isEmpty, false)
                XCTAssertEqual(advertiser.connectedPeerIDs.isEmpty, false)
                expect.fulfill()
            case .tryConnecting:
                print("try")
            case .connectionFail:
                print("fail")
            }
        }) { (foundIDs) in
            foundIDs.forEach {
                browser.inviteTo(peerID: $0, timeout: 3)
            }
        }

        advertiser.needsToRunSession = true
        advertiser.needsAdvertising  = true
        XCTAssertEqual(advertiser.needsToRunSession, true)
        XCTAssertEqual(advertiser.needsAdvertising, true)
        XCTAssertEqual(advertiser.needsBrowsing, false)

        browser.needsToRunSession = true
        browser.needsBrowsing     = true
        XCTAssertEqual(browser.needsToRunSession, true)
        XCTAssertEqual(browser.needsBrowsing, true)
        XCTAssertEqual(browser.needsAdvertising, false)
        wait(for: [expect], timeout: timeout)

    }

    func connectionBugTest() {
        let expect = expectation(description: "connectionBug")
        let serviceType = "test"
        let serviceProtocol:MCSessionManager.ServiceProtocol = .textAndVideo

        let advertiser = MCSessionManager.init(displayName: "advertiser", serviceType: serviceType,serviceProtocol: serviceProtocol)
        let browser = MCSessionManager.init(displayName: "browser", serviceType: serviceType,serviceProtocol: serviceProtocol)
        var tryCnt  = 0
        let limit   = 3
        let timeout: TimeInterval = 10

        advertiser.onInvited { (_, answerCallback) in
            answerCallback(true)
        }

        advertiser.onStateChanaged(connecting: { (_, state) in
            switch state {
            case .connected:
                if tryCnt > limit {
                    expect.fulfill()
                    advertiser.needsToRunSession = false
                    browser.needsToRunSession = false
                } else {
                    DispatchQueue.main.async {
                        Thread.sleep(forTimeInterval: 0.1)
                        XCTAssertEqual(browser.connectedPeerIDs.isEmpty, false )
                        advertiser.needsToRunSession = false
                        advertiser.needsToRunSession = true
                        advertiser.needsAdvertising  = true
                        tryCnt += 1
                    }
                }
            case .connectionFail, .tryConnecting:break
            }
        }, foundPeerIDs: {_ in })

        browser.onStateChanaged(connecting: { (_, state) in
            switch state {
            case .connected:break
            case .connectionFail:break
            case .tryConnecting:break
            }
        }, foundPeerIDs: {(ids) in
            ids.forEach {
                browser.inviteTo(peerID: $0, timeout: 5)
            }
        })

        browser.needsToRunSession = true
        browser.needsBrowsing     = true
        
        advertiser.needsToRunSession = true
        advertiser.needsAdvertising  = true

        wait(for: [expect], timeout: timeout)
    }

    func test() {
        self.connectionBugTest()
        self.connectionTest()
    }
}
