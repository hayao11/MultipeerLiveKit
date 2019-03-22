//
//  DataReader.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import Foundation

struct DataReader {
    static func isImageData(_ target: Data, readSize: Int?=nil) -> Bool {

        guard
            let targetStr = try? self.toHexStringFrom(data: target, readSize: readSize)
            else {
                return false
        }

        if self.isPngImage(targetStr) { return true }
        return false
    }

    static let pngHeader = "89504E470D0A1A0A"

    static func isPngImage(_ str: String) -> Bool {

        if str == pngHeader {
            return true
        }
        return false
    }

    static func toHexStringFrom(data: Data, readSize: Int?=nil)throws -> String {

        let _readSize = (readSize == nil || readSize! >= data.count) ? data.count : readSize!
        let kbData = data.subdata(in: 0..<_readSize)
        let stringArray = kbData.map {String(format: "%02X", $0)}
        let binaryString = stringArray.joined(separator: "")

        return binaryString
    }

    private static func strictIsImage(_ str: String) -> Bool {

        let strReg = "[a-zA-Z0-9]"
        let isImageReg = "(^FFD8\(strReg)+FFD9$|^89504E470D0A1A0A\(strReg)+)"
        if str.range(of: isImageReg, options: .regularExpression, range: nil, locale: .current) != nil {
            return true
        }
        return false
    }
}
