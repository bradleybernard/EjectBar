//
//  AppDelegate.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private enum Path: String {
        case settings = "Settings"
        case app = "EjectBar"
        case fileEnding = "."
        case plist = "plist"
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    static let backgroundQueue = DispatchQueue(label: "Background")
    var favorites = Set<Favorite>()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Self.backgroundQueue.async { [weak self] in
            self?.favorites = Self.loadFavorites()
        }

        setupMenu()
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(forName: .postVolumeCount, object: nil, queue: nil, using: postVolumeCount)
        NotificationCenter.default.post(name: .updateVolumeCount, object: nil, userInfo: nil)
    }
    
    private func postVolumeCount(notification: Notification) {
        guard let info = notification.userInfo, let count = info["count"] as? Int else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.title = String(count)
        }
    }
    
    private static var settingsURL: URL? {
        guard let source = Bundle.main.path(forResource: Path.settings.rawValue, ofType: Path.plist.rawValue),
              let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        
        var settingsURL = url
        settingsURL.appendPathComponent(Path.app.rawValue, isDirectory: true)
        settingsURL.appendPathComponent(Path.settings.rawValue, isDirectory: true)
        try? FileManager.default.createDirectory(at: settingsURL, withIntermediateDirectories: true, attributes: nil)
        
        let name = Path.settings.rawValue + Path.fileEnding.rawValue + Path.plist.rawValue
        settingsURL.appendPathComponent(name, isDirectory: false)
        try? FileManager.default.copyItem(atPath: source, toPath: settingsURL.path)
        
        return settingsURL
    }

    static func loadFavorites() -> Set<Favorite> {
        guard let settingsURL = settingsURL, let data = try? Data(contentsOf: settingsURL) else {
            return .init()
        }

        let value: Set<Favorite> = {
            do {
                return try PropertyListDecoder().decode(Set<Favorite>.self, from: data)
            } catch {
                return .init()
            }
        }()

        return value
    }
    
    func saveFavorites(_ favorites: Set<Favorite>) {
        guard let settingsURL = AppDelegate.settingsURL else {
            return
        }

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        let data = try? encoder.encode(favorites)
        try? data?.write(to: settingsURL)

        self.favorites = favorites
        NotificationCenter.default.post(name: .favoritesUpdated, object: nil, userInfo: ["favorites": favorites])
    }
    
    static var plistURL: URL? {
        guard let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        
        var plistURL = url
        plistURL.appendPathComponent(Path.app.rawValue, isDirectory: true)
        plistURL.appendPathComponent(Path.settings.rawValue, isDirectory: true)
        plistURL.appendPathComponent(Path.settings.rawValue + Path.fileEnding.rawValue + Path.plist.rawValue, isDirectory: false)
        
        return plistURL
    }
    
    private func setupMenu() {
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(named: "EjectIcon")

        menu.addItem(NSMenuItem(title: "Eject Favorites", action: #selector(AppDelegate.ejectFavorites(sender:)), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show Volumes Window", action: #selector(AppDelegate.showVolumesWindow(sender:)), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Hide Volumes Window", action: #selector(AppDelegate.hideVolumesWindow(sender:)), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show Favorites Window", action: #selector(AppDelegate.showFavoritesWindow(sender:)), keyEquivalent: "f"))
        menu.addItem(NSMenuItem(title: "Hide Favorites Window", action: #selector(AppDelegate.hideFavoritesWindow(sender:)), keyEquivalent: "g"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quitAction(sender:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func quitAction(sender: Any) {
        NSApplication.shared.terminate(self)
    }

    @objc private func showVolumesWindow(sender: Any) {
        NotificationCenter.default.post(name: .showVolumesWindow, object: nil, userInfo: nil)
    }
    
    @objc private func hideVolumesWindow(sender: Any) {
        NotificationCenter.default.post(name: .hideVolumesWindow, object: nil, userInfo: nil)
    }

    @objc private func showFavoritesWindow(sender: Any) {
        NotificationCenter.default.post(name: .showFavoritesWindow, object: nil, userInfo: nil)
    }

    @objc private func hideFavoritesWindow(sender: Any) {
        NotificationCenter.default.post(name: .hideFavoritesWindow, object: nil, userInfo: nil)
    }
    
    @objc private func ejectFavorites(sender: Any) {
        NotificationCenter.default.post(name: .ejectFavorites, object: nil, userInfo: nil)
    }
}

