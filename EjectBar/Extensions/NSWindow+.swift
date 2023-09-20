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

    // Based on the window's: NSWindow.StyleMask
    // https://developer.apple.com/documentation/appkit/nswindow/stylemask
    private static let leftRightPadding: CGFloat = 2

    private func makeActiveWindow() {
        // Warning: Window NSWindow 0x148666000 ordered front from a non-active application and may order beneath the active application's windows.
        // makeKeyAndOrderFront(self)
        orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func fadeIn(completion: (() -> Void)? = nil) {
        guard !isMainWindow else {
            makeActiveWindow()
            return
        }

        guard !isVisible else {
            makeActiveWindow()
            completion?()
            return
        }

        alphaValue = 0
        makeActiveWindow()

        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = Self.fadeDuration
            self?.animator().alphaValue = 1
        } completionHandler: { [weak self] in
            self?.makeActiveWindow()
            completion?()
        }
    }

    func fadeOut(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = Self.fadeDuration
            self?.animator().alphaValue = 0
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
