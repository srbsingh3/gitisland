//
//  NotchWindowController.swift
//  gitisland
//
//  Controls the notch window positioning and lifecycle
//

import AppKit
import Combine
import SwiftUI

class NotchWindowController: NSWindowController {
    let viewModel: NotchViewModel
    private let screen: NSScreen
    private var cancellables = Set<AnyCancellable>()

    init(screen: NSScreen) {
        self.screen = screen

        let screenFrame = screen.frame
        let notchSize = screen.notchSize

        let windowHeight: CGFloat = 750
        let windowFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - windowHeight,
            width: screenFrame.width,
            height: windowHeight
        )

        let deviceNotchRect = CGRect(
            x: (screenFrame.width - notchSize.width) / 2,
            y: 0,
            width: notchSize.width,
            height: notchSize.height
        )

        self.viewModel = NotchViewModel(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenFrame,
            windowHeight: windowHeight,
            hasPhysicalNotch: screen.hasPhysicalNotch
        )

        let notchWindow = NotchPanel(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: notchWindow)

        let hostingController = NotchViewController(viewModel: viewModel)
        notchWindow.contentViewController = hostingController

        notchWindow.setFrame(windowFrame, display: true)

        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak notchWindow] status in
                switch status {
                case .opened:
                    notchWindow?.ignoresMouseEvents = false
                    NSApp.activate(ignoringOtherApps: false)
                    notchWindow?.makeKey()
                case .closed:
                    notchWindow?.ignoresMouseEvents = true
                }
            }
            .store(in: &cancellables)

        notchWindow.ignoresMouseEvents = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
