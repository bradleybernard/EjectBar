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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        volumes = Volume.queryVolumes()
        setupNotificationListeners()
        VolumeListener.instance.registerCallbacks()
    }
    
    func setupNotificationListeners() {
        
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name(rawValue: "diskMounted"), object: nil, queue: nil, using: diskMountedNotification)
        center.addObserver(forName: Notification.Name(rawValue: "diskUnmounted"), object: nil, queue: nil, using: diskUnmountedNotification)
    }
    
    func diskMountedNotification(notification: Notification) {
        print("Mounted")
//        fetchVolumes()

        guard let object = notification.object else {
            return
        }
//
        let volume = object as! Volume
        print(volume)
//        var found = false
//
//        volumes.forEach {
//            if($0.id == disk)
//        }
    }
    
    func diskUnmountedNotification(notification: Notification) {
        print("Unmounted")
//        fetchVolumes()
    }
    
    func fetchVolumes() {
//        volumes = Volume.queryVolumes()
//        DispatchQueue.main.sync {
//            self.tableView.reloadData()
//        }
    }
    
    func displayVolumes(_ volumes: [Volume]) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        volumes.enumerated().forEach {
            view.addSubview(NSTextField(labelWithString: $1.name + " " + formatter.string(fromByteCount: Int64($1.size))))
            $1.unmount(callback: {(success: Bool, error: String?) in
                print(success)
                print(error as Any)
            })
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
        
        let sizeFormatter = ByteCountFormatter()
        let volume = volumes[row]
        
        if tableColumn == tableView.tableColumns[0] {
            text = "True"
            cellIdentifier = CellIdentifiers.SelectedCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = volume.name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = sizeFormatter.string(fromByteCount: Int64(volume.size))
            cellIdentifier = CellIdentifiers.SizeCell
        } else if tableColumn == tableView.tableColumns[3] {
            text = volume.device
            cellIdentifier = CellIdentifiers.PathCell
        }
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
//            cell.imageView?.image = image ?? nil
            return cell
        }
        
        return nil
    }
}

extension HomeVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return volumes.count
    }
}
