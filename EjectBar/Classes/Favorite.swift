//
//  Favorite.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/28/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Foundation

@objcMembers
class Favorite: NSObject, Codable {
    let id: String
    let name: String
    let date: Date

    init(id: String, name: String, date: Date) {
        self.id = id
        self.name = name
        self.date = date
    }
}
