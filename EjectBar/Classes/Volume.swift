//
//  Volume.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//
//

import Foundation


// MARK: - Type aliases

private typealias UnmountDef = (Bool, NSError?)
private typealias UnmountRet = Void
typealias UnmountCallback = (Bool, NSError?) -> Void

private typealias MAppDef = (DADisk, UnsafeMutableRawPointer?)
private typealias MAppRet = Unmanaged<DADissenter>?
private typealias MAppCallback = (DADisk, UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>?

private typealias CAppDef = (DADisk, CFArray)
private typealias CAppRet = Void
private typealias CAppCallback = (DADisk, CFArray) -> Void

// MARK: - Volume constants

private enum VolumeComponent: Int {
    case root = 1
}

private enum VolumeReservedNames: String {
    case EFI = "EFI"
    case Volumes = "Volumes"
}

// MARK: - Callbacks

private class CallbackWrapper<Input, Output> {
    let callback : (Input) -> Output
    init(callback: @escaping (Input) -> Output) {
        self.callback = callback
    }
}

// MARK: - DASession

class SessionWrapper {
    static let shared: DASession? = DASessionCreate(kCFAllocatorDefault)
}

// MARK: - Volume

@objcMembers
class Volume: NSObject {
    let disk: DADisk

    let id: String
    let name: String
    let model: String
    let device: String
    let `protocol`: String
    let path: String
    let size: Int
    let ejectable: Bool
    let removable: Bool

    init(disk: DADisk, id: String, name: String, model: String, device: String, protocol: String, path: String, size: Int, ejectable: Bool, removable: Bool) {
        self.disk = disk
        self.id = id
        self.name = name
        self.model = model
        self.device = device
        self.protocol = `protocol`
        self.path = path
        self.size = size
        self.ejectable = ejectable
        self.removable = removable
    }

    private static let keys: [URLResourceKey] = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    private static let set: Set<URLResourceKey> = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]

    func unmount(callback: @escaping UnmountCallback) {
        let wrapper = CallbackWrapper<UnmountDef, UnmountRet>(callback: callback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())

        DADiskUnmount(disk, DADiskUnmountOptions(kDADiskUnmountOptionDefault), { (volume, dissenter, context) in
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

    private func errorCodeToString(code: DAReturn) -> String {
        let status = Int(code)
        
        if status == kDAReturnSuccess {
            return "Successful"
        } else if status == kDAReturnError {
            return ""
        }
        
        return ""
    }

    static func fromURL(_ url: URL) -> Volume? {
        guard let session = SessionWrapper.shared, let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL) else {
            return nil
        }

        return Volume.fromDisk(disk)
    }
    
    static func fromDisk(_ disk: DADisk) -> Volume? {
        guard let dict = DADiskCopyDescription(disk),
            let diskInfo = dict as? [NSString: Any],
            let name = diskInfo[kDADiskDescriptionVolumeNameKey] as? String,
            let size = diskInfo[kDADiskDescriptionMediaSizeKey] as? Int,
            let ejectable = diskInfo[kDADiskDescriptionMediaEjectableKey] as? Bool,
            let removable = diskInfo[kDADiskDescriptionMediaRemovableKey] as? Bool,
            let bsdName = diskInfo[kDADiskDescriptionMediaBSDNameKey] as? String,
            let path = diskInfo[kDADiskDescriptionVolumePathKey] as? URL,
            let idVal = diskInfo[kDADiskDescriptionVolumeUUIDKey],
            let model = diskInfo[kDADiskDescriptionDeviceModelKey] as? String,
            let `protocol` = diskInfo[kDADiskDescriptionDeviceProtocolKey] as? String
        else {
            return nil
        }

        guard name != VolumeReservedNames.EFI.rawValue else {
            return nil
        }
        
        let volumeID = idVal as! CFUUID

        guard let cfID = CFUUIDCreateString(kCFAllocatorDefault, volumeID) else {
            return nil
        }

        let id = cfID as String
        
        return Volume(
            disk: disk,
            id: id,
            name: name,
            model: model,
            device: bsdName,
            protocol: `protocol`,
            path: path.absoluteString,
            size: size,
            ejectable: ejectable,
            removable: removable
        )
    }

    static func isVolumeURL(_ url: URL) -> Bool {
        url.pathComponents.count > 1 && url.pathComponents[VolumeComponent.root.rawValue] == VolumeReservedNames.Volumes.rawValue
    }

    static func queryVolumes() -> [Volume] {
        guard let urls = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else {
            return []
        }

        return urls.filter { Volume.isVolumeURL($0) }.compactMap { Volume.fromURL($0) }
    }
}

// MARK: - Volume Listener

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
        
        guard let session = SessionWrapper.shared else {
            return
        }
        
        DASessionSetDispatchQueue(session, nil)
    }
    
    func registerCallbacks() {
        guard let session = SessionWrapper.shared else {
            return
        }
        
        DASessionSetDispatchQueue(session, DispatchQueue.main)
        
        mountApproval(session)
        unmountApproval(session)
        changedListener(session)
    }
    
    private func changedListener(_ session: DASession) {
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
    
    private func changedCallback(disk: DADisk, keys: CFArray) {
        NotificationCenter.default.post(name: .resetTableView, object: nil, userInfo: nil)
    }
    
    private func mountApproval(_ session: DASession) {
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
    
    private func mountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        NotificationCenter.default.post(name: .diskMounted, object: Volume.fromDisk(disk), userInfo: nil)
        return nil
    }
    
    private func unmountApproval(_ session: DASession) {
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
    
    private func unmountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        NotificationCenter.default.post(name: .diskUnmounted, object: Volume.fromDisk(disk), userInfo: nil)
        return nil
    }
}
