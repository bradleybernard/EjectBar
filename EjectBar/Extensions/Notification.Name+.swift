//
//  Notification.Name+.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/28/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let resetTableView = Notification.Name("resetTableView")

    static let hideFavoritesWindow = Notification.Name("hideFavoritesWindow")
    static let showFavoritesWindow = Notification.Name("showFavoritesWindow")

    static let hideVolumesWindow = Notification.Name("hideVolumesWindow")
    static let showVolumesWindow = Notification.Name("showVolumesWindow")

    static let postVolumeCount = Notification.Name("postVolumeCount")
    static let updateVolumeCount = Notification.Name("updateVolumeCount")


    static let favoritesUpdated = Notification.Name("favoritesUpdated")
    static let ejectFavorites = Notification.Name("ejectFavorites")

    static let diskUnmounted = Notification.Name("diskUnmounted")
    static let diskMounted = Notification.Name("diskMounted")
}
