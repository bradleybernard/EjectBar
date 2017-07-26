//
//  Volume.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//
//
import Foundation

typealias VolumeID = (NSCopying & NSSecureCoding & NSObjectProtocol)

typealias UnmountDef = (Bool, String?)
typealias UnmountRet = Void
typealias UnmountCallback = (Bool, String?) -> Void

typealias MAppDef = (DADisk, UnsafeMutableRawPointer?)
typealias MAppRet = Unmanaged<DADissenter>?
typealias MAppCallback = (DADisk, UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>?

enum VolumeComponent: Int {
    case root = 1
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

    var id: String
    var name: String
    var device: String
    var disk: DADisk
    var size: Int
    var ejectable: Bool
    var removable: Bool

    static let keys: [URLResourceKey] = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]
    static let set: Set<URLResourceKey> = [.volumeIdentifierKey, .volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeIsEjectableKey, .volumeIsRemovableKey]

    init(id: String, name: String, device: String, disk: DADisk, size: Int, ejectable: Bool, removable: Bool) {
        self.id = id
        self.name = name
        self.device = device
        self.disk = disk
        self.size = size
        self.ejectable = ejectable
        self.removable = removable
    }

    func unmount(callback: @escaping UnmountCallback) {

        let wrapper = CallbackWrapper<UnmountDef, UnmountRet>(callback: callback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())

        DADiskUnmount(disk, DADiskUnmountOptions(kDADiskMountOptionWhole & kDADiskUnmountOptionForce), { (volume, dissenter, context) in

            guard let context = context else {
                return
            }

            let wrapped = Unmanaged<CallbackWrapper<UnmountDef, UnmountRet>>.fromOpaque(context).takeRetainedValue()

            if let error = dissenter {
                wrapped.callback((false, String(describing: DADissenterGetStatusString(error))))
            } else {
                wrapped.callback((true, nil))
            }

        }, address)
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
            let bsdName = DADiskGetBSDName(disk)
        else { return nil }
        
        let volumeID = (diskInfo[kDADiskDescriptionVolumeUUIDKey] as! CFUUID)
        let id = CFUUIDCreateString(kCFAllocatorDefault, volumeID) as String
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

class VolumeListener {
    
    static let instance = VolumeListener()
    var callbacks = [CallbackWrapper<MAppDef, MAppRet>]()
    
    deinit {
        callbacks.forEach {
            let address = UnsafeMutableRawPointer(Unmanaged.passUnretained($0).toOpaque())
            let _ = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(address).takeRetainedValue()
        }
        
        callbacks.removeAll()
    }
    
    func registerCallbacks() {
        
        guard
            let session = SessionWrapper.session
            else { return }
        
        DASessionSetDispatchQueue(session, DispatchQueue.global())
        
        mountApproval(session)
        unmountApproval(session)
        appearApproval(session)
    }
    
    func appearApproval(_ session: DASession) {
        
        let wrapper = CallbackWrapper<MAppDef, MAppRet>(callback: appearCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())
        
        DARegisterDiskAppearedCallback(session, nil, { (disk, context) -> Void in
            //public typealias DADiskAppearedCallback = @convention(c) (DADisk, UnsafeMutableRawPointer?) -> Swift.Void
            
        }, address)
        
        callbacks.append(wrapper)
    }
    
    func appearCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        
//        print("Appear")
////        let center = NotificationCenter.default
////        center.post(name:Notification.Name(rawValue: "diskMounted"), object: disk, userInfo: nil)
//
        return nil
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
        center.post(name:Notification.Name(rawValue: "diskMounted"), object: Volume.fromDisk(disk), userInfo: nil)
        
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
        center.post(name:Notification.Name(rawValue: "diskUnmounted"), object: Volume.fromDisk(disk), userInfo: nil)
        
        return nil
    }
}
