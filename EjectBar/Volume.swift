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

//class CallbackWrapper {
//    var callback : DiskCallback
//    
//    init(callback: DiskCallback) {
//        self.callback = callback
//    }
//}

struct Volume {
    
    var id: VolumeID
    var name: String
    var device: String
    var disk: DADisk
    var session: DASession
    var size: Int
    var ejectable: Bool
    var removable: Bool
    
    static let keys: [URLResourceKey] = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    static let set: Set<URLResourceKey> = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    
    init(id: VolumeID, name: String, device: String, disk: DADisk, session: DASession, size: Int, ejectable: Bool, removable: Bool) {
        self.id = id
        self.name = name
        self.device = device
        self.disk = disk
        self.session = session
        self.size = size
        self.ejectable = ejectable
        self.removable = removable
    }
    
    func unmount(callback: inout DiskCallback) {

        withUnsafeMutablePointer(to: &callback, { reference in
            DADiskUnmount(disk, DADiskUnmountOptions(kDADiskMountOptionWhole & kDADiskUnmountOptionForce), { (volume: DADisk, dissenter : DADissenter?, context : UnsafeMutableRawPointer?) in
                
                let pointer = unsafeBitCast(context, to: DiskCallback)
                
                guard let function = pointer else {
                    return
                }
                
                if let error = dissenter {
                    function(false, String(describing: DADissenterGetStatusString(error)))
                } else {
                    function(true, nil)
                }
                
            }, reference)
        })
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
        else { return nil }
        
        let device = String(cString: bsdName)
        DASessionSetDispatchQueue(session, DispatchQueue.global())
        
        return Volume(id: id, name: name, device: device, disk: disk, session: session, size: size, ejectable: ejectable, removable: removable)
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
