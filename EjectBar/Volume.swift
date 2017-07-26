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
typealias MAppCallback = (DADisk, UnsafeMutableRawPointer?) -> MAppRet

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
            let resources = try? url.resourceValues(forKeys: set),
            let id = resources.volumeIdentifier,
            let name = resources.volumeLocalizedName,
            let size = resources.volumeTotalCapacity,
            let ejectable = resources.volumeIsEjectable,
            let removable = resources.volumeIsRemovable,
            let session = SessionWrapper.session,
            let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL),
            let bsdName = DADiskGetBSDName(disk)
        else { return nil }

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
    
    static func registerCallbacks() {

        guard
            let session = SessionWrapper.session
        else { return }

        DASessionSetDispatchQueue(session, DispatchQueue.global())

        mountApproval(session)
        unmountApproval(session)
    }

    static func mountApproval(_ session: DASession) {

        let wrapper = CallbackWrapper<MAppDef, MAppRet>(callback: mountCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())

        DARegisterDiskMountApprovalCallback(session, nil, { (disk, context) -> Unmanaged<DADissenter>? in

            guard let context = context else {
                return nil
            }

            let wrapped = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(context).takeUnretainedValue()
            return wrapped.callback((disk, context))
            
        }, address)
    }

    static func mountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        print("Disk mounted")
        return nil
    }

    static func unmountApproval(_ session: DASession) {

        let wrapper = CallbackWrapper<MAppDef, MAppRet>(callback: unmountCallback)
        let address = UnsafeMutableRawPointer(Unmanaged.passRetained(wrapper).toOpaque())

        DARegisterDiskUnmountApprovalCallback(session, nil, { (disk, context) -> Unmanaged<DADissenter>? in

            guard let context = context else {
                return nil
            }

            let wrapped = Unmanaged<CallbackWrapper<MAppDef, MAppRet>>.fromOpaque(context).takeUnretainedValue()
            return wrapped.callback((disk, context))

        }, address)
    }

    static func unmountCallback(disk: DADisk, cont: UnsafeMutableRawPointer?) -> Unmanaged<DADissenter>? {
        print("Disk unmounted")
        return nil
    }
}

