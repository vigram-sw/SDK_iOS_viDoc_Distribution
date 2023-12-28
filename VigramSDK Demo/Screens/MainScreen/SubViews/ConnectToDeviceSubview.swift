//
//  ConnectToDeviceSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 14.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct ConnectToDeviceSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            Text("Available devices")
                .font(Font.headline.bold())
                .padding(6)
            if viewModel.allDeviceNames.isEmpty {
                ProgressView()
            } else {
                ForEach(viewModel.allDeviceNames, id: \.self) { deviceName in
                    Button {
                        viewModel.connectToDevice(name: deviceName)
                    } label: {
                        Text("Connect to " + deviceName)
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                    }.buttonStyle(.bordered).padding(6)
                }
            }
        }
    }
}
