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
    }
}
