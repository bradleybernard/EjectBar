//
//  HomeVC.swift
//  EjectBar
//
//  Created by Bradley Bernard on 7/24/17.
//  Copyright © 2017 Bradley Bernard. All rights reserved.
//

import Cocoa
import Foundation

class HomeVC: NSViewController {    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VolumeListener.instance.registerCallbacks()
        displayVolumes(Volume.queryVolumes())
    }
    
    func displayVolumes(_ volumes: [Volume]) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        volumes.enumerated().forEach {
            view.addSubview(NSTextField(labelWithString: $1.name + " " + formatter.string(fromByteCount: Int64($1.size))))
            $1.unmount(callback: {(success: Bool, error: String?) in
                print(success)
                print(error as Any)
            })
        }
    }
    
}
