//
//  FavoriteToggleCellView.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/25/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

protocol FavoriteToggleCellDelegate: AnyObject {
    func favoriteToggleCellTapped(_ favoriteToggleCell: FavoriteToggleCellView)
}

class FavoriteToggleCellView: NSTableCellView {

    weak var delegate: FavoriteToggleCellDelegate?

    @IBOutlet weak var checkbox: NSButtonCell!

    @IBAction func checkboxAction(_ sender: Any) {
        delegate?.favoriteToggleCellTapped(self)
    }

}
