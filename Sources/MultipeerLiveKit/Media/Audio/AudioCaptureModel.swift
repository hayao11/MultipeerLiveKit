//
//  AudioCaptureModel.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

final class AudioCaptureModel: NSObject, AudioOutputDelegate {

    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var mixerNode: AVAudioMixerNode!
    private var nodeBus: AVAudioNodeBus = 0
    private var bufferLate: Double = 0.1
    private var inputNode: AVAudioInputNode!
    private (set) var outputBuffer: AVAudioPCMBuffer!
    private let avAudioFormat: AVAudioFormat?

    init(avAudioFormat: AVAudioFormat?, nodeBus: AVAudioNodeBus=0, bufferLate: Double=0.1) throws {
        self.avAudioFormat = avAudioFormat
        super.init()
        self.nodeBus = nodeBus
        self.bufferLate = bufferLate
        try self.engineInit()
    }

    func audioRecordEnableTo(_ active: Bool) throws {
        if active {
            installTap()
            try engineStart()
        } else {
            engineStop()
            removeTap()
        }
    }

    private func engineInit() throws {
        engine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        let mainMixerNode = engine.mainMixerNode
        inputNode = engine.inputNode
        engine.attach(mixerNode)
        engine.connect(mixerNode, to: mainMixerNode, format: avAudioFormat)
        engine.connect(inputNode, to: mixerNode, format: avAudioFormat)
    }

    private func engineStart() throws {
        engine.prepare()
        try engine.start()
    }

    private func engineStop() {
        engine.stop()
    }

    private func removeTap() {
        mixerNode.removeTap(onBus: nodeBus)
    }

    private func installTap() {
        guard let _avAudioFormat = self.avAudioFormat else {
            return
        }

        let bufferSize = _avAudioFormat.sampleRate * bufferLate
        mixerNode.installTap(onBus: nodeBus, bufferSize: AVAudioFrameCount(bufferSize), format: self.avAudioFormat, block: {[weak self](buffer, _) in
            self?.outputBuffer = buffer
        })
    }

    deinit {
        Log("deinit:\(self.className)")
    }
}
