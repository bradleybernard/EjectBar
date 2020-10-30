//
//  FavoritesViewController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/28/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Cocoa

class FavoritesViewController: NSViewController {

    private var favorites: [Favorite] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.tableView.resizeColumns()
                self?.view.window?.resizeToFitTableView(tableView: self?.tableView)
            }
        }
    }

    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotifications()
        loadFavorites()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesViewController.favoritesUpdated(notification:)), name: .favoritesUpdated, object: nil)
    }

    private func loadFavorites() {
        guard let appFavorites = (NSApp.delegate as? AppDelegate)?.favorites else {
            return
        }

        favorites = Array(appFavorites)
    }

    @objc private func favoritesUpdated(notification: NSNotification) {
        guard let userInfo = notification.userInfo, let favorites = userInfo["favorites"] as? Set<Favorite> else {
            return
        }

        self.favorites = Array(favorites)
    }
    
}

// MARK: - NSTableViewDelegate

extension FavoritesViewController: NSTableViewDelegate {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private enum CellIdentifier: String {
        case id = "FavoriteIDCell"
        case name = "FavoriteNameCell"
        case date = "FavoriteDateCell"
        case action = "FavoriteActionCell"
    }

    private enum ColumnIdentifier: String {
        case id = "FavoriteIDColumn"
        case name = "FavoriteNameColumn"
        case date = "FavoriteDateColumn"
        case action = "FavoriteActionColumn"

        var cellIdentifier: CellIdentifier {
            switch self {
                case .id:
                    return .id
                case .name:
                    return .name
                case .date:
                    return .date
                case .action:
                    return .action
            }
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let favorite = favorites[row]

        guard let columnIdentifier = tableColumn?.identifier, let tableColumnType = ColumnIdentifier(rawValue: columnIdentifier.rawValue) else {
            return nil
        }

        var text: String = ""

        switch tableColumnType {
            case .id:
                text = favorite.id
            case .name:
                text = favorite.name
            case .date:
                text = Self.dateFormatter.string(for: favorite.date) ?? ""
            default:
                break
        }

        let cellType = tableColumnType.cellIdentifier
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: cellType.rawValue)

        guard let tableCellView = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        switch cellType {
            case .action:
                let removeFavoriteCell = tableCellView as? RemoveFavoriteTableCellView
                removeFavoriteCell?.delegate = self
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
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }
}

// MARK: - NSTableViewDataSource

extension FavoritesViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        favorites.count
    }

}

// MARK: - RemoveFavoriteDelegate

extension FavoritesViewController: RemoveFavoriteCellDelegate {

    func removeFavoriteCellTapped(_ removeFavoriteCell: RemoveFavoriteTableCellView) {
        let row = tableView.row(for: removeFavoriteCell)
        let favorite = favorites[row]

        let alert = NSAlert()
        alert.messageText = "Remove \"\(favorite.name)\" as a favorite?"
        alert.informativeText = "You can always add this volume back to your favorites later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")

        let result = alert.runModal()

        guard result == .alertFirstButtonReturn else {
            return
        }

        if let index = favorites.firstIndex(where: { favorite.id == $0.id }) {
            favorites.remove(at: index)
        }
    }

}

