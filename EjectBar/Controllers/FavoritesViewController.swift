//
//  FavoritesViewController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/28/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Cocoa

class FavoritesViewController: NSViewController {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private var favorites: [Favorite] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
//                self?.tableView.resizeColumns()
            }
        }
    }

    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

//        tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("ID"))?.sortDescriptorPrototype = NSSortDescriptor(keyPath: \Favorite.id, ascending: true)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.intrinsicContentSize
//        NSLayoutConstraint.activate([
//            NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: tableView.intrinsicContentSize.height)
//        ])

//        tableViews.heightAnchor.constraint(equalToConstant: tableView.intrinsicContentSize.height).isActive = true

        setupNotifications()
        loadFavorites()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesViewController.favoritesUpdated(notification:)), name: .favoritesUpdated, object: nil)
    }

    @objc private func favoritesUpdated(notification: NSNotification) {
        guard let userInfo = notification.userInfo, let favorites = userInfo["favorites"] as? Set<Favorite> else {
            return
        }

        self.favorites = Array(favorites)
    }

    private func loadFavorites() {
        guard let appFavorites = (NSApp.delegate as? AppDelegate)?.favorites else {
            return
        }

        favorites = Array(appFavorites)
    }
    
}

extension FavoritesViewController: NSTableViewDelegate {

    private static let sizeFormatter = ByteCountFormatter()

    private enum CellIdentifier: String {
        case idCell = "FavoriteIDCell"
        case nameCell = "FavoriteNameCell"
        case dateCell = "FavoriteDateCell"
        case actionCell = "FavoriteActionCell"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        let cellIdentifier: CellIdentifier

        let favorite = favorites[row]

        if tableColumn == tableView.tableColumns[0] {
            text = favorite.id
            cellIdentifier = .idCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = favorite.name
            cellIdentifier = .nameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = Self.dateFormatter.string(for: favorite.date) ?? ""
            cellIdentifier = .dateCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = ""
            cellIdentifier = .actionCell
        } else {
            fatalError("Unknown tableView column \(String(describing: tableColumn))")
        }

        let identifier = NSUserInterfaceItemIdentifier(rawValue: cellIdentifier.rawValue)

        guard let tableCellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        switch cellIdentifier {
            case .actionCell:
                break
//                let selectedTableCell = tableCellView as? SelectedTableCell
//                selectedTableCell?.saveCheckbox.state = checkboxState(volume)
//                selectedTableCell?.saveCheckbox.action = #selector(VolumesController.checkboxSelected)
            default:
                tableCellView.textField?.stringValue = text
        }

        return tableCellView
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let favoritesSorted = (favorites as NSArray).sortedArray(using: tableView.sortDescriptors) as? [Favorite] else {
            return
        }

        favorites = favoritesSorted
        tableView.reloadData()
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }
}

extension FavoritesViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        favorites.count
    }

}

