//
//  OnlineSoftwareUpdateSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 14.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct OnlineSoftwareUpdateSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showSoftware = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            if viewModel.isFlashingDevice {
                Text("Status update device")
                    .font(Font.headline.bold())
                    .padding(6)
                Text(viewModel.statusUpdate)
                Text(viewModel.progressUpdate)
            }
            if viewModel.isConnectedDevice, !viewModel.isFlashingDevice {
                Button {
                    showSoftware.toggle()
                } label: {
                    if showSoftware {
                        Text("Hide Software Info")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Show Software Info")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }.buttonStyle(.bordered)
                if showSoftware {
                    Text("List of available softwares:")
                        .font(Font.headline.bold())
                        .padding(6)
                    ForEach(viewModel.allAvailableSoftwareNamesForWeb, id: \.self) { software in
                        Button {
                            viewModel.installSoftware(name: software)
                        } label: {
                            Text("Install " + software)
                                .font(Font.headline.bold())
                                .foregroundColor(.black)
                        }.buttonStyle(.bordered).padding(6)
                    }
                    Button {
                        viewModel.setForceUpdateSoftware()
                    } label: {
                        Text("Force update actual software")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                    }.buttonStyle(.bordered)
                }
            }
        }.padding(6)
    }
}
