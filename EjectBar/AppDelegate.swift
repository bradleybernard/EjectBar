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
    
    private static let settingsFile: String = "Settings"
    private static let folderName: String = "EjectBar"
    private static let settingsFolder: String = "Settings"
    
    private var plist = [String: Any]()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenu()
        setupNotificationListeners()
    }
    
    func setupNotificationListeners() {
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name(rawValue: "postVolumeCount"), object: nil, queue: nil, using: postVolumeCount)
        center.post(name: Notification.Name(rawValue: "updateVolumeCount"), object: nil, userInfo: nil)
    }
    
    func postVolumeCount(notification: Notification) {
        guard
            let info = notification.userInfo,
            let count = info["count"] as? Int
        else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.title = String(count)
        }
    }

    static func loadSettings() -> [String: Any]? {
        guard
            let path = createSettings(),
            let data = NSData(contentsOfFile: path.path)
        else { return nil }
        
        return try? PropertyListSerialization.propertyList(from: data as Data, options: [], format: nil) as? [String: Any]
    }
    
    static func createSettings() -> URL? {
        guard
            let source = Bundle.main.path(forResource: AppDelegate.settingsFile, ofType: "plist"),
            let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        else {
            return nil
        }
        
        var dest = url
        dest.appendPathComponent(AppDelegate.folderName, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFolder, isDirectory: true)
        try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true, attributes: nil)
        
        let name = AppDelegate.settingsFile + ".plist"
        dest.appendPathComponent(name, isDirectory: false)
        try? FileManager.default.copyItem(atPath: source, toPath: dest.path)
        
        return dest
    }
    
    static func writeSettings(_ prefs: [String: Any]) {
        guard let path = AppDelegate.plistURL() else { return }
        
        (prefs as NSDictionary).write(to: path, atomically: true)
    }
    
    static func plistURL() -> URL? {
        guard let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return nil }
        
        var dest = url
        dest.appendPathComponent(AppDelegate.folderName, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFolder, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFile + ".plist", isDirectory: false)
        
        return dest
    }
    
    func setupMenu() {
        guard let button = statusItem.button else { return }
        
        menu.addItem(NSMenuItem(title: "Eject Favorites", action: #selector(AppDelegate.ejectAction(sender:)), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(AppDelegate.showAction(sender:)), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Window", action: #selector(AppDelegate.hideAction(sender:)), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.quitAction(sender:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        button.image = NSImage(named: "EjectIcon")
        button.target = self
        button.action = #selector(self.statusBarButtonClicked(sender:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        if event?.type == .rightMouseUp {
            //
        } else {
            //
        }
    }
    
    @objc func quitAction(sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func hideAction(sender: Any) {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "hideApplication"), object: nil, userInfo: nil)
    }
    
    @objc func showAction(sender: Any) {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "showApplication"), object: nil, userInfo: nil)
    }
    
    @objc func ejectAction(sender: Any) {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "ejectFavorites"), object: nil, userInfo: nil)
    }
    
    func menuClick(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        let center = NotificationCenter.default
        
        if event.type == .rightMouseUp {
            center.post(name: Notification.Name(rawValue: "rightClick"), object: nil, userInfo: nil)
        } else if event.type == .leftMouseUp {
            center.post(name: Notification.Name(rawValue: "leftClick"), object: nil, userInfo: nil)
        }
    }
}

