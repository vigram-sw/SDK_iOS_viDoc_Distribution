//
//  SelectButton.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 30.01.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import SwiftUI

struct SelectButton: View {
    @Binding var isSelected: Bool
    let color: Color
    let text: String

    var body: some View {
        ZStack {
            Capsule()
                .fill(isSelected ? color.opacity(0.24) : ClientTheme.subtleFill)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color.opacity(0.7) : ClientTheme.border, lineWidth: 1)
                )
                .frame(height: 40)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClientTheme.textPrimary)
        }
        .contentShape(Capsule())
    }
}

struct SelectedButton: ButtonStyle {
    var isSelected = false
    var backgroundColorBase = ClientTheme.subtleFill
    var backgroundColorIsSelected = Color.green
    var foregroundColorBase = ClientTheme.textPrimary
    var foregroundColorIsSelected = ClientTheme.textPrimary
    var height: CGFloat = 40
    var width: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        if let width = width {
            return configuration
                .label
                .font(.body)
                .padding()
                .frame(width: width, height: height)
                .background(isSelected ? backgroundColorIsSelected : backgroundColorBase)
                .foregroundStyle(isSelected ? foregroundColorIsSelected : foregroundColorBase)
                .clipShape(Capsule())
                .fixedSize()
        } else {
            return configuration
                .label
                .font(.title)
                .padding()
                .frame(height: height)
                .background(isSelected ? backgroundColorIsSelected : backgroundColorBase)
                .foregroundStyle(isSelected ? foregroundColorIsSelected : foregroundColorBase)
                .clipShape(Capsule())
                .fixedSize()
        }
    }
}

struct NoTapAnimationStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .contentShape(Rectangle())
            .onTapGesture(perform: configuration.trigger)
    }
}
