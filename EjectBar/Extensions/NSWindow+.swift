//
//  NSWindow+.swift
//  EjectBar
//
//  Created by Bradley Bernard on 10/28/20.
//  Copyright © 2020 Bradley Bernard. All rights reserved.
//

import Foundation
import AppKit

extension NSWindow {

    private static let fadeDuration = 0.35
    private static let leftRightPadding: CGFloat = 2
    
    func fadeIn(completion: (() -> Void)? = nil) {
        guard !isKeyWindow else {
            return
        }

        alphaValue = 0

        makeKeyAndOrderFront(self)
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)

        NSAnimationContext.runAnimationGroup { [weak self] context in
            guard let self = self else {
                return
            }

            context.duration = Self.fadeDuration
            self.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
            self?.makeKeyAndOrderFront(self)

            completion?()
        }
    }

    func fadeOut(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { [weak self] context in
            guard let self = self else {
                return
            }

            context.duration = Self.fadeDuration
            self.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            guard let self = self else {
                return
            }

            self.contentViewController?.view.window?.orderOut(self)
            self.alphaValue = 1

            completion?()
        }
    }

    func resizeToFitTableView(tableView: NSTableView?) {
        guard let tableView = tableView else {
            return
        }

        let widthDifference = frame.size.width - tableView.frame.size.width

        // A window with a tableView has a 1 pixel line on left and 1 pixel line on right,
        // so we don't want to shrink the window by 2 pixels each time we redraw the tableView.
        // If the difference in width's is 2, we don't change the frame
        guard widthDifference != Self.leftRightPadding else {
            return
        }

        var windowFrame = frame
        windowFrame.size.width = tableView.frame.size.width

        setFrame(windowFrame, display: true)
    }

}
