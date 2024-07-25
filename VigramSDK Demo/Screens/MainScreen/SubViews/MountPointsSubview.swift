//
//  MountPointsSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 24.05.2024.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI
import VigramSDK

class MountPointsValuesData: ObservableObject {

    // MARK: Public properties

    @Published var currentMountPointName: String
    @Published var allMountPointNames: [String]

    // MARK: Init

    init(
        currentMountPointName: String,
        allMountPointNames: [String]
    ) {
        self.currentMountPointName = currentMountPointName
        self.allMountPointNames = allMountPointNames
    }
}

struct MountPointsSubview: View {

    // MARK: Public properties

    var action: ((String) -> Void)?
    var dissmiss: (() -> Void)?

    // MARK: Private properties

    @ObservedObject private var data: MountPointsValuesData
    @State private var selectedId: String = ""

    // MARK: Computed propeties

    var body: some View {
        VStack(spacing: Constants.vStackSpacing) {
            ZStack {
                Text(Constants.title)
                    .font(Constants.textFont)
                HStack {
                    Spacer()
                    Button {
                        dissmiss?()
                    } label: {
                        Image(systemName: Constants.imageName)
                            .frame(
                                width: Constants.imageSize.width,
                                height: Constants.imageSize.height
                            )
                            .font(Constants.imageFont)
                            .padding(Constants.imagePadding)
                            .foregroundColor(Constants.imageForegroundColor)
                    }
                    .buttonStyle(NoTapAnimationStyle())
                }
            }.padding(Constants.zStackPadding)
            if data.allMountPointNames.isEmpty {
                VStack {
                    Spacer()
                    ProgressView().controlSize(.large)
                    Spacer()
                }
            } else {
                List {
                    ForEach(0..<data.allMountPointNames.count, id: \.self) { index in
                        RadioButtonField(
                            id: "\(index)",
                            label: data.allMountPointNames[index],
                            isMarked: selectedId == "\(index)" ? true : false
                        ) { _ in
                            selectedId = "\(index)"
                        }
                        .listRowSeparator(.hidden, edges: .all)
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(Constants.listRowSpacing)
            }
            VStack {
                Button(Constants.btnTitle) {
                    if let index = Int(selectedId), index < data.allMountPointNames.count {
                        action?(data.allMountPointNames[index])
                    }
                }.buttonStyle(
                    SelectedButton(
                        isSelected: selectedId != "",
                        backgroundColorBase: .gray,
                        backgroundColorIsSelected: .green,
                        foregroundColorBase: .black,
                        foregroundColorIsSelected: .black,
                        height: Constants.btnSize.height,
                        width: Constants.btnSize.width
                    )
                ).padding(Constants.btnPadding)
            }
        }
    }

    // MARK: Init

    init(data: MountPointsValuesData) {
        self.data = data
    }
}

// MARK: - Constants

private extension MountPointsSubview {
    enum Constants {

        // MARK: UI constants

        static let title = "Mount points"
        static let frameHeight: CGFloat = 40
        static let vStackSpacing: CGFloat = 0
        static let stackPadding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let textFont = Font.system(size: 16, weight: .bold)
        static let imageName = "xmark"
        static let imageSize = CGSize(width: 24, height: 24)
        static let imageFont = Font.system(size: 16, weight: .bold)
        static let imagePadding = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        static let imageForegroundColor = Color.black
        static let zStackPadding = EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 16)
        static let listRowSpacing: CGFloat = -10
        static let btnTitle = String(localized: "Choose")
        static let btnSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 48)
        static let btnPadding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}
// MARK: - Custom action method

extension MountPointsSubview {
    func action(_ handler: @escaping (String) -> Void) -> MountPointsSubview {
        var new = self
        new.action = handler
        return new
    }

    func dissmiss(_ handler: @escaping () -> Void) -> MountPointsSubview {
        var new = self
        new.dissmiss = handler
        return new
    }
}
