//
//  VigramSDK_DemoApp.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 03.08.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import SwiftUI

@main
struct VigramSDK_DemoApp: App {
    let vigramHelper = VigramHelper.shared

    var body: some Scene {
        WindowGroup {
            MainScreenView()
        }
    }
}
