//
//  VolumesController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa
import Foundation

class VolumesController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!

    private var volumes = [Volume]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableViewDataUpdated()
            }
        }
    }

    private var favorites = Set<Favorite>() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableViewDataUpdated()
            }
        }
    }

    private var favoriteVolumes: [Volume] {
        let favoriteVolumeIds = favorites.map(\.id)
        return volumes.filter { volume in
            favoriteVolumeIds.contains(volume.id)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        volumes = Volume.queryVolumes()
        VolumeListener.shared.registerCallbacks()

        setupNotificationListeners()
        readFavorites()
    }

    private func tableViewDataUpdated() {
        tableView.reloadData()
        tableView.resizeColumns()
        view.window?.resizeToFitTableView(tableView: self.tableView)
        postVolumeCount()
    }
    
    private func readFavorites() {
        AppDelegate.backgroundQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.favorites = AppDelegate.loadFavorites()
        }
    }

    // MARK: - Notifications
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .diskMounted, object: nil, queue: nil, using: diskMounted)
        NotificationCenter.default.addObserver(forName: .diskUnmounted, object: nil, queue: nil, using: diskUnmounted)
        NotificationCenter.default.addObserver(forName: .ejectFavorites, object: nil, queue: nil, using: ejectFavorites)
        NotificationCenter.default.addObserver(forName: .resetTableView, object: nil, queue: nil, using: resetTableView)
        NotificationCenter.default.addObserver(forName: .favoritesUpdated, object: nil, queue: nil, using: favoritesUpdated)
    }
    
    private func resetTableView(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.volumes = Volume.queryVolumes()
        }
    }

    private func favoritesUpdated(notification: Notification) {
        guard let userInfo = notification.userInfo, let updatedFavorites = userInfo["favorites"] as? Set<Favorite> else {
            return
        }

        favorites = updatedFavorites
    }
    
    private func ejectFavorites(notification: Notification) {
        let favoriteVolumeIds = favorites.map(\.id)
        let favoriteVolumes = volumes.filter { volume in
            favoriteVolumeIds.contains(volume.id)
        }

        favoriteVolumes.forEach { favoriteVolume in
            favoriteVolume.unmount() { status, error in
                if let error = error {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = favoriteVolume.name + " " + error.localizedDescription
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    private func showApplication(notification: Notification) {
        view.window?.fadeIn()
    }
    
    private func hideApplication(notification: Notification) {
        view.window?.fadeOut()
    }
    
    private func diskMounted(notification: Notification) {
        guard let object = notification.object, let volume = object as? Volume, !volumeExists(volume: volume) else {
            return
        }
        
        volumes.append(volume)
    }
    
    private func volumeExists(volume: Volume) -> Bool {
        volumes.first { $0.id == volume.id } != nil
    }
    
    private func postVolumeCount() {
        let favoriteVolumeIds = favorites.map(\.id)
        let favoriteVolumes = volumes.filter { volume in
            favoriteVolumeIds.contains(volume.id)
        }

        NotificationCenter.default.post(name: .postVolumeCount, object: nil, userInfo: ["count": favoriteVolumes.count])
    }
    
    private func diskUnmounted(notification: Notification) {
        guard let object = notification.object, let volume = object as? Volume else {
            return
        }
        
        volumes = volumes.filter { $0.id != volume.id }
    }
}

// MARK: - NSTableViewDelegate

extension VolumesController: NSTableViewDelegate {

    private static let sizeFormatter = ByteCountFormatter()
    
    private enum CellIdentifier: String {
        case favorite = "VolumeFavoriteCell"
        case name = "VolumeNameCell"
        case model = "VolumeModelCell"
        case size = "VolumeSizeCell"
        case `protocol` = "VolumeProtocolCell"
        case device = "VolumeDeviceCell"
        case disk = "VolumeDiskCell"
        case path = "VolumePathCell"
    }

    private enum ColumnIdentifier: String {
        case favorite = "VolumeFavoriteColumn"
        case name = "VolumeNameColumn"
        case model = "VolumeModelColumn"
        case size = "VolumeSizeColumn"
        case `protocol` = "VolumeProtocolColumn"
        case device = "VolumeDeviceColumn"
        case disk = "VolumeDiskColumn"
        case path = "VolumePathColumn"

        var cellIdentifier: CellIdentifier {
            switch self {
                case .favorite:
                    return .favorite
                case .name:
                    return .name
                case .size:
                    return .size
                case .model:
                    return .model
                case .disk:
                    return .disk
                case .path:
                    return .path
                case .device:
                    return .device
                case .protocol:
                    return .protocol
            }
        }
    }

    private func checkboxState(_ volume: Volume) -> NSCell.StateValue {
        return favorites.map(\.id).contains(volume.id) ? .on : .off
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let volume = volumes[row]

        guard let columnIdentifier = tableColumn?.identifier, let tableColumnType = ColumnIdentifier(rawValue: columnIdentifier.rawValue) else {
            return nil
        }

        var text: String = ""

        switch tableColumnType {
            case .name:
                text = volume.name
            case .model:
                text = volume.model
            case .size:
                text = Self.sizeFormatter.string(fromByteCount: Int64(volume.size))
            case .protocol:
                text = volume.protocol
            case .device:
                text = volume.device
            case .disk:
                text = volume.device
            case .path:
                text = volume.path
            default:
                break
        }

        let cellType = tableColumnType.cellIdentifier
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: cellType.rawValue)

        guard let tableCellView = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        switch cellType {
            case .favorite:
                let favoriteToggleCell = tableCellView as? FavoriteToggleCellView
                favoriteToggleCell?.buttonCell.state = checkboxState(volume)
                favoriteToggleCell?.delegate = self
            default:
                tableCellView.textField?.stringValue = text
        }

        return tableCellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let volumesSorted = (volumes as NSArray).sortedArray(using: tableView.sortDescriptors) as? [Volume] else {
            return
        }

        volumes = volumesSorted
    }
}

// MARK: - NSTableViewDataSource

extension VolumesController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        volumes.count
    }
    
}

// MARK: - FavoriteToggleCellDelegate

extension VolumesController: FavoriteToggleCellDelegate {

    func favoriteToggleCellClicked(_ favoriteToggleCell: FavoriteToggleCellView) {
        guard let checkbox = favoriteToggleCell.buttonCell else {
            return
        }

        checkbox.isEnabled = false

        let row = tableView.row(for: favoriteToggleCell)
        let volume = volumes[row]

        if checkbox.state == .on {
            favorites.insert(Favorite(id: volume.id, name: volume.name, date: Date()))
        } else {
            if let volumeFavorite = favorites.first(where: { volume.id == $0.id }) {
                favorites.remove(volumeFavorite)
            }
        }

        DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                AppDelegate.backgroundQueue.async { [weak self] in
                    guard let self = self else {
                        return
                    }

                    appDelegate.saveFavorites(self.favorites)
                    DispatchQueue.main.async {
                        checkbox.isEnabled = true
                    }
                }
            }
        }
    }

}
