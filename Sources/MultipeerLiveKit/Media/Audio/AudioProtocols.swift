//
//  AudioProtocols.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/12.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation

protocol AudioOutputDelegate {
    var outputBuffer: AVAudioPCMBuffer! {get}
    func audioRecordEnableTo(_ active: Bool) throws
}
