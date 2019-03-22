//
//  VideoChatPresenter.swift
//  MultipeerKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation
import MultipeerConnectivity

public final class VideoChatPresenter: NSObject {
    //models
    private var mcSessionManager: MCSessionManager!
    private var audioPlayer: AudioPlayer!
    private var mediaPresenter: MediaPresenter!
    private var timerManager: TimerManager!
    //properties
    private (set) var isNeedsMute = false
    private var cameraInitPosition: AVCaptureDevice.Position
    private var sessionPreset: AVCaptureSession.Preset
    private let audioStreamName = "audio"
    private let convertImageDataType: VideoDataConverter.ConvertImageType = .png
    private var targetPeerID: MCPeerID!
    private var sendInterval: TimeInterval

    public var cameraPosition: AVCaptureDevice.Position? {
        return mediaPresenter?.cameraPosition
    }

    public var mediaData: (CMSampleBuffer?, AVAudioPCMBuffer?) {
        return self.mediaPresenter.resultBuffers
    }

    public var needsVideoRun = false {
        didSet {
            #if !targetEnvironment(simulator)
            return
            #else
            guard oldValue != needsVideoRun else {return}
            videoRunTo(needsVideoRun)
            #endif
        }
    }

    private let avAudioFormat: AVAudioFormat? = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
                                                              sampleRate: 44100.0,
                                                              channels: 1,
                                                              interleaved: true)

    public init(mcSessionManager: MCSessionManager, sendInterval: TimeInterval, targetPeerID: MCPeerID?=nil,
                cameraInitPosition: AVCaptureDevice.Position = .front, sessionPreset: AVCaptureSession.Preset = .low) throws {
        self.sendInterval = sendInterval
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

    public func soundToMute(_ flag: Bool) {
        isNeedsMute = flag
    }

    public func toDeinitModels() throws {
        #if !targetEnvironment(simulator)
        videoStop()
        try mediaPresenter.captureAudioSessionRunTo(false)
        mediaPresenter.captureSessionToRun(false)
        audioPlayer.playerStop()
        mediaPresenter = nil
        #endif
        audioPlayer = nil
    }

    private func videoRunTo(_ flag: Bool) {
        if timerManager == nil && flag {
            videoStart()
        } else if flag == false {
            videoStop()
        }
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

    public func bindReceivedCallbacks(gotImage:@escaping(UIImage?, MCPeerID) -> Void, gotTextMessage: ((String, MCPeerID)->Void)?=nil) {
        mcSessionManager.onReceivedData(audioCallback: {[weak self] (audioData, fromPeerID) in
            guard
                let weakSelf = self,
                let targetPeerID = weakSelf.targetPeerID,
                weakSelf.isNeedsMute == false
                else {
                    return
            }

            guard targetPeerID === fromPeerID else {
                return
            }
            weakSelf.playSound(audioData: audioData)

        }) {[weak self] (videoData, fromPeerID) in
            guard
                let weakSelf = self,
                let targetPeerID = weakSelf.targetPeerID
                else {return}

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

    private func initModels() throws {
        #if !targetEnvironment(simulator)
        try setUpCamera(initPosition: cameraInitPosition, sessionPreset: sessionPreset, avAudioFormat: avAudioFormat!)
        #endif
        try setUpAudioPlayer()
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
        timerManager.start(sendInterval)
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

    private func playSound(audioData: Data) {

        guard
            let audioPlayer = audioPlayer,
            let audioFormat = avAudioFormat
            else { return }

        let nsData = audioData as NSData
        guard let pcmBuffer = AudioConverter.dataToPCMBuffer( data: nsData, format: audioFormat) else {
            return
        }

        do {
            try audioPlayer.playStartWithBuffer(pcmBuffer)
        } catch let error {
            Log(error)
        }

    }

    deinit {
        Log("deinit:\(className)")
    }
}
