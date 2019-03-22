//
//  AlertPresenter.swift
//  MultiPeerLiveKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit

struct AlertPresenter {
    func confirmAlert(title: String, message: String, acceptTitle: String, cancelTitle: String, style: UIAlertController.Style = .alert, acceptCallback:@escaping(Bool) -> Void) {
        let alertContainer = UIAlertController.init(title: title, message: message, preferredStyle: style)
        let accept = UIAlertAction.init(title: acceptTitle, style: .default, handler: {_ in
            acceptCallback(true)
        })

        let cancel = UIAlertAction.init(title: cancelTitle, style: .cancel, handler: {_ in
            acceptCallback(false)
        })
        alertContainer.addAction(accept)
        alertContainer.addAction(cancel)
        show(alertContainer: alertContainer)
    }

    func notice(title: String, message: String, style: UIAlertController.Style = .alert) {
        let alertContainer = UIAlertController.init(title: title, message: message, preferredStyle: style)
        let accept = UIAlertAction.init(title: "OK", style: .default)
        alertContainer.addAction(accept)
        show(alertContainer: alertContainer)
    }

    private func show(alertContainer: UIAlertController) {
        guard
            let window = UIApplication.shared.keyWindow,
            let vc = window.rootViewController
            else { return }
        
        vc.present(alertContainer, animated: false, completion: nil)
    }
}
