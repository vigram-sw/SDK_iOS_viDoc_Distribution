//
//  ActivityViewController.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {

    // MARK: Public propeties

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    // MARK: Public methods

    func makeUIViewController(
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ActivityViewController>
    ) {}
}
