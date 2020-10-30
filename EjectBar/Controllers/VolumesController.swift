//
//  HomeController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa
import Foundation

class VolumesController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!

    private var volumes = [Volume]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    private var favorites = Set<Favorite>() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }

    private enum ColumnIdentifier: String {
        case favorite = "VolumFavoriteColumn"
        case name = "VolumeNameColumn"
        case path = "VolumePathColumn"
        case size = "VolumeSizeColumn"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        volumes = Volume.queryVolumes()
        VolumeListener.shared.registerCallbacks()

        tableView.sortDescriptors = [
//            NSSortDescriptor(keyPath: KeyPath<Volume, , ascending: <#T##Bool#>, comparator: <#T##Comparator##Comparator##(Any, Any) -> ComparisonResult#>)
//            NSSortDescriptor(keyPath: \Volume.name, ascending: true),
//            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
//            NSSortDescriptor(key: "path", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
//            NSSortDescriptor(key: "size", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        
//        tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ColumnIdentifier.name.rawValue))?.sortDescriptorPrototype = NSSortDescriptor(keyPath: \Volume.size, ascending: true)

//        tableView.sortD
        
        setupNotificationListeners()
        readSelected()
    }
    
    private func readSelected() {
        AppDelegate.backgroundQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.favorites = AppDelegate.loadFavorites()
        }
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .diskMounted, object: nil, queue: nil, using: diskMounted)
        NotificationCenter.default.addObserver(forName: .diskUnmounted, object: nil, queue: nil, using: diskUnmounted)
        NotificationCenter.default.addObserver(forName: .ejectFavorites, object: nil, queue: nil, using: ejectFavorites)
        NotificationCenter.default.addObserver(forName: .updateVolumeCount, object: nil, queue: nil, using: updateVolumeCount)
        NotificationCenter.default.addObserver(forName: .resetTableView, object: nil, queue: nil, using: resetTableView)
    }
    
    private func resetTableView(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.volumes = Volume.queryVolumes()
            self.postVolumeCount()
        }
    }
    
    private func updateVolumeCount(notification: Notification) {
        postVolumeCount()
    }
    
    private func ejectFavorites(notification: Notification) {
        let favoritesNames = favorites.map(\.id)

        volumes.forEach { volume in
            if favoritesNames.contains(volume.id) {
                volume.unmount(callback: { status, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = volume.name + " " + error.localizedDescription
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "OK")
                            alert.runModal()
                        }
                    }
                })
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.postVolumeCount()
        }
    }
    
    private func volumeExists(volume: Volume) -> Bool {
        volumes.first { $0.id == volume.id } != nil
    }
    
    private func postVolumeCount() {
        NotificationCenter.default.post(name: .postVolumeCount, object: nil, userInfo: ["count": volumes.count])
    }
    
    private func diskUnmounted(notification: Notification) {
        guard let object = notification.object, let volume = object as? Volume else {
            return
        }
        
        volumes = volumes.filter { $0.id != volume.id }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.postVolumeCount()
        }
    }
    
    @objc private func checkboxSelected(sender: NSButton) {
        sender.isEnabled = false

        defer {
            sender.isEnabled = true
        }

        let row = tableView.row(for: sender)
        let volume = volumes[row]
        
        if sender.state == .on {
            favorites.insert(Favorite(id: volume.id, name: volume.name, date: Date()))
        } else {
            if let volumeFavorite = favorites.first(where: { volume.id == $0.id }) {
                favorites.remove(volumeFavorite)
            }
        }

        AppDelegate.backgroundQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    AppDelegate.backgroundQueue.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        
                        appDelegate.saveFavorites(self.favorites)
                    }
                }
            }
        }
    }
    
    private func checkboxState(_ volume: Volume) -> NSCell.StateValue {
        return favorites.map(\.id).contains(volume.id) ? .on : .off
    }
}

extension VolumesController: NSTableViewDelegate {

    private static let sizeFormatter = ByteCountFormatter()
    
    private enum CellIdentifier: String {
        case pathCell = "VolumePathCell"
        case nameCell = "VolumeNameCell"
        case favoriteCell = "VolumeFavoriteCell"
        case sizeCell = "VolumeSizeCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        let cellIdentifier: CellIdentifier

        let volume = volumes[row]
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = .favoriteCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = volume.name
            cellIdentifier = .nameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = volume.device
            cellIdentifier = .pathCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = Self.sizeFormatter.string(fromByteCount: Int64(volume.size))
            cellIdentifier = .sizeCell
        } else {
            fatalError("Unknown tableView column \(String(describing: tableColumn))")
        }

        let identifier = NSUserInterfaceItemIdentifier(rawValue: cellIdentifier.rawValue)

        guard let tableCellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView else {
            return nil
        }

        switch cellIdentifier {
            case .favoriteCell:
                let selectedTableCell = tableCellView as? SelectedTableCell
                selectedTableCell?.saveCheckbox.state = checkboxState(volume)
                selectedTableCell?.saveCheckbox.action = #selector(VolumesController.checkboxSelected)
            default:
                tableCellView.textField?.stringValue = text
        }

        return tableCellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        false
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
//        (volumes as NSArray).sortedArray(using: tableView.sortDescriptors)
//        tableView.reloadData()
    }
}

extension VolumesController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        volumes.count
    }
    
}
