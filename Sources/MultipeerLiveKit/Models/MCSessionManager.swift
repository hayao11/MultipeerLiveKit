
//
//  MCSessionManager.swift
//  MultipeeLiveVideoKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity

public final class MCSessionManager: NSObject,SessionHelperProtocol{
    //models
    private var browserModel: BrowserModel!
    private var advtiserModel: AdvertiserModel!
    private var videoOnlyHelper:VideoOnlyHelper!
    private var sessionHelperDelegate:SessionHelperProtocol?
    //callbacks
    var connectingStateCallback: ((MCPeerID, MCConnectionState) -> Void)?
    var gotDataCallback: ((Data, MCPeerID) -> Void)?
    var receivedDataCallback: ((Data?, MCPeerID) -> Void)?
    private var changedFoundPeerState: (([MCPeerID]) -> Void)?
    private var gotTextDataCallback: ((Data, MCPeerID) -> Void)?
    private var runStateChangedCallback: ((RunStateType, Bool) -> Void)?
    //properties
    private let readQueue: DispatchQueue = .init(label: "com.hayao.MultipeeLiveKit.read-stream-queue")
    
    private var readBufferSize = 24
    private let imageDataType:VideoDataConverter.ConvertImageType = .jpg
    private lazy var binaryImageReadSize = self.imageDataType == .jpg ? 2 : 8
    private let jpegCompressRatio:CGFloat = 1.0
    private var session: MCSession?
    private var encryptionPreference: MCEncryptionPreference!
    private var streamHelper: MCStreamHelper!
    private let discoveryInfo: [String: String]?
    private let isAllowDupplicationID: Bool = false
    private let waitIntervalForReadStream: TimeInterval = 0.1

    public func onRunStateChange(_ callback:@escaping(RunStateType, Bool) -> Void) {
        self.runStateChangedCallback = { (stateType, isRun) in
            callback(stateType, isRun)
        }
    }
    
    public var needsAdvertising = false {
        didSet {
            guard self.needsToRunSession else {
                needsAdvertising = false
                return
            }
            guard oldValue != needsAdvertising else { return }
            advertisingControl()
        }
    }
    
    public var needsBrowsing = false {
        didSet {
            guard self.needsToRunSession else {
                needsBrowsing = false
                return
            }
            guard oldValue != needsBrowsing else { return }
            browserControl()
        }
    }
    
    public var needsToRunSession = false {
        willSet {
            if newValue == false {
                needsAdvertising = false
                needsBrowsing = false
            }
        }
        didSet {
            guard oldValue != needsToRunSession else {return}
            toggleConnectionRunState()
        }
    }
    
    public var foundIDs: [MCPeerID] {
        get {
            guard let _browserModel = browserModel else {
                return []
            }
            return _browserModel.foundPeerIDs
        }
    }
    
    public var connectedPeerIDs: [MCPeerID] {
        guard let weakSession = session else {
            return []
        }
        return weakSession.connectedPeers
    }
    
    public enum ServiceProtocol:String{
        case textAndVideo = ""
        case videoOnly    = "-V"
    }

    public let serviceType: String
    public private (set) var displayName: String
    public private (set) var myPeerID:MCPeerID?
    public private (set) var serviceProtocol:ServiceProtocol
    
    public init(displayName: String, serviceType: String,
                serviceProtocol:ServiceProtocol = .textAndVideo,
                encryptionPreference: MCEncryptionPreference = .required,
                discoveryInfo: [String: String]?=nil) {
        
        self.serviceProtocol = serviceProtocol
        self.serviceType = serviceType + self.serviceProtocol.rawValue
        self.discoveryInfo = discoveryInfo
        self.encryptionPreference = encryptionPreference
        self.displayName = displayName
        super.init()
        self.streamHelper = MCStreamHelper.init(imageDataType: self.imageDataType,
                                                quality: jpegCompressRatio, readBufferSize: self.readBufferSize,
                                                waitIntervalForReadStream: self.waitIntervalForReadStream,
                                                readQueue: self.readQueue)
        self.sessionInit()
        
    }
    
    public func inviteTo(peerID: MCPeerID, timeout: TimeInterval) {
        guard let weakSession = self.session else {return}
        browserModel.inivitation(peerID: peerID, session: weakSession, timeout: timeout)
    }
    
    public func canselConectRequestTo(peerID: MCPeerID) {
        session?.cancelConnectPeer(peerID)
    }
    
    public func onInvited(_ answerCallback:@escaping(MCPeerID, @escaping(Bool)->Void)->Void) {
        self.advtiserModel.isAcceptInvitedCallback = {[weak self](fromPeerID, sessionCallback) in
            guard let self = self, let weakSession = self.session else {return}
            let acceptCallback: (Bool) -> Void = {(isAccept) in
                if isAccept {
                    sessionCallback(true, weakSession)
                }
            }
            answerCallback(fromPeerID, acceptCallback)
        }
    }
    
    public func onStateChanaged(connecting:@escaping(MCPeerID, MCConnectionState) -> Void, foundPeerIDs:@escaping([MCPeerID]) -> Void) {
        self.sessionHelperDelegate?.connectingStateCallback = {(id,state) in
            connecting(id,state)
        }
        
        self.browserModel.changedFoundPeerState = {(ids) in
            foundPeerIDs(ids)
        }
    }
    
    internal func onReceivedTextData(_ callback:@escaping(String, MCPeerID) -> Void) {
        self.gotTextDataCallback = {(data, id) in
            if let str = String.init(data: data, encoding: .utf8) {
                callback(str, id)
            }
        }
    }
    
    internal func send(data: Data, sendMode: MCSessionSendDataMode, targets: [MCPeerID]) throws {
        guard let weakSession = self.session else {return}
        guard self.serviceProtocol == .textAndVideo else { return }
        try streamHelper.send(session: weakSession, data: data, sendMode: sendMode, targets: targets)
    }
    
    
    internal func onReceivedData(audioCallback:@escaping(Data, MCPeerID) -> Void, imageCallback:@escaping(Data, MCPeerID) -> Void) {
        self.sessionHelperDelegate?.receivedDataCallback = {(data,fromPeerID) in
            if let _data = data{
                audioCallback(_data,fromPeerID)
            }
        }
        
        self.sessionHelperDelegate?.gotDataCallback = {(data,fromPeerID) in
            imageCallback(data,fromPeerID)
        }
    }
    
    internal func send(videoData: Data?, audioData: NSData?, audioStreamName: String, sendMode: MCSessionSendDataMode, target: MCPeerID) throws {
        guard let weakSession = self.session else {return}
        if let _videoData = videoData {
            try streamHelper.send(session: weakSession, data: _videoData, sendMode: sendMode, targets: [target])
        }
        if let _audioData  = audioData {
            let streamName = audioStreamName + RandomGenerater.generateStringFromTime()
            try streamHelper.startStream(session: weakSession, audioData: _audioData, name: streamName, targetPeerID: target)
        }
    }
    
    private func disconnect() {
        needsBrowsing = false
        needsAdvertising = false
        session?.disconnect()
        myPeerID = nil
    }
    
    private func sessionInit() {
        myPeerID = MCPeerID.init(displayName: displayName)
        session = MCSession.init(peer: myPeerID!, securityIdentity: nil, encryptionPreference: encryptionPreference)
        if browserModel == nil {
            browserModel = BrowserModel.init(isAllowDupplicationID: isAllowDupplicationID)
        }
        
        if advtiserModel == nil {
            advtiserModel = AdvertiserModel.init(encryptionPreference: encryptionPreference, discoveryInfo: discoveryInfo)
        }
        setUpDelegate()
    }
    
    private func setUpDelegate(){
        switch self.serviceProtocol {
        case .textAndVideo:
            sessionHelperDelegate = self
        case .videoOnly:
            if videoOnlyHelper == nil{
                
               videoOnlyHelper = VideoOnlyHelper.init(readQueue: readQueue, streamHelper: streamHelper,
                                                      readBufferSize: readBufferSize,
                                                      waitIntervalForReadStream: waitIntervalForReadStream,
                                                      encryptionPreference: encryptionPreference)
            }
            
            self.sessionHelperDelegate = videoOnlyHelper
        }
        session?.delegate = sessionHelperDelegate
    }
    
    private func toggleConnectionRunState() {
        if needsToRunSession {
            self.sessionInit()
        } else {
            self.disconnect()
        }
        runStateChangedCallback?(.connectionRunning, needsToRunSession)
    }
    
    private func browserControl() {
        let needsState: MultipeerHelperRunState = needsBrowsing ? .valid : .invalid
        self.helperRunTo(browserModel, needsState: needsState)
        runStateChangedCallback?(.browsing, needsBrowsing)
    }
    
    private func advertisingControl() {
        let needsState: MultipeerHelperRunState = needsAdvertising ? .valid : .invalid
        self.helperRunTo(advtiserModel, needsState: needsState)
        runStateChangedCallback?(.advertising, needsAdvertising)
    }
    
    private func helperRunTo(_ helper: MultipeerHelper, needsState: MultipeerHelperRunState) {
        switch needsState {
        case .valid:
            if let peerID = self.myPeerID {
                helper.start(peerID: peerID, serviceType: self.serviceType)
            }
        case .invalid:
            helper.stop()
        }
    }
    
    private func isImageData(data:Data) -> Bool{
        switch self.imageDataType {
        case .jpg:
            return DataReader.isJpegImageData(data, readSize: self.binaryImageReadSize)
        case .png:
            return DataReader.isPngImageData(data, readSize: self.binaryImageReadSize)
        }
    }
    
    deinit {
        disconnect()
        //Log("deinit:\(className)")
    }
}

extension MCSessionManager: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            self.sessionHelperDelegate?.connectingStateCallback?(peerID, .tryConnecting)
        case .connected:
            self.sessionHelperDelegate?.connectingStateCallback?(peerID, .connected)
        case .notConnected:
            self.sessionHelperDelegate?.connectingStateCallback?(peerID, .connectionFail)
        @unknown default:
            fatalError()
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if self.isImageData(data: data){
            gotDataCallback?(data,peerID)
        }else{
            gotTextDataCallback?(data,peerID)
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        guard stream.streamError == nil else {return}
        if stream.streamStatus == .notOpen {
           self.streamHelper.readStream(stream, fromPeerID: peerID) {[weak self] (data, fromPeerID) in
                guard let self = self else {return}
                self.receivedDataCallback?(data, fromPeerID)
            }
        }
    }
    
    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        if encryptionPreference == .required {
            certificateHandler(true)
        }
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

