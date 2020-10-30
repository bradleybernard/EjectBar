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

    private static let fadeDuration = 1.0

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



}
