//
//  MountPointsSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 14.02.2024.
//  Copyright © 2020 Vigram. All rights reserved.
//

import SwiftUI
import VigramSDK

class MountPointsValuesData: ObservableObject {

    // MARK: Public properties

    @Published var currentMountPointName: String
    @Published var allMountPointNames: [String]
    @Published var isLoading: Bool
    @Published var errorMessage: String?

    // MARK: Init

    init(
        currentMountPointName: String,
        allMountPointNames: [String],
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.currentMountPointName = currentMountPointName
        self.allMountPointNames = allMountPointNames
        self.isLoading = isLoading
        self.errorMessage = errorMessage
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
            if data.isLoading && data.allMountPointNames.isEmpty {
                messageView {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading mount points...")
                        .font(.subheadline)
                        .foregroundStyle(ClientTheme.textSecondary)
                }
            } else if let errorMessage = data.errorMessage, data.allMountPointNames.isEmpty {
                messageView {
                    Text("Unable to load mount points")
                        .font(.headline)
                        .foregroundStyle(ClientTheme.textPrimary)
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ClientTheme.textSecondary)
                        .padding(.horizontal, Constants.messageHorizontalPadding)
                }
            } else if data.allMountPointNames.isEmpty {
                messageView {
                    Text("No mount points found")
                        .font(.headline)
                        .foregroundStyle(ClientTheme.textPrimary)
                    Text("Check the caster credentials and try loading mount points again.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ClientTheme.textSecondary)
                        .padding(.horizontal, Constants.messageHorizontalPadding)
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
                        foregroundColorBase: ClientTheme.textPrimary,
                        foregroundColorIsSelected: ClientTheme.textPrimary,
                        height: Constants.btnSize.height,
                        width: Constants.btnSize.width
                    )
                ).padding(Constants.btnPadding)
            }
        }
        .onChange(of: data.allMountPointNames) { _ in
            selectedId = ""
        }
    }

    // MARK: Init

    init(data: MountPointsValuesData) {
        self.data = data
    }

    private func messageView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: Constants.messageSpacing) {
            Spacer()
            content()
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
        static let imageForegroundColor = ClientTheme.textPrimary
        static let zStackPadding = EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 16)
        static let listRowSpacing: CGFloat = -10
        static let messageSpacing: CGFloat = 12
        static let messageHorizontalPadding: CGFloat = 24
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
