//
//  CameraProtocols.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

protocol VideoDataOutputDelegate {
    var resultBuffer: CMSampleBuffer! {get}
    var position: AVCaptureDevice.Position {get}
    func initUpMovieCamera() throws
    func toggleCameraPosition() throws
    func captureSessionStop()
    func captureSessionStart()
    func deinitCaptureSession()
}

enum CameraError: Error {
    case canNotGetDevice
}
