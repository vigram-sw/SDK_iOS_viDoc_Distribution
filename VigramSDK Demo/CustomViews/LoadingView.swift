//
//  LoadingView.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

// MARK: Nested types

public enum ConfigurationViewMessages: String {
    case configuration = "Configuration in progress"
    case reset = "viDoc is reseting\n(Estimated time 60 sec)"
    case resetWithNtrip = "viDoc is reseting. \nAfter reset, NTRIP connection will be restored \n(Estimated time 70 sec)"
}

struct LoadingView<Content>: View where Content: View {

    // MARK: Public propeties

    @Binding var isShowing: Bool
    var message: ConfigurationViewMessages
    var content: () -> Content

    // MARK: Computer properties

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)
                VStack {
                    Text("Please wait...")
                    Text(message.rawValue)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}
