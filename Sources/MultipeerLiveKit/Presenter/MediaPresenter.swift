//
//  MediaPresenter.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

final class MediaPresenter: NSObject {
    //models
    private var cameraDelegate: VideoDataOutputDelegate?
    private var audioCaptureDelegate: AudioOutputDelegate?
    //properties
    private var isCapturing = false
    private let avAudioFormat: AVAudioFormat?
    var cameraPosition: AVCaptureDevice.Position? {
        return self.cameraDelegate?.position
    }

    var resultBuffers: (CMSampleBuffer?, AVAudioPCMBuffer?) {
        return (video: cameraDelegate?.resultBuffer, audio: audioCaptureDelegate?.outputBuffer)
    }

    init(initPosition: AVCaptureDevice.Position,
         sessionPreset: AVCaptureSession.Preset,
         avAudioFormat: AVAudioFormat?) throws {
        
        self.avAudioFormat = avAudioFormat
        super.init()
        try self.setMovieCameraModel(initPosition: initPosition, sessionPreset: sessionPreset)
        try self.setUpAudio()
        
    }

    func captureAudioSessionRunTo(_ flag: Bool) throws {
        try audioCaptureDelegate?.audioRecordEnableTo(flag)
    }

    func captureSessionToRun(_ flag: Bool) {
        if flag && isCapturing == false {
            self.cameraDelegate?.captureSessionStart()
            self.isCapturing = true
        } else if flag == false {
            self.cameraDelegate?.captureSessionStop()
            self.isCapturing = false
        }
    }

    func toggleCameraPosition() throws {
        #if !targetEnvironment(simulator)
        try cameraDelegate?.toggleCameraPosition()
        #endif
    }

    private func setUpAudio() throws {
        try audioCaptureDelegate = AudioCaptureModel.init(avAudioFormat: avAudioFormat)
        try audioCaptureDelegate?.audioRecordEnableTo(true)
    }

    private func deinitSessions() throws {
        try captureAudioSessionRunTo(false)
        cameraDelegate?.deinitCaptureSession()
    }

    private func setMovieCameraModel(initPosition: AVCaptureDevice.Position,
                                     sessionPreset: AVCaptureSession.Preset) throws {
        
        #if !targetEnvironment(simulator)
        cameraDelegate = SampleBufferCamera.init(initPosition: initPosition,
                                                 sessionPreset: sessionPreset)
        try cameraDelegate?.initUpMovieCamera()
        #else
        throw CameraError.canNotGetDevice
        #endif
        
    }

    deinit {
        Log("deinit:\(self.className)")
    }
}
