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
    private var volumes = [Volume]()
    
    private var plist = [String: Any]()
    private var selected = Set<String>()
    private var visible = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.autoresizingMask = .width
        tableView.sizeToFit()
        
        volumes = Volume.queryVolumes()
        VolumeListener.shared.registerCallbacks()
        
        setupNotificationListeners()
        readSelected()
    }
    
    func readSelected() {
        guard let prefs = AppDelegate.loadSettings(), let saved = prefs["Selected"] as? [String] else {
            return
        }
        
        plist = prefs
        selected = Set(saved)
        
        tableView.reloadData()
    }
    
    func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .diskMounted, object: nil, queue: nil, using: diskMounted)
        NotificationCenter.default.addObserver(forName: .diskUnmounted, object: nil, queue: nil, using: diskUnmounted)
        NotificationCenter.default.addObserver(forName: .ejectFavorites, object: nil, queue: nil, using: ejectFavorites)
        NotificationCenter.default.addObserver(forName: .showApplication, object: nil, queue: nil, using: showApplication)
        NotificationCenter.default.addObserver(forName: .hideApplication, object: nil, queue: nil, using: hideApplication)
        NotificationCenter.default.addObserver(forName: .updateVolumeCount, object: nil, queue: nil, using: updateVolumeCount)
        NotificationCenter.default.addObserver(forName: .resetTableView, object: nil, queue: nil, using: resetTableView)
    }
    
    func resetTableView(notification: Notification) {
        guard let dict = notification.userInfo, let background = dict["background"] as? Bool else {
            return
        }

        let block = { [weak self] in
            guard let self = self else {
                return
            }

            self.volumes = Volume.queryVolumes()
            self.postVolumeCount()
            self.tableView.reloadData()
        }
        
        if background {
            DispatchQueue.main.async {
                block()
            }
        } else {
            block()
        }
    }
    
    func updateVolumeCount(notification: Notification) {
        postVolumeCount()
    }
    
    func ejectFavorites(notification: Notification) {
        volumes.forEach { (volume) in
            if selected.contains(volume.name) {
                volume.unmount(callback: { (status, error) in
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
    
    func showApplication(notification: Notification) {
        view.window?.fadeIn()
    }
    
    func hideApplication(notification: Notification) {
        view.window?.fadeOut()
    }
    
    func diskMounted(notification: Notification) {
        guard let object = notification.object, let volume = object as? Volume, !volumeExists(volume: volume) else {
            return
        }
        
        volumes.append(volume)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.postVolumeCount()
            self.tableView.reloadData()
        }
    }
    
    func volumeExists(volume: Volume) -> Bool {
        volumes.reduce(0) { $0 + ($1.id == volume.id ? 1 : 0) } == 1
    }
    
    func postVolumeCount() {
        NotificationCenter.default.post(name: .postVolumeCount, object: nil, userInfo: ["count": volumes.count])
    }
    
    func diskUnmounted(notification: Notification) {
        guard let object = notification.object, let volume = object as? Volume else {
            return
        }
        
        volumes = volumes.filter { $0.id != volume.id }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.postVolumeCount()
            self.tableView.reloadData()
        }
    }
    
    @objc func checkboxSelected(sender: NSButton) {
        sender.isEnabled = false

        defer {
            sender.isEnabled = true
        }

        let row = tableView.row(for: sender)
        let volume = volumes[row]
        
        if sender.state == .on {
            selected.insert(volume.name)
        } else {
            selected.remove(volume.name)
        }
        
        plist["Selected"] = Array(selected)
        AppDelegate.writeSettings(plist)
    }
    
    func checkboxState(_ volume: Volume) -> NSCell.StateValue {
        selected.contains(volume.name) ? .on : .off
    }
}

extension VolumesController: NSTableViewDelegate {

    private static let sizeFormatter = ByteCountFormatter()
    
    private enum CellIdentifier: String {
        case pathCell = "PathCellID"
        case nameCell = "NameCellID"
        case selectedCell = "SelectedCellID"
        case sizeCell = "SizeCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        let cellIdentifier: CellIdentifier

        let volume = volumes[row]
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = .selectedCell
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
            case .selectedCell:
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
}

extension VolumesController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        volumes.count
    }
    
}
