//
//  LivePresenter.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation
import MultipeerConnectivity

public final class LivePresenter: NSObject {
    //models
    private var mcSessionManager: MCSessionManager!
    private var audioPlayer: AudioPlayer!
    private var mediaPresenter: MediaPresenter!
    private var timerManager: TimerManager!
    //properties
    private var cameraInitPosition: AVCaptureDevice.Position
    private var sessionPreset: AVCaptureSession.Preset
    private let audioStreamName = "audio"
    private let convertImageDataType: VideoDataConverter.ConvertImageType = .png
    private var targetPeerID: MCPeerID!
    private var sendVideoInterval: TimeInterval

    public var cameraPosition: AVCaptureDevice.Position? {
        return mediaPresenter?.cameraPosition
    }

    public var mediaData: (CMSampleBuffer?, AVAudioPCMBuffer?) {
        return self.mediaPresenter.resultBuffers
    }

    public var needsVideoRun = false {
        didSet {
            #if !targetEnvironment(simulator)
            guard oldValue != needsVideoRun else {return}
            videoRunTo(needsVideoRun)
            #else
            return
            #endif
        }
    }

    private let avAudioFormat: AVAudioFormat? = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                                                              sampleRate: 44100.0,
                                                              channels: 1,
                                                              interleaved: true)

    public init(mcSessionManager: MCSessionManager, sendVideoInterval: TimeInterval, targetPeerID: MCPeerID?=nil,
                cameraInitPosition: AVCaptureDevice.Position = .front, sessionPreset: AVCaptureSession.Preset = .low) throws {
        self.sendVideoInterval = sendVideoInterval
        self.targetPeerID = targetPeerID
        self.cameraInitPosition = cameraInitPosition
        self.sessionPreset = sessionPreset
        self.mcSessionManager = mcSessionManager
        super.init()
        try initModels()
    }

    public func updateTargetPeerID(_ peerID: MCPeerID) {
        targetPeerID = peerID
    }

    public func toggleCamera() throws {
        #if !targetEnvironment(simulator)
        do {
            try mediaPresenter?.toggleCameraPosition()
        } catch let error {
            Log(error)
        }
        #endif
    }

    public func bindReceivedCallbacks(gotImage:@escaping(UIImage?, MCPeerID) -> Void, gotAudioData:@escaping(Data, MCPeerID) -> Void, gotTextMessage: ((String, MCPeerID)->Void)?=nil) {
        mcSessionManager.onReceivedData(audioCallback: {[weak self] (audioData, fromPeerID) in
            guard
                let weakSelf = self,
                let targetPeerID = weakSelf.targetPeerID
                else { return }

            guard targetPeerID === fromPeerID else {
                return
            }

            gotAudioData(audioData, fromPeerID)

        }) {[weak self] (videoData, fromPeerID) in
            guard
                let weakSelf = self,
                let targetPeerID = weakSelf.targetPeerID
                else {
                    return
            }

            guard targetPeerID === fromPeerID else {
                return
            }

            let image = VideoDataConverter.convertImageFrom(data: videoData)
            DispatchQueue.main.async {
                gotImage(image, fromPeerID)
            }
        }

        mcSessionManager.onReceivedTextData { (message, fromPeerID) in
            DispatchQueue.main.async {
                gotTextMessage?(message, fromPeerID)
            }
        }
    }

    public func send(text: String, sendMode: MCSessionSendDataMode) throws {
        guard let _targetPeerID = self.targetPeerID else { return }
        let data = text.data(using: .utf8)!
        try mcSessionManager.send(data: data, sendMode: sendMode, targets: [_targetPeerID])
    }

    public func playSound(audioData: Data) throws {

        guard
            let audioPlayer = audioPlayer,
            let audioFormat = avAudioFormat
            else { return }

        let nsData = audioData as NSData
        guard let pcmBuffer = AudioConverter.dataToPCMBuffer( data: nsData, format: audioFormat) else {
            return
        }

        try audioPlayer.playStartWithBuffer(pcmBuffer)

    }

    func toDeinitModels() throws {
        #if !targetEnvironment(simulator)
        videoStop()
        try mediaPresenter.captureAudioSessionRunTo(false)
        mediaPresenter.captureSessionToRun(false)
        audioPlayer.playerStop()
        mediaPresenter = nil
        #endif
        audioPlayer = nil
    }

    private func initModels() throws {
        #if !targetEnvironment(simulator)
        try setUpCamera(initPosition: cameraInitPosition, sessionPreset: sessionPreset, avAudioFormat: avAudioFormat!)
        #endif
        try setUpAudioPlayer()
    }

    private func videoRunTo(_ flag: Bool) {
        if timerManager == nil && flag {
            videoStart()
        } else if flag == false {
            videoStop()
        }
    }

    private func setUpAudioPlayer() throws {
        try audioPlayer = AudioPlayer.init(avAudioFormat: avAudioFormat)
    }

    private func setUpCamera(initPosition: AVCaptureDevice.Position, sessionPreset: AVCaptureSession.Preset, avAudioFormat: AVAudioFormat) throws {
        try mediaPresenter = MediaPresenter.init(initPosition: cameraInitPosition, sessionPreset: sessionPreset, avAudioFormat: avAudioFormat)
        mediaPresenter.captureSessionToRun(true)
    }

    private func videoStart() {
        guard mediaPresenter != nil else {
            return
        }

        timerManager = TimerManager.init(callback: {[weak self] (_) in
            guard let weakSelf = self else {return}
            weakSelf.sendVideo()
        })
        timerManager.start(sendVideoInterval)
    }

    private func videoStop() {
        guard timerManager != nil else {return}
        timerManager.stop()
        timerManager = nil
    }

    private func sendVideo() {

        guard
            let manager = mcSessionManager,
            let presenter = mediaPresenter,
            let peerID = targetPeerID
            else { return }

        let videoBuffer = presenter.resultBuffers.0
        let audioBuffer = presenter.resultBuffers.1

        do {
            let audioData = AudioConverter.audioBufferToNSData(pcmBuffer: audioBuffer)
            let image = VideoDataConverter.convertImageFrom(buffer: videoBuffer)
            let imageData = VideoDataConverter.ImageToData(image, type: convertImageDataType)
            try manager.send(videoData: imageData, audioData: audioData, audioStreamName: audioStreamName, sendMode: .reliable, target: peerID)
        } catch let error {
            Log(error)
        }

    }

    deinit {
        Log("deinit:\(className)")
    }
}
