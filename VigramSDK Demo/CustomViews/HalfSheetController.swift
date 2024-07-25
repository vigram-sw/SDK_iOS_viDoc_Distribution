//
//  HalfSheetController.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 25.04.2024.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI
import UIKit

class HalfSheetController<Content>: UIHostingController<Content> where Content: View {

    // MARK: Private properties

    private var isSmall: Bool

    // MARK: Inheritance

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let presentation = sheetPresentationController {
            if isSmall {
                if #available(iOS 16.0, *) {
                    presentation.detents = [.custom { _ in 300 }]
                } else {
                    presentation.detents = [.medium()]
                }
                presentation.preferredCornerRadius = 32
            } else {
                presentation.detents = [.large()]
            }

            presentation.prefersGrabberVisible = isSmall
            presentation.largestUndimmedDetentIdentifier = .large
        }
    }

    // MARK: Init

    init(rootView: Content, isSmall: Bool) {
        self.isSmall = isSmall
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct HalfSheet<Content>: UIViewControllerRepresentable where Content: View {

    // MARK: Private properties

    private let content: Content
    private var isSmall: Bool

    // MARK: Init

    @inlinable init(isSmall: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isSmall = isSmall
    }

    // MARK: Public methods

    func makeUIViewController(context: Context) -> HalfSheetController<Content> {
        return HalfSheetController(rootView: content, isSmall: isSmall)
    }

    func updateUIViewController(_: HalfSheetController<Content>, context: Context) { }
}
