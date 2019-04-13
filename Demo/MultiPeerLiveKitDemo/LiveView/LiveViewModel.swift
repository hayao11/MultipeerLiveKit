//
//  ViewModel.swift
//  MultiPeerLiveKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import MultipeerConnectivity
import MultipeerLiveKit
import AVFoundation

final class LiveViewModel: NSObject {
    //
    private var mcSessionManager: MCSessionManager!
    private var livePresenter: LivePresenter!
    //
    private var targetPeerID: MCPeerID?
    private var sendString = ""

    private var needsMute = false
    private let onColor: UIColor = .red
    private let offColor: UIColor = .black
    private let cameraFrontLabel = "front"
    private let cameraBackLabel = "back"
    private let sendTextButtonTitle = "send text"

    private enum ButtonType {
        case sound
        case sendVideo
    }

    typealias ButtonDisplayData = (title: String, color: UIColor)

    private lazy var soundBtnData: [Bool: ButtonDisplayData]    = [true: ("Sound ON", onColor), false: ("...", offColor)]
    private lazy var publishBtnData: [Bool: ButtonDisplayData]  = [true: ("ON AIR", onColor), false: ("OFF AIR", offColor)]


    init(targetPeerID: MCPeerID?, mcSessionManager: MCSessionManager,
         sendVideoInterval:TimeInterval,videoCompressionQuality:CGFloat,
         sessionPreset:AVCaptureSession.Preset = .low) throws {
        
        self.targetPeerID = targetPeerID
        super.init()
        self.mcSessionManager = mcSessionManager
        try livePresenter = LivePresenter.init(mcSessionManager: mcSessionManager,
                                               sendVideoInterval: sendVideoInterval,
                                               videoCompressionQuality:videoCompressionQuality,
                                               targetPeerID: targetPeerID,
                                               sessionPreset: sessionPreset)
    }

    func updatePeerID(_ peerID: MCPeerID) {
        livePresenter.updateTargetPeerID(peerID)
    }

    func attachViews(liveView: LiveView) {
        attachButtonActions(liveView)
        attachDisplayData(liveView)

        self.livePresenter.bindReceivedCallbacks(gotImage: {[liveView] (image, fromPeerID) in
            DispatchQueue.main.async {
                liveView.imageView.image = image
            }
        }, gotAudioData: {[weak self](audioData, fromPeerID) in
            guard let weakSelf = self else {return}
            if weakSelf.needsMute == false {
                do {
                    try weakSelf.livePresenter.playSound(audioData: audioData)
                } catch let error {
                    print(error)
                }
            }
        }, gotTextMessage: {[liveView](msg, fromPeerID) in
            DispatchQueue.main.async {
                liveView.receivedTextLabel.text = msg
            }
        })
    }

    private func attachButtonActions(_ liveView: LiveView) {

        liveView.soundControlButton.addTarget(self, action: #selector(toggleSouondMuteState(_:)), for: .touchUpInside)
        liveView.changeCameraButton.addTarget(self, action: #selector(cameraToggle(_:)), for: .touchUpInside)
        liveView.cameraControlButton.addTarget(self, action: #selector(toggleSendVideoData(_:)), for: .touchUpInside)
        liveView.textSendButton.addTarget(self, action: #selector(sendText), for: .touchUpInside)
        liveView.sendTextField.addTarget(self, action: #selector(onchangedTextField(_:)), for: .editingChanged)

    }

    private func attachDisplayData(_ liveView: LiveView) {

        let publishBtndata = setUpButtonLabel(buttonType: .sendVideo)
        let soundBtnData = setUpButtonLabel(buttonType: .sound)
        // title
        liveView.cameraControlButton.setTitle(publishBtndata.title, for: .normal)
        liveView.changeCameraButton.setTitle(setUpCameraPositionLabel(), for: .normal)
        liveView.soundControlButton.setTitle(soundBtnData.title, for: .normal)
        liveView.textSendButton.setTitle(sendTextButtonTitle, for: .normal)
        liveView.sendTextField.placeholder = "text"
        //colors
        liveView.imageView.backgroundColor = .black
        liveView.receivedTextLabel.backgroundColor = .white
        liveView.soundControlButton.backgroundColor = soundBtnData.color
        liveView.sendTextField.backgroundColor = .white
        liveView.textSendButton.setTitleColor(onColor, for: .highlighted)
        // others
        liveView.imageView.contentMode = .scaleAspectFit
        liveView.receivedTextLabel.adjustsFontSizeToFitWidth = true
        liveView.soundControlButton.layer.opacity = 0.5
        liveView.textSendButton.titleLabel?.adjustsFontSizeToFitWidth = true

    }

    @objc private func cameraToggle(_ sender: UIButton) {
        #if !targetEnvironment(simulator)

        do {
            try livePresenter.toggleCamera()
        } catch let error {
            print(error)
        }
        let title = setUpCameraPositionLabel()
        sender.setTitle(title, for: .normal)

        #endif
    }

    private func setUpCameraPositionLabel() -> String {
        guard let cameraPosition = livePresenter.cameraPosition else{
            return cameraFrontLabel
        }
        switch cameraPosition {
        case .back:
            return cameraBackLabel
        case .front:
            return cameraFrontLabel
        default:
            return ""
        }
    }

    private func setUpButtonLabel(buttonType: ButtonType) -> ButtonDisplayData {
        switch  buttonType {
        case .sound:
            return soundBtnData[!needsMute]!
        case .sendVideo:
            return publishBtnData[livePresenter.needsVideoRun]!
        }
    }

    @objc private func toggleSouondMuteState(_ sender: UIButton) {
        self.needsMute.toggle()

        let data = setUpButtonLabel(buttonType: .sound)
        sender.setTitle(data.title, for: .normal)
        sender.backgroundColor = data.color
    }

    @objc private func toggleSendVideoData(_ sender: UIButton) {
        #if !targetEnvironment(simulator)
        livePresenter.needsVideoRun.toggle()
        let data = publishBtnData[livePresenter.needsVideoRun]!
        sender.setTitle(data.title, for: .normal)
        sender.backgroundColor = data.color
        #endif
    }

    @objc private func sendText() {
        do {
            try livePresenter.send(text: sendString, sendMode: .unreliable)
        } catch let error {
            print(error)
        }
    }

    @objc private func onchangedTextField(_ sender: UITextField) {
        sendString = sender.text ?? ""
    }

    deinit {
         //print("deinit:LiveViewModel")
    }
}
