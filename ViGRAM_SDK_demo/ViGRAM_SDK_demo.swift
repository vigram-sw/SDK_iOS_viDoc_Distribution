//
//  ViGRAM_SDK_demo.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 03.08.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import Foundation
import SwiftUI

@main
struct ViGRAM_SDK_demo: App {

    private let vigramHelper: VigramHelper
        private let token: String = ""
    init() {
        self.vigramHelper = VigramHelper(token: self.token)
    }
    
    var body: some Scene {
        WindowGroup {
            MainScreenView(vigramHelper: vigramHelper)
        }
    }
}
