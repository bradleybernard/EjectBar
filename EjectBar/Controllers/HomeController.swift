//
//  HomeController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa
import Foundation

class HomeVC: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    var volumes = [Volume]()
    
    var plist = [String: Any]()
    var selected = Set<String>()
    var visible = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.autoresizingMask = .viewWidthSizable
        tableView.sizeToFit()
        
        volumes = Volume.queryVolumes()
        VolumeListener.instance.registerCallbacks()
        
        setupNotificationListeners()
        readSelected()
    }
    
    func readSelected() {
        
        guard
            let prefs = AppDelegate.loadSettings(),
            let saved = prefs["Selected"] as? Array<String>
        else { return }
        
        plist = prefs
        selected = Set(saved)
        
        tableView.reloadData()
    }
    
    func setupNotificationListeners() {
        
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name(rawValue: "diskMounted"), object: nil, queue: nil, using: diskMounted)
        center.addObserver(forName: Notification.Name(rawValue: "diskUnmounted"), object: nil, queue: nil, using: diskUnmounted)
        center.addObserver(forName: Notification.Name(rawValue: "ejectFavorites"), object: nil, queue: nil, using: ejectFavorites)
        center.addObserver(forName: Notification.Name(rawValue: "showApplication"), object: nil, queue: nil, using: showApplication)
        center.addObserver(forName: Notification.Name(rawValue: "hideApplication"), object: nil, queue: nil, using: hideApplication)
        center.addObserver(forName: Notification.Name(rawValue: "updateVolumeCount"), object: nil, queue: nil, using: updateVolumeCount)
        center.addObserver(forName: Notification.Name(rawValue: "resetTableView"), object: nil, queue: nil, using: resetTableView)
        
    }
    
    func resetTableView(notification: Notification) {
        DispatchQueue.main.sync {
            volumes = Volume.queryVolumes()
            postVolumeCount()
            self.tableView.reloadData()
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
                        let alert = NSAlert(error: NSError(domain: error, code: 100, userInfo: nil))
                        DispatchQueue.main.async {
                            // Silence unused response
                            _ = alert.runModal()
                        }
                    }
                })
            }
        }
    }
    
    func showApplication(notification: Notification) {
        guard let window = view.window else { return }
        
        window.makeKeyAndOrderFront(self)
        NSRunningApplication.current().activate(options: .activateIgnoringOtherApps)
    }
    
    func hideApplication(notification: Notification) {
        view.window?.orderOut(self)
    }
    
    func diskMounted(notification: Notification) {
        
        guard
            let object = notification.object,
            let volume = object as? Volume
        else { return }
        
        if(volumeExists(volume: volume)) {
            return
        }
        
        volumes.append(volume)
        
        DispatchQueue.main.sync {
            postVolumeCount()
            self.tableView.reloadData()
        }
    }
    
    func volumeExists(volume: Volume) -> Bool {
        return volumes.reduce(0) { $0 + ($1.id == volume.id ? 1 : 0) } == 1
    }
    
    func postVolumeCount() {
        let center = NotificationCenter.default
        center.post(name:Notification.Name(rawValue: "postVolumeCount"), object: nil, userInfo: ["count": volumes.count])
    }
    
    func diskUnmounted(notification: Notification) {
        
        guard
            let object = notification.object,
            let volume = object as? Volume
        else { return }
        
        volumes = volumes.filter { $0.id != volume.id }
        
        DispatchQueue.main.sync {
            postVolumeCount()
            self.tableView.reloadData()
        }
    }
    
    func checkboxSelected(sender: NSButton) {
        
        let row = self.tableView.row(for: sender)
        let volume = volumes[row]
        
        sender.isEnabled = false
        
        if sender.state == NSOnState {
            selected.insert(volume.name)
        } else if sender.state == NSOffState {
            selected.remove(volume.name)
        }
        
        plist["Selected"] = Array(selected)
        AppDelegate.writeSettings(plist)
        
        sender.isEnabled = true
    }
    
    func checkboxState(_ volume: Volume) -> NSCellStateValue {
        return (selected.contains(volume.name) ? NSOnState : NSOffState)
    }
}

extension HomeVC: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let PathCell = "PathCellID"
        static let NameCell = "NameCellID"
        static let SelectedCell = "SelectedCellID"
        static let SizeCell = "SizeCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text: String = ""
        var cellIdentifier: String = ""
        var custom = false
        
        let sizeFormatter = ByteCountFormatter()
        let volume = volumes[row]
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.SelectedCell
            custom = true
        } else if tableColumn == tableView.tableColumns[1] {
            text = volume.name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = volume.device
            cellIdentifier = CellIdentifiers.PathCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = sizeFormatter.string(fromByteCount: Int64(volume.size))
            cellIdentifier = CellIdentifiers.SizeCell
        }
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            if(!custom) {
                cell.textField?.stringValue = text
            } else {
                let selected = (cell as! SelectedTableCell)
                selected.saveCheckbox.state = checkboxState(volume)
                selected.saveCheckbox.action = #selector(HomeVC.checkboxSelected)
            }
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

extension HomeVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return volumes.count
    }
}
