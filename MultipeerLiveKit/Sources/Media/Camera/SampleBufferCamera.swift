//
//  SampleBufferCamera.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation


final class SampleBufferCamera: NSObject, VideoDataOutputDelegate {

    private var captureDevice: AVCaptureDevice!
    private var captureSession: AVCaptureSession!
    private var mediaType: AVMediaType = .video
    private var captureVideoDataOutput: AVCaptureVideoDataOutput!
    private var defualtCameraDeviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
    private let queue = DispatchQueue.init(label: "com.hayao.MultipeerLiveKit.videodata-ouput-queue")
    private let captureDurationTime = CMTime(value: 1, timescale: 30)
    private var sessionPreset: AVCaptureSession.Preset
    private (set) var resultBuffer: CMSampleBuffer!

    var position: AVCaptureDevice.Position

    init(initPosition: AVCaptureDevice.Position, sessionPreset: AVCaptureSession.Preset) {
        self.position = initPosition
        self.sessionPreset = sessionPreset
    }

    func initUpMovieCamera() throws {
        captureSession = AVCaptureSession()
        try setUpDevice()
        try setUpCameraInput()
        setUpVideoDataOutput()
        setVideoDataSetting()
        captureSessionStart()
    }

    func captureSessionStart() {
        guard captureSession.isRunning == false else {return}
        captureSession.startRunning()
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: queue)
    }

    func captureSessionStop() {
        guard captureSession.isRunning else {return}
        captureSession.stopRunning()
    }

    func toggleCameraPosition() throws {
        position = position == .back ? .front : .back
        deinitCaptureSession()
        try initUpMovieCamera()
    }

    func deinitCaptureSession() {
        captureSessionStop()
        captureVideoDataOutput = nil
        captureSession.inputs.forEach {self.captureSession.removeInput($0)}
        captureSession.outputs.forEach {self.captureSession.removeOutput($0)}
        captureSession = nil
    }

    private func setVideoDataSetting() {
        captureDevice.activeVideoMinFrameDuration = captureDurationTime
        captureSession.sessionPreset = sessionPreset
    }

    private func setUpDevice() throws {
        let avCaptureDeviceType: [AVCaptureDevice.DeviceType] = [.builtInMicrophone, defualtCameraDeviceType]
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: avCaptureDeviceType, mediaType: mediaType, position: position)

        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == position {
                self.captureDevice = device
                break
            }
        }
        if captureDevice == nil {
            throw CameraError.canNotGetDevice
        }
    }

    private func setUpCameraInput() throws {
        let captureDeviceInput = try AVCaptureDeviceInput.init(device: captureDevice)
        captureSession.addInput(captureDeviceInput)
    }

    private func setUpVideoDataOutput() {
        captureVideoDataOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureVideoDataOutput)
    }
}

extension SampleBufferCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.resultBuffer = sampleBuffer
    }
}
