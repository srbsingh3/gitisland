//
//  gitislandApp.swift
//  gitisland
//
//  Created by Saurabh on 17.01.26.
//

import SwiftUI

@main
struct gitislandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
