//
//  SelectButton.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 30.01.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import SwiftUI

struct SelectButton: View {
    @Binding var isSelected: Bool
    @State var color: Color
    @State var text: String

    var body: some View {
        ZStack {
            Capsule()
                .frame(height: 30)
                .foregroundColor(isSelected ? color : .gray)
            Text(text)
                .foregroundColor(.black)
        }
    }
}

struct SelectedButton: ButtonStyle {
    var isSelected = false
    var backgroundColorBase = Color.white
    var backgroundColorIsSelected = Color.green
    var foregroundColorBase = Color.white
    var foregroundColorIsSelected = Color.white
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
