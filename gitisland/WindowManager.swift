//
//  WindowManager.swift
//  gitisland
//
//  Manages the notch window lifecycle
//

import AppKit

class WindowManager {
    private(set) var windowController: NotchWindowController?

    func setupNotchWindow() -> NotchWindowController? {
        guard let screen = NSScreen.builtin else {
            print("No screen found")
            return nil
        }

        if let existingController = windowController {
            existingController.window?.orderOut(nil)
            existingController.window?.close()
            windowController = nil
        }

        windowController = NotchWindowController(screen: screen)
        windowController?.showWindow(nil)

        return windowController
    }
}
