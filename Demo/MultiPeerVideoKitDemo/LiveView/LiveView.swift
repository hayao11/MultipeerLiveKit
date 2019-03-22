//
//  LiveView.swift
//  MultiPeerLiveKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit
import SnapKit

final class LiveView: NSObject {
    private var view: UIView!
    private let toHiddenKeyboardGesture = UITapGestureRecognizer.init()
    let imageView = UIImageView()
    let receivedTextLabel = UILabel()
    let sendTextField = UITextField()
    let textSendButton = UIButton()
    let changeCameraButton = UIButton()
    let cameraControlButton = UIButton()
    let buttonAreaStackView = UIStackView()
    let textAreaStackView = UIStackView()
    let soundControlButton = UIButton()

    private func setUpSoundControlButton(margin: CGFloat) {
        imageView.addSubview(soundControlButton)
        soundControlButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview().multipliedBy(0.1)
            make.width.equalToSuperview().multipliedBy(0.3)
            make.trailing.equalToSuperview().offset(-margin)
            make.bottom.equalToSuperview().offset(-margin)
        }
        soundControlButton.layoutIfNeeded()
        soundControlButton.toRoundly(margin)
    }

    @objc private func toHiddenKeyboard() {
        self.view.endEditing(true)
    }

    private func setUpSoundGesture() {
        toHiddenKeyboardGesture.addTarget(self, action: #selector(toHiddenKeyboard))
        toHiddenKeyboardGesture.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(toHiddenKeyboardGesture)
    }

    private func addViews() {
        view.addSubview(imageView)
        view.addSubview(textAreaStackView)
        view.addSubview(buttonAreaStackView)
        textAreaStackView.addArrangedSubview(receivedTextLabel)
        textAreaStackView.addArrangedSubview(sendTextField)
        buttonAreaStackView.addArrangedSubview(textSendButton)
        buttonAreaStackView.addArrangedSubview(cameraControlButton)
        buttonAreaStackView.addArrangedSubview(changeCameraButton)
    }

    func setUpViews(frame: CGRect, margin: CGFloat) -> UIView {
        view = UIView.init(frame: frame)

        addViews()

        imageView.snp.makeConstraints { (make) in
            make.width.top.leading.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.68)
        }

        let baseWidth: CGFloat = view.bounds.width - (margin * 2)

        textAreaStackView.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(margin)
            make.centerX.equalToSuperview()
            make.width.equalTo(baseWidth)
            make.height.equalToSuperview().multipliedBy(0.12)
        }

        buttonAreaStackView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(baseWidth)
            make.top.equalTo(textAreaStackView.snp.bottom).offset(margin)
            make.bottom.equalTo(view.safeArea.bottom).offset(-margin)
        }

        setUpViewProperties(margin: margin)
        setUpSoundControlButton(margin: margin)
        setUpSoundGesture()
        setUpKeyboardObserver()

        return self.view
    }

    private func setUpViewProperties(margin: CGFloat) {

        view.backgroundColor = Colors.whiteFb

        textAreaStackView.axis = .vertical
        textAreaStackView.distribution = .fillProportionally
        textAreaStackView.spacing = margin

        sendTextField.delegate = self

        buttonAreaStackView.axis = .horizontal
        buttonAreaStackView.distribution = .fillEqually
        buttonAreaStackView.spacing = margin

        textAreaStackView.arrangedSubviews.forEach {
            $0.toRoundly(margin)
        }

        buttonAreaStackView.arrangedSubviews.forEach {
            $0.backgroundColor = .black
            $0.toRoundly(margin)
        }
    }
}

extension LiveView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension LiveView {
    @objc func keyboardWillShow(notification: Notification?) {
        guard
            let duration: TimeInterval = notification?.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let keyBoardRect = (notification?.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        let keyboardHeight = keyBoardRect.height
        UIView.animate(withDuration: duration, animations: {[weak self]  in
            let transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
            self?.view.transform = transform
        })
    }

    @objc func keyboardWillHide(notification: Notification?) {
        guard
            let duration: TimeInterval = notification?.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Double
            else {
                return
        }
        UIView.animate(withDuration: duration, animations: {[weak self]  in
            self?.view.transform = CGAffineTransform.identity
        })
    }

    private func setUpKeyboardObserver() {
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notification.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func removeKeyboardObserver() {
        let notification = NotificationCenter.default
        notification.removeObserver(self)
    }
}
