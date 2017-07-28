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
        
        guard let window = window else { return }
        window.title = "Mounted Volumes"
        window.styleMask.remove(NSWindowStyleMask.closable)
        window.styleMask.remove(NSWindowStyleMask.miniaturizable)
    }
    
    func titleBarButton(title: String) -> NSTitlebarAccessoryViewController {
        let button = NSTextField(labelWithString: title)
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .bottom
        accessory.view = button
        return accessory
    }
    
    func hide() {
        window?.orderOut(self)
    }
    
    func quit() {
        NSApplication.shared().terminate(nil)
    }
}
