//
//  NSTableView+.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/29/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Cocoa

extension NSTableView {

    func resizeColumns() {
        tableColumns.enumerated().forEach { column, tableColumn in
            var columnWidth: CGFloat = 0

            (0..<numberOfRows).forEach { row in
                let cellView = view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView
                let width = cellView?.textField?.attributedStringValue.size().width ?? 0
                columnWidth = max(width, columnWidth)
            }

            tableColumn.width = columnWidth
        }

        reloadData()
    }

}
