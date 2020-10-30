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
        guard numberOfRows > 0 else {
            return
        }
        
        let padding: CGFloat = 20

        tableColumns.enumerated().forEach { column, tableColumn in
            var columnWidth: CGFloat = 0
            let headerWidth = tableColumn.headerCell.attributedStringValue.size().width

            (0..<numberOfRows).forEach { row in
                let cellView = view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView
                let width: CGFloat

                if let selectedCell = cellView as? SelectedTableCell {
                    width = selectedCell.frame.width
                } else {
                    width = cellView?.textField?.attributedStringValue.size().width ?? 0
                }

                columnWidth = max(width, columnWidth)
            }

            tableColumn.width = max(columnWidth, headerWidth) + padding
        }

        reloadData()
    }

}
