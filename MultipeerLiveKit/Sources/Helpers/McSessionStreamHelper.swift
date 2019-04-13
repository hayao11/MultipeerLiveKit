//
//  McSessionStreamHelper.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miayazaki. All rights reserved.
//

import MultipeerConnectivity

struct MCStreamHelper {
    private let waitIntervalForReadStream:TimeInterval
    private var readQueue:DispatchQueue
    private let readBufferSize:Int
    private let imageDataType:VideoDataConverter.ConvertImageType
    private let quality:CGFloat

    private let runLoopMode = RunLoop.Mode.default
    private let runLoop = RunLoop.current
    
    init(imageDataType:VideoDataConverter.ConvertImageType ,
         quality:CGFloat,readBufferSize:Int,
         waitIntervalForReadStream:TimeInterval,readQueue:DispatchQueue){
        self.imageDataType = imageDataType
        self.quality = quality
        self.readBufferSize = readBufferSize
        self.waitIntervalForReadStream = waitIntervalForReadStream
        self.readQueue = readQueue
    }
   
    func convertImageDataFrom(image:UIImage) -> (pointer:UnsafePointer<UInt8>,size:Int)? {
        switch imageDataType {
        case .jpg:
            return VideoDataConverter.createJpegDataFrom(image: image, quality: quality)
        case .png:
            return VideoDataConverter.createPngDataFrom(image: image)
        }
    }

    func send(session: MCSession, data: Data, sendMode: MCSessionSendDataMode, targets: [MCPeerID]) throws {
        try session.send(data, toPeers: targets, with: sendMode)
    }

    func startStream(session: MCSession, audioData: NSData, name: String, targetPeerID: MCPeerID) throws {

        let pointerData = VideoDataConverter.createPointerFrom(nsData: audioData)
        let outputStream = try session.startStream(withName: name, toPeer: targetPeerID)

        sendStream(outputStream: outputStream, name: name, unsafePointer: pointerData.pointer, dataSize: pointerData.size)

    }

    func startStream(session: MCSession, image: UIImage, name: String, targetPeerID: MCPeerID) throws {
        guard let pointerData = convertImageDataFrom(image: image) else {return}

        let outputStream = try session.startStream(withName: name, toPeer: targetPeerID)
        sendStream(outputStream: outputStream, name: name, unsafePointer: pointerData.0, dataSize: pointerData.1)

    }
    
    func readStream(_ stream: InputStream, fromPeerID: MCPeerID,callback:@escaping(Data,MCPeerID)->Void) {
        readQueue.asyncAfter(deadline: .now() + waitIntervalForReadStream, execute: {
            self.openStream(stream, readBufferSize: self.readBufferSize, receivedCallback: { (data) in
                callback(data,fromPeerID)
            })
        })
    }

    private func sendStream(outputStream: OutputStream, name: String, unsafePointer: UnsafePointer<UInt8>, dataSize: Int) {

        outputStream.schedule(in: runLoop, forMode: runLoopMode)
        outputStream.open()

        defer {
            outputStream.remove(from: runLoop, forMode: runLoopMode)
            outputStream.close()
        }

        guard outputStream.hasSpaceAvailable else { return }
        outputStream.write(unsafePointer, maxLength: dataSize)
    }

   private func openStream(_ stream: InputStream, readBufferSize: Int, receivedCallback: (Data) -> Void) {

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: readBufferSize)
        var data = Data()

        stream.schedule(in: runLoop, forMode: runLoopMode)
        stream.open()

        defer {
            stream.remove(from: runLoop, forMode: runLoopMode)
            stream.close()
            buffer.deallocate()
        }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: readBufferSize)
            data.append(buffer, count: read)
        }

        receivedCallback(data)
    }
}
