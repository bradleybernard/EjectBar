//
//  WindowController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.title = "Mounted Volumes"
    }
    
    func titleBarButton(title: String) -> NSTitlebarAccessoryViewController {
        let button = NSTextField(labelWithString: title)
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .bottom
        accessory.view = button

        return accessory
    }
    
    @IBAction func ejectAtion(_ sender: Any) {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "ejectFavorites"), object: nil, userInfo: nil)
    }
    
    @IBAction func hideAction(_ sender: Any) {
        window?.orderOut(self)
    }
    
    @IBAction func quitAction(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func aboutAction(_ sender: Any) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "About EjectBar"
        alert.informativeText = "Copyright © 2017 Bradley Bernard. All rights reserved. https://bradleybernard.com/"
        alert.runModal()
    }
    
    @IBAction func refreshAction(_ sender: Any) {
         let center = NotificationCenter.default
         center.post(name: Notification.Name(rawValue: "resetTableView"), object: nil, userInfo: ["background": false])
    }
}
