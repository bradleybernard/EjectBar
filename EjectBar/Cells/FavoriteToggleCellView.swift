//
//  FavoriteToggleCellView.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/25/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

protocol FavoriteToggleCellDelegate: AnyObject {
    func favoriteToggleCellClicked(_ favoriteToggleCell: FavoriteToggleCellView)
}

class FavoriteToggleCellView: NSTableCellView {

    weak var delegate: FavoriteToggleCellDelegate?

    @IBOutlet weak var button: NSButton!
    @IBOutlet weak var buttonCell: NSButtonCell!

    @IBAction func checkboxAction(_ sender: Any) {
        delegate?.favoriteToggleCellClicked(self)
    }

}
