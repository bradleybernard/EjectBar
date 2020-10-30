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

        // Smaller to allow for spacing between the column values
        let valuePadding: CGFloat = 20

        // Larger to accomodate sorting by column (adds more width from chevron)
        let headerPadding: CGFloat = 40

        tableColumns.enumerated().forEach { column, tableColumn in
            var columnWidth: CGFloat = 0
            let headerWidth = tableColumn.headerCell.attributedStringValue.size().width

            (0..<numberOfRows).forEach { row in
                let cellView = view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView
                let width: CGFloat

                if let favoriteToggleCell = cellView as? FavoriteToggleCellView {
                    width = favoriteToggleCell.button?.intrinsicContentSize.width ?? 0
                } else if let removeFavoriteCell = cellView as? RemoveFavoriteTableCellView {
                    width = removeFavoriteCell.removeButton?.intrinsicContentSize.width ?? 0
                } else {
                    width = cellView?.textField?.attributedStringValue.size().width ?? 0
                }

                columnWidth = max(width, columnWidth)
            }

            // Choose either column (value) width or header width, then add padding depending on if it is a header or value
            tableColumn.width = max(columnWidth, headerWidth) + (columnWidth > headerWidth ? valuePadding : headerPadding)
        }

        reloadData()
    }

}
