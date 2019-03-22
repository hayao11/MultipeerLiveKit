//
//  AudioPlayer.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

struct AudioPlayer {

    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var mixerNode: AVAudioMixerNode!
    private let avAudioFormat: AVAudioFormat?

    init(avAudioFormat: AVAudioFormat?) throws {
        self.avAudioFormat = avAudioFormat
        try self.playerInit()
    }
    
    func playerStop() {
        playerNode.stop()
    }

    func playStartWithBuffer(_ buffer: AVAudioPCMBuffer)throws {
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    mutating func playerDeinit() {
        playerStop()
        engineStop()
    }

    private mutating func playerInit() throws {
        engine = AVAudioEngine.init()
        playerNode  = AVAudioPlayerNode.init()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: avAudioFormat)
        engine.prepare()
        try engineStart()
    }

    private func engineStart() throws {
        try engine.start()
    }

    private func engineStop() {
        engine.stop()
    }

    private func playWithFile(url: URL) throws {
        let audioFile = try AVAudioFile.init(forReading: url)
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
        playerNode.play()
    }
}
