//
//  RemoveFavoriteTableCellView.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/29/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Cocoa

protocol RemoveFavoriteCellDelegate: AnyObject {
    func removeFavoriteCellClicked(_ removeFavoriteCell: RemoveFavoriteTableCellView)
}

class RemoveFavoriteTableCellView: NSTableCellView {

    weak var delegate: RemoveFavoriteCellDelegate?

    @IBOutlet weak var removeButton: NSButton!
    
    @IBAction func tappedRemoveButton(_ sender: Any) {
        delegate?.removeFavoriteCellClicked(self)
    }
    
}
