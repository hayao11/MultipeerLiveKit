//
//  UIView+.swift
//  MultiPeerLiveKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {
    var safeArea: ConstraintBasicAttributesDSL {
        #if swift(>=3.2)
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.snp
        }
        return self.snp
        #else
        return self.snp
        #endif
    }

    func toRoundly(_ rad: CGFloat) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = rad
    }

    func setUpGradient(colors: [UIColor], name: String="", startPoint: CGPoint=CGPoint.zero, endPoint: CGPoint=CGPoint.zero, locations: [NSNumber]?=[]) {
        let gradientLayer = CAGradientLayer()

        if name != ""{
            gradientLayer.name = name
        }

        if startPoint != CGPoint.zero || endPoint != CGPoint.zero {
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint   = endPoint
        }

        if let innerLocations = locations, innerLocations.count > 0 {
            gradientLayer.locations = innerLocations
        }

        gradientLayer.frame = self.bounds
        gradientLayer.colors = colors.map {$0.cgColor}
        self.layer.insertSublayer(gradientLayer, at: 0)

    }

    func removeLayer(name: String) {
        self.layer.sublayers?.forEach({ (layer) in
            if layer.name == name {
                layer.removeFromSuperlayer()
            }
        })
    }
}
