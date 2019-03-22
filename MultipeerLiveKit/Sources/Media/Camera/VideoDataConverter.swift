//
//  VideoDataConverter.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import AVFoundation
import UIKit

struct VideoDataConverter {

    enum ConvertImageType {
        case jpg
        case png
    }

    static func unsafePointerFrom(buffer: CMSampleBuffer) -> (pointer: UnsafePointer<UInt8>, size: Int)? {
        guard let nsData = self.nsDataFrom(buffer: buffer) else {
            return nil
        }
        let unsafePointer = nsData.bytes.bindMemory(to: UInt8.self, capacity: 1)
        return (pointer:unsafePointer, size:nsData.length)
    }

    static func nsDataFrom(buffer: CMSampleBuffer) -> NSData? {
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return nil
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let length = bytesPerRow * height

        let data =  NSData(bytes: baseAddress, length: length)
        return data
    }

    static func convertImageFrom(buffer: CMSampleBuffer?) -> UIImage? {
        guard
            let _buffer = buffer,
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(_buffer)
            else { return nil }
        let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        return self.convertImageFrom(ciimage: ciimage)
    }

    static func convertImageFrom(ciimage: CIImage) -> UIImage? {
        let context: CIContext = CIContext.init(options: nil)
        guard let cgImage = context.createCGImage(ciimage, from: ciimage.extent) else {
            return nil
        }
        let image = UIImage.init(cgImage: cgImage, scale: 0, orientation: .right)
        return image
    }

    static func convertImageFrom(data: Data) -> UIImage? {
        let ciimage: CIImage = CIImage.init(data: data)!
        return self.convertImageFrom(ciimage: ciimage)
    }

    static func createPointerFrom(data: Data) -> (pointer: UnsafePointer<UInt8>, size: Int) {
        let nsData = data as NSData
        let unsafePointer = nsData.bytes.bindMemory(to: UInt8.self, capacity: 1)
        return (pointer:unsafePointer, size:nsData.length)
    }

    static func createPointerFrom(nsData: NSData) -> (pointer: UnsafePointer<UInt8>, size: Int) {
        let unsafePointer = nsData.bytes.bindMemory(to: UInt8.self, capacity: 1)
        return (pointer:unsafePointer, size:nsData.length)
    }

    static func createDataFrom(image: UIImage) -> (UnsafePointer<UInt8>, Int)? {
        guard let data = image.pngData() else {
            return nil
        }
        let nsData = data as NSData
        let unsafePointer = nsData.bytes.bindMemory(to: UInt8.self, capacity: 1)
        return (unsafePointer, nsData.length)
    }

    static func ImageToData(_ image: UIImage?, type: ConvertImageType) -> Data? {
        guard let _image = image else {return nil}
        switch type {
        case .png:
            return _image.pngData()
        case .jpg:
            return _image.jpegData(compressionQuality: 1.0)
        }
    }
}
