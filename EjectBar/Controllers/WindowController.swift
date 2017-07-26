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
        
        window.addTitlebarAccessoryViewController(titleBarButton(title: "Quit", selector: #selector(WindowController.quit)))
        window.addTitlebarAccessoryViewController(titleBarButton(title: "Hide", selector: #selector(WindowController.hide)))
        window.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
    }
    
    @objc func titleBarButton(title: String, selector: Selector) -> NSTitlebarAccessoryViewController {
        let button = NSButton(title: title, target: nil, action: selector)
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .right
        accessory.view = button
        return accessory
    }
    
    @objc func hide() {
        window?.orderOut(self)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
