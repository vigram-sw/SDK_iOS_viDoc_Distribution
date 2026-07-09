//
//  SwiftUI+Extension.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import UIKit
import SwiftUI

enum ClientTheme {
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let fieldBackground = Color(uiColor: .secondarySystemBackground)
    static let subtleFill = Color(uiColor: .secondarySystemFill)
    static let border = Color.primary.opacity(0.1)
    static let activeBorder = Color.accentColor.opacity(0.7)
    static let textPrimary = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .white : .black
    })
    static let textSecondary = textPrimary
    static let shadow = Color.black.opacity(0.06)
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension View {
    func alertButtonTint(color: Color) -> some View {
        modifier(AlertButtonTintColor(color: color))
    }
}

struct AlertButtonTintColor: ViewModifier {
    let color: Color
    @State private var previousTintColor: UIColor?

    func body(content: Content) -> some View {
        content
            .onAppear {
                previousTintColor = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(color)
            }
            .onDisappear {
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = previousTintColor
            }
    }
}
