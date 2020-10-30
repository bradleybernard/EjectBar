//
//  VolumesWindowController.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

class VolumesWindowController: NSWindowController {

    private var favoritesWindowController: FavoritesWindowController?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupNotificationListeners()
    }

    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .showVolumesWindow, object: nil, queue: nil, using: showVolumesWindow(notification:))
        NotificationCenter.default.addObserver(forName: .hideVolumesWindow, object: nil, queue: nil, using: hideVolumesWindow(notification:))

        NotificationCenter.default.addObserver(forName: .showFavoritesWindow, object: nil, queue: nil, using: showFavoritesWindow(notification:))
        NotificationCenter.default.addObserver(forName: .hideFavoritesWindow, object: nil, queue: nil, using: hideFavoritesWindow(notification:))
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
        createFavoritesWindow(show: true)
    }
    
    @IBAction private func refreshAction(_ sender: Any) {
        NotificationCenter.default.post(name: .resetTableView, object: nil, userInfo: nil)
    }

    private func showFavoritesWindow(notification: Notification) {
        createFavoritesWindow(show: true)
    }

    private func hideFavoritesWindow(notification: Notification) {
        favoritesWindowController?.window?.fadeOut()
    }

    private func showVolumesWindow(notification: Notification) {
        window?.fadeIn()
    }

    private func hideVolumesWindow(notification: Notification) {
        window?.fadeOut()
    }

    private func createFavoritesWindow(show: Bool) {
        defer {
            if show {
                favoritesWindowController?.window?.fadeIn()
            }
        }

        guard favoritesWindowController == nil else {
            return
        }

        favoritesWindowController = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: FavoritesWindowController.sceneIdentifier) as? FavoritesWindowController
    }
}
