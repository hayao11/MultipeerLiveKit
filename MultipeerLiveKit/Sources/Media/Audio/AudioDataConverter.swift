//
//  AudioDataConverter.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

struct AudioConverter {

    static func audioBufferToNSData(pcmBuffer: AVAudioPCMBuffer?) -> NSData? {
        guard let _pcmBuffer = pcmBuffer, let channelData = _pcmBuffer.floatChannelData else {
            return nil
        }
        let channelCount = 1
        let channels = UnsafeBufferPointer(start: channelData, count: channelCount)
        let data = NSData(bytes: channels[0], length: Int(_pcmBuffer.frameLength * _pcmBuffer.format.streamDescription.pointee.mBytesPerFrame))
        return data

    }

    static func dataToPCMBuffer(data: NSData, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let chanelLengh = format.streamDescription.pointee.mBytesPerFrame
        let frameCapacity = UInt32(data.length) / chanelLengh
        guard
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)
            else { return nil }

        audioBuffer.frameLength = audioBuffer.frameCapacity
        let channels = UnsafeBufferPointer(start: audioBuffer.floatChannelData, count: Int(audioBuffer.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]), length: data.length)
        return audioBuffer
    }

}
