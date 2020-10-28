//
//  Volume.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//
//

import Foundation

typealias UnmountDef = (Bool, NSError?)
typealias UnmountRet = Void
typealias UnmountCallback = (Bool, NSError?) -> Void

typealias MAppDef = (DADisk, UnsafeMutableRawPointer?)
typealias MAppRet = Unmanaged<DADissenter>?
typealias MAppCallback = (DADisk, UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>?

typealias CAppDef = (DADisk, CFArray)
typealias CAppRet = Void
typealias CAppCallback = (DADisk, CFArray) -> Void

enum VolumeComponent: Int {
    case root = 1
}

enum VolumeReservedNames: String {
    case EFI = "EFI"
    case Volumes = "Volumes"
}

class CallbackWrapper<T, U> {
    let callback : (T) -> U
    init(callback: @escaping (T) -> U) {
        self.callback = callback
    }
}

class SessionWrapper {
    static let session: DASession? = DASessionCreate(kCFAllocatorDefault)
}

struct Volume {
    let id: String
    let name: String
    let device: String
    let path: CFURL
    let disk: DADisk
    let size: Int
    let ejectable: Bool
    let removable: Bool

    private static let keys: [URLResourceKey] = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    private static let set: Set<URLResourceKey> = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]

    init(id: String, name: String, device: String, path: CFURL, disk: DADisk, size: Int, ejectable: Bool, removable: Bool) {
        self.id = id
        self.name = name
        self.device = device
        self.path = path
        self.disk = disk
        self.size = size
        self.ejectable = ejectable
        self.removable = removable
    }

    func unmount(callback: @escaping UnmountCallback) {
        let wrapper = CallbackWrapper<UnmountDef, UnmountRet>(callback: callback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())

        DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionWhole & kDADiskUnmountOptionForce), { (volume, dissenter, context) in
            guard let context = context else {
                return
            }

            let wrapped = Unmanaged<CallbackWrapper<UnmountDef, UnmountRet>>.fromOpaque(context).takeRetainedValue()

            if let dissenter = dissenter {
                let code = DADissenterGetStatus(dissenter)
                let hex = String(format: "%2X", code).lowercased()
                let error = NSError(domain: "Disk unmount failed. Error code: 0x" + hex + ".", code: -1, userInfo: nil)
                wrapped.callback((false,  error))
            } else {
                wrapped.callback((true, nil))
            }

        }, address)
    }

    //        public var kDAReturnSuccess: Int { get }
    //        public var kDAReturnError: Int { get } /* ( 0xF8DA0001 ) */
    //        public var kDAReturnBusy: Int { get } /* ( 0xF8DA0002 ) */
    //        public var kDAReturnBadArgument: Int { get } /* ( 0xF8DA0003 ) */
    //        public var kDAReturnExclusiveAccess: Int { get } /* ( 0xF8DA0004 ) */
    //        public var kDAReturnNoResources: Int { get } /* ( 0xF8DA0005 ) */
    //        public var kDAReturnNotFound: Int { get } /* ( 0xF8DA0006 ) */
    //        public var kDAReturnNotMounted: Int { get } /* ( 0xF8DA0007 ) */
    //        public var kDAReturnNotPermitted: Int { get } /* ( 0xF8DA0008 ) */
    //        public var kDAReturnNotPrivileged: Int { get } /* ( 0xF8DA0009 ) */
    //        public var kDAReturnNotReady: Int { get } /* ( 0xF8DA000A ) */
    //        public var kDAReturnNotWritable: Int { get } /* ( 0xF8DA000B ) */
    //        public var kDAReturnUnsupported: Int { get } /* ( 0xF8DA000C ) */

    func errorCodeToString(code: DAReturn) -> String {
        let status = Int(code)
        
        if status == kDAReturnSuccess {
            return "Successful"
        } else if status == kDAReturnError {
            return ""
        }
        
        return ""
    }

    static func fromURL(_ url: URL) -> Volume? {
        guard
            let session = SessionWrapper.session,
            let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL)
        else { return nil }

        return Volume.fromDisk(disk)
    }
    
    static func fromDisk(_ disk: DADisk) -> Volume? {
        guard
            let dict = DADiskCopyDescription(disk),
            let diskInfo = dict as? [NSString: Any],
            let name = diskInfo[kDADiskDescriptionVolumeNameKey] as? String,
            let size = diskInfo[kDADiskDescriptionMediaSizeKey] as? Int,
            let ejectable = diskInfo[kDADiskDescriptionMediaEjectableKey] as? Bool,
            let removable = diskInfo[kDADiskDescriptionMediaRemovableKey] as? Bool,
            let bsdName = DADiskGetBSDName(disk),
            let pathVal = diskInfo[kDADiskDescriptionMediaPathKey],
            let idVal = diskInfo[kDADiskDescriptionVolumeUUIDKey]
        else { return nil }
        
        if name == VolumeReservedNames.EFI.rawValue {
            return nil
        }
        
        let volumeID = (idVal as! CFUUID)
        let id = CFUUIDCreateString(kCFAllocatorDefault, volumeID) as String
        let path = pathVal as! CFURL
        let device = String(cString: bsdName)
        
        return Volume(id: id, name: name, device: device, path: path, disk: disk, size: size, ejectable: ejectable, removable: removable)
    }

    static func isVolumeURL(_ url: URL) -> Bool {
        return url.pathComponents.count > 1
        && url.pathComponents[VolumeComponent.root.rawValue] == VolumeReservedNames.Volumes.rawValue
    }

    static func queryVolumes() -> [Volume] {
        let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])

        guard let urls = paths else {
            return []
        }

        return urls.filter { Volume.isVolumeURL($0) }.compactMap { Volume.fromURL($0) }
    }
}

class VolumeListener {
    static let shared = VolumeListener()
    
    private var callbacks = [CallbackWrapper<MAppDef, MAppRet>]()
    private var listeners = [CallbackWrapper<CAppDef, CAppRet>]()
    
    deinit {
        callbacks.forEach {
            let address = UnsafeMutableRawPointer(Unmanaged.passUnretained($0).toOpaque())
            let _ = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(address).takeRetainedValue()
        }
        callbacks.removeAll()
        
        listeners.forEach {
            let address = UnsafeMutableRawPointer(Unmanaged.passUnretained($0).toOpaque())
            let _ = Unmanaged<CallbackWrapper<CAppDef, CAppRet>>.fromOpaque(address).takeRetainedValue()
        }
        listeners.removeAll()
        
        guard let session = SessionWrapper.session else { return }
        DASessionSetDispatchQueue(session, nil)
    }
    
    func registerCallbacks() {
        guard
            let session = SessionWrapper.session
            else { return }
        
        DASessionSetDispatchQueue(session, DispatchQueue.global())
        
        mountApproval(session)
        unmountApproval(session)
        changedListener(session)
    }
    
    func changedListener(_ session: DASession) {
        let wrapper = CallbackWrapper<CAppDef, CAppRet>(callback: changedCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())
        
        DARegisterDiskDescriptionChangedCallback(session, nil, nil, { (disk, info, context) in
            guard let context = context else {
                return
            }
            
            let wrapped = Unmanaged<CallbackWrapper<CAppDef, CAppRet>>.fromOpaque(context).takeUnretainedValue()
            return wrapped.callback((disk, info))
            
        }, address)
        
        listeners.append(wrapper)
    }
    
    func changedCallback(disk: DADisk, keys: CFArray) {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "resetTableView"), object: nil, userInfo: ["background": true])
    }
    
    func mountApproval(_ session: DASession) {
        let wrapper = CallbackWrapper<MAppDef, MAppRet>(callback: mountCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())
        
        DARegisterDiskMountApprovalCallback(session, nil, { (disk, context) -> Unmanaged<DADissenter>? in
            guard let context = context else {
                return nil
            }
            
            let wrapped = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(context).takeUnretainedValue()
            return wrapped.callback((disk, context))
            
        }, address)
        
        callbacks.append(wrapper)
    }
    
    func mountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "diskMounted"), object: Volume.fromDisk(disk), userInfo: nil)
        
        return nil
    }
    
    func unmountApproval(_ session: DASession) {
        let wrapper = CallbackWrapper<MAppDef, MAppRet>(callback: unmountCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())
        
        DARegisterDiskUnmountApprovalCallback(session, nil, { (disk, context) -> Unmanaged<DADissenter>? in
            guard let context = context else {
                return nil
            }
            
            let wrapped = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(context).takeUnretainedValue()
            return wrapped.callback((disk, context))
            
        }, address)
        
        callbacks.append(wrapper)
    }
    
    func unmountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        let center = NotificationCenter.default
        center.post(name: Notification.Name(rawValue: "diskUnmounted"), object: Volume.fromDisk(disk), userInfo: nil)
        
        return nil
    }
}
