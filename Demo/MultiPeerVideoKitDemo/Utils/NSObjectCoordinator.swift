//
//  NSObjectCoordinator.swift
//  MultiPeerLiveKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import Foundation

struct NSObjectCoordinator {
    func initFrom<T: NSObject>(_ classType: T.Type) -> T? {
        guard let metaType = NSClassFromString(classType.description()) as? NSObject.Type else {
            return nil
        }
        if let instance = metaType.init() as? T {return instance}
        return nil
    }
}
