//
//  HomeVC.swift
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
    var selected = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        volumes = Volume.queryVolumes()
        VolumeListener.instance.registerCallbacks()
        
        setupNotificationListeners()
        readSelected()
    }
    
    func readSelected() {
        
//        guard
//            let selectedSaved = SwiftyPlistManager.shared.fetchValue(for: "Selected", fromPlistWithName: "Settings"),
//            let saved = selectedSaved as? Array<String>
//        else { return }
    
        
//        selected = Set(saved)
        tableView.reloadData()
    }
    
    func setupNotificationListeners() {
        
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name(rawValue: "diskMounted"), object: nil, queue: nil, using: diskMountedNotification)
        center.addObserver(forName: Notification.Name(rawValue: "diskUnmounted"), object: nil, queue: nil, using: diskUnmountedNotification)
    }
    
    func diskMountedNotification(notification: Notification) {
        
        guard
            let object = notification.object,
            let volume = object as? Volume
        else { return }
        
        if(volumeExists(volume: volume)) {
            return
        }
        
        volumes.append(volume)
        DispatchQueue.main.sync {
            self.tableView.reloadData()
        }
    }
    
    func volumeExists(volume: Volume) -> Bool {
        return volumes.reduce(0) { $0 + ($1.id == volume.id ? 1 : 0) } == 1
    }
    
    func diskUnmountedNotification(notification: Notification) {
        
        guard
            let object = notification.object,
            let volume = object as? Volume
        else { return }
        
        volumes = volumes.filter { $0.id != volume.id }
        DispatchQueue.main.sync {
            self.tableView.reloadData()
        }
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
                selected.saveCheckbox.tag = row
            }
            return cell
        }
        
        return nil
    }
    
    func checkboxSelected(sender: NSButton) {
        let volume = volumes[sender.tag]
        
        sender.isEnabled = false
        if sender.state == NSOnState {
            selected.insert(volume.name)
        } else if sender.state == NSOffState {
            selected.remove(volume.name)
        }
        
//        SwiftyPlistManager.shared.save(Array(selected), forKey: "Selected", toPlistWithName: "Settings") { (err) in
//            DispatchQueue.main.sync {
//                sender.isEnabled = true
//            }
//        }
    }
    
    func checkboxState(_ volume: Volume) -> NSControl.StateValue {
        return (selected.contains(volume.name) ? NSOnState : NSOffState)
    }
}

extension HomeVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return volumes.count
    }
}
