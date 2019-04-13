//
//  PeerTableViewModel.swift
//  MultiPeerKitDemo
//
//  Created by hayaoMac on 2019/03/11.
//  Copyright © 2019年 Takashi Miyazaki. All rights reserved.
//

import UIKit
import MultipeerConnectivity

final class PeerTableViewModel: NSObject {

    enum PeerIDTableSections: CaseIterable {
        case founds
        case connected

        func titleLabel() -> String {
            switch self {
            case .founds:
                return "Found PeerIDs"
            case .connected:
                return "Connected PeerIDs"
            }
        }

        func cellData(_ model: PeerTableViewModel) -> [PeerIDCellData] {
            switch self {
            case .founds:
                return model.foundCellData
            case .connected:
                return model.connectedCellData
            }
        }

        var rowHeight: CGFloat {
            switch self {
            default:
                return 80
            }
        }

        var headerHeight: CGFloat {
            switch self {
            default:
                return 50
            }
        }

        var footerHeight: CGFloat {
            switch self {
            default:
                return 0
            }
        }
    }

    private let cellName: String = "Cell"

    var tappedCellButtonCallback: ((PeerIDTableCell, IndexPath) -> Void)?
    var foundCellData: [PeerIDCellData] = []
    var connectedCellData: [PeerIDCellData] = []
    var onSetUpCellContents: ((PeerIDTableCell, IndexPath) -> Void)?

    init(tableView: UITableView) {
        super.init()
        tableView.register(PeerIDTableCell.self, forCellReuseIdentifier: self.cellName)
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension PeerTableViewModel: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return PeerIDTableSections.allCases.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PeerIDTableSections.allCases[indexPath.section].rowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return PeerIDTableSections.allCases[section].headerHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return PeerIDTableSections.allCases[section].footerHeight
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return PeerIDTableSections.allCases[section].titleLabel()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PeerIDTableSections.allCases[section].cellData(self).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath) as? PeerIDTableCell else {
            return UITableViewCell()
        }
        onSetUpCellContents?(cell, indexPath)
        return cell
    }
}
