//
//  utils.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import Foundation

func Log<T>(_ msg: T, funcName: String=#function, _ line: Int=#line, _ file: String=#file) {
    //#if DEBUG
    let fileName = file.split(separator: "/").last!
    let message = "Log -> func-name: \(funcName) line: \(line) file-name: \(fileName)\nmsg: \(msg) "
    print(message)
    //#endif
}
