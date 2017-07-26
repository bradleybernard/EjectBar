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
    
    static func loadSettings() -> [String: Any]? {
        
        guard
            let path = createSettings(),
            let data = NSData(contentsOfFile: path.path)
        else { return nil }
        
        guard
            let wrapped = try? PropertyListSerialization.propertyList(from: data as Data, options: [], format: nil) as? [String: Any],
            let dict = wrapped
        else { return nil }
        
        return dict
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
        
        do {
            if #available(OSX 10.13, *) {
                try (prefs as NSDictionary).write(to: path)
            } else {
                (prefs as NSDictionary).write(to: path, atomically: true)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func plistURL() -> URL? {
        guard let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return nil }
        
        var dest = url
        dest.appendPathComponent(AppDelegate.folderName, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFolder, isDirectory: true)
        dest.appendPathComponent(AppDelegate.settingsFile + ".plist", isDirectory: false)
        
        return dest
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        guard let settings = AppDelegate.loadSettings() else { return }
//        plist = settings
    }

    func applicationWillTerminate(_ aNotification: Notification) {
//        AppDelegate.writeSettings(plist)
    }
}

