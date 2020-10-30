//
//  WindowController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

class VolumesWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    private func titleBarButton(title: String) -> NSTitlebarAccessoryViewController {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isSelectable = false

        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .bottom
        accessory.view = textField

        return accessory
    }
    
    @IBAction private func ejectAtion(_ sender: Any) {
        NotificationCenter.default.post(name: .ejectFavorites, object: nil, userInfo: nil)
    }
    
    @IBAction private func hideAction(_ sender: Any) {
        window?.fadeOut()
    }
    
    @IBAction private func quitAction(_ sender: Any) {
        window?.fadeOut() { [weak self] in
            NSApplication.shared.terminate(self)
        }
    }
    
    @IBAction private func favoritesAction(_ sender: Any) {
//        let alert = NSAlert()
//
//        alert.addButton(withTitle: "OK")
//        alert.messageText = "About EjectBar"
//        alert.informativeText = "Copyright © 2020 Bradley Bernard. All rights reserved. https://bradleybernard.com/"
//        alert.runModal()
        let favoritesViewControllerIdentifier = NSStoryboard.SceneIdentifier("FavoritesViewController")
        guard let favoritesViewController = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: favoritesViewControllerIdentifier) as? FavoritesViewController else {
            return
        }

        self.window?.contentViewController = favoritesViewController
    }
    
    @IBAction private func refreshAction(_ sender: Any) {
        NotificationCenter.default.post(name: .resetTableView, object: nil, userInfo: ["background": false])
    }
}
