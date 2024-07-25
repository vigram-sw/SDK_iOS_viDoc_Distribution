//
//  RadioButtonField.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 25.04.2024.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct RadioButtonField: View {

    // MARK: Private properties

    private let id: String
    private let label: String
    private let isMarked: Bool
    private let callback: (String) -> Void

    // MARK: Computed properties

    var body: some View {
        Button {
            callback(id)
        } label: {
            HStack(alignment: .center, spacing: Constants.hStackSpacing) {
                Image(systemName: isMarked ? Constants.isMarkedImgName : Constants.isNotMarkedImgName)
                    .frame(
                        width: Constants.imageSize.width,
                        height: Constants.imageSize.height
                    )
                    .font(Constants.imageFont)
                    .padding(Constants.imagePadding)
                    .foregroundColor(Constants.imageForegroundColor)
                Text(label)
                    .font(Constants.textLblFont)
                    .foregroundColor(Constants.textLblForegroundColor)
                Spacer()
            }
        }
        .buttonStyle(NoTapAnimationStyle())
        .foregroundColor(Color.white)
    }

    // MARK: Init

    init(
        id: String,
        label: String,
        isMarked: Bool = false,
        callback: @escaping (String) -> Void
    ) {
        self.id = id
        self.label = label
        self.isMarked = isMarked
        self.callback = callback
    }
}
// MARK: - Constants

private extension RadioButtonField {
    enum Constants {

        // MARK: UI constants

        static let hStackSpacing = CGFloat(10)
        static let isMarkedImgName = "circle.fill"
        static let isNotMarkedImgName = "circle"
        static let imageSize = CGSize(width: 24, height: 24)
        static let textLblFont = Font.system(size: 14).weight(.medium)
        static let textLblForegroundColor = Color(red: 0.2, green: 0.2, blue: 0.2)
        static let imageFont = Font.system(size: 16, weight: .bold)
        static let imagePadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        static let imageForegroundColor = Color.black
    }
}
