//
//  McSessionStreamHelper.swift
//  MultipeerLiveKit
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miayazaki. All rights reserved.
//

import MultipeerConnectivity

struct MCStreamHelper {

    func send(session: MCSession, data: Data, sendMode: MCSessionSendDataMode, targets: [MCPeerID]) throws {
        try session.send(data, toPeers: targets, with: sendMode)
    }

    func startStream(session: MCSession, audioData: NSData, name: String, targetPeerID: MCPeerID) throws {

        let pointerData = VideoDataConverter.createPointerFrom(nsData: audioData)
        let outputStream = try session.startStream(withName: name, toPeer: targetPeerID)

        sendStream(outputStream: outputStream, name: name, unsafePointer: pointerData.pointer, dataSize: pointerData.size)

    }

    func startStream(session: MCSession, image: UIImage, name: String, targetPeerID: MCPeerID) throws {

        guard let pointerData = VideoDataConverter.createDataFrom(image: image) else {return}

        let outputStream = try session.startStream(withName: name, toPeer: targetPeerID)
        sendStream(outputStream: outputStream, name: name, unsafePointer: pointerData.0, dataSize: pointerData.1)

    }

    private func sendStream(outputStream: OutputStream, name: String, unsafePointer: UnsafePointer<UInt8>, dataSize: Int) {

        let runLoopMode = RunLoop.Mode.default
        let runLoop = RunLoop.current

        outputStream.schedule(in: runLoop, forMode: runLoopMode)
        outputStream.open()

        defer {
            outputStream.remove(from: runLoop, forMode: runLoopMode)
            outputStream.close()
        }

        guard outputStream.hasSpaceAvailable else { return }
        outputStream.write(unsafePointer, maxLength: dataSize)
    }

    func openStream(_ stream: InputStream, readBufferSize: Int, receivedCallback: (Data) -> Void) {

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: readBufferSize)
        let runLoopMode = RunLoop.Mode.default
        let runLoop = RunLoop.current
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
