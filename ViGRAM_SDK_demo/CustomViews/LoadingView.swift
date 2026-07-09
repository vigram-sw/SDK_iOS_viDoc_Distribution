//
//  LoadingView.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

// MARK: Nested types

struct LoadingView<Content>: View where Content: View {

    // MARK: Public propeties

    @Binding var isShowing: Bool
    var message: String
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
                    Text(message)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(ClientTheme.cardBackground)
                .foregroundStyle(ClientTheme.textPrimary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}
