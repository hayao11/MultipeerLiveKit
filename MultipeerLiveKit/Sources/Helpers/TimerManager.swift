//
//  TimerManager.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import Foundation

final class TimerManager: NSObject {
    enum TimerStatus {
        case valid
        case inValid
    }

    private (set) var timerState: TimerStatus = .inValid
    private var timer: Timer!
    private let callback: ((TimerManager) -> Void)!

    init(callback:@escaping (TimerManager) -> Void) {
        self.callback = callback
    }

    @objc private func update() {
        self.callback(self)
    }

    func start(_ interval: TimeInterval) {
        guard timerState == .inValid else { return }
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(self.update),
            userInfo: nil,
            repeats: true
        )
        timer.fire()
        timerState = .valid
    }

    func stop() {
        guard timerState == .valid else { return }
        if timer.isValid {
            timer.invalidate()
            timer = nil
            timerState = .inValid
        }
    }

    deinit {
        Log("deinit:\(self.className)")
    }
}
