//
//  RandomGenerater.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import Foundation

struct RandomGenerater {
    enum SeedType: String, CaseIterable {
        case alphabed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        case num      = "0123456789"
        case symbol   = "!#$%&\"'()*+,-.:;<=>?[]{}~"
    }

    static func generateStringFromTime() -> String {
        return String(NSDate().timeIntervalSince1970)
    }

    static func generateFrom(seedTypes: [SeedType], size: Int) -> String {
        let seed = seedTypes.compactMap {$0.rawValue}.reduce("", {(accum, str) in accum + str})
        return self.generateStringFrom(seed: seed, size: size)
    }

    static func generateStringFrom(seed: String, size: Int) -> String {
        var res: [String] = []
        let seeds = seed.map {String($0)}
        while res.count < size {
            if let s = seeds.randomElement() {
                res.append(s)
            }
        }
        return res.reduce("", {(accum, str) in accum+str})
    }
}
