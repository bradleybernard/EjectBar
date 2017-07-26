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
    
    static let settingsFile: String = "Settings"
    static let folderName: String = "EjectBar"
    static let settingsFolder: String = "Settings"
    
    var plist = [String: Any]()
    
    func loadSettings() {
        
        guard
            let path = createSettings(),
            let data = NSData(contentsOfFile: path.path)
        else { return }
        
        guard
            let wrapped = try? PropertyListSerialization.propertyList(from: data as Data, options: [], format: nil) as? [String: Any],
            let dict = wrapped
        else { return }
        
        plist = dict
    }
    
    func createSettings() -> URL? {
        
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
    
    func writeSettings() {
        guard let path = plistURL() else { return }
        
        let data = NSKeyedArchiver.archivedData(withRootObject: plist)
        try? data.write(to: path)
    }
    
    func plistURL() -> URL? {
        guard let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return nil }
        
        var dest = url
        dest.appendPathComponent(AppDelegate.folderName, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFolder, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFile + ".plist", isDirectory: false)
        
        return dest
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadSettings()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        writeSettings()
    }
}

