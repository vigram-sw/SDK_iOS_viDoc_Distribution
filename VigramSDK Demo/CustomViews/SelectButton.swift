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
