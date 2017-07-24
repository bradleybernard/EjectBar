//
//  Volume.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Foundation

typealias VolumeID = (NSCopying & NSSecureCoding & NSObjectProtocol)
typealias DiskCallback = (Bool, String?) -> Void

enum VolumeComponent: Int {
    case root = 1
}

struct Volume {
    
    var id: VolumeID
    var name: String
    var device: String
    var disk: DADisk
    var size: Int
    var ejectable: Bool
    var removable: Bool
    
    static let keys: [URLResourceKey] = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    static let set: Set<URLResourceKey> = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    
    init(id: VolumeID, name: String, device: String, disk: DADisk, size: Int, ejectable: Bool, removable: Bool) {
        self.id = id
        self.name = name
        self.device = device
        self.disk = disk
        self.size = size
        self.ejectable = ejectable
        self.removable = removable
    }
    
    func unmount(callback: @escaping DiskCallback) {
        DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionDefault), { (volume, dissenter, context) in
            
            let pointer = context?.load(as: DiskCallback.self)
            
            guard let function = pointer else {
                return
            }
            
            if let error = dissenter {
                function(false, String(describing: DADissenterGetStatusString(error)))
            } else {
                function(true, nil)
            }
            
        }, nil)
    }
    
    static func fromURL(_ url: URL) -> Volume? {
        
        guard
            let resources = try? url.resourceValues(forKeys: set),
            let id = resources.volumeIdentifier,
            let name = resources.volumeLocalizedName,
            let size = resources.volumeTotalCapacity,
            let ejectable = resources.volumeIsEjectable,
            let removable = resources.volumeIsRemovable,
            let session = DASessionCreate(kCFAllocatorDefault),
            let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL),
            let bsdName = DADiskGetBSDName(disk)
        else { print("WOW")
            return nil }
        
        let device = String(cString: bsdName)
        
        return Volume(id: id, name: name, device: device, disk: disk, size: size, ejectable: ejectable, removable: removable)
    }
    
    static func isVolumeURL(_ url: URL) -> Bool {
        return (url.pathComponents.count > 1 && url.pathComponents[VolumeComponent.root.rawValue] == "Volumes")
    }
    
    static func queryVolumes() -> [Volume] {
        
        let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])
        
        guard let urls = paths else {
            return []
        }
        
        return urls.filter { Volume.isVolumeURL($0) }.flatMap { Volume.fromURL($0) }
    }
}
