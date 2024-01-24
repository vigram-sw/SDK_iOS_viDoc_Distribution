//
//  DeviceInfoSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 14.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct DeviceInfoSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showViDocReset = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            Button {
                viewModel.disconnect()
            } label: {
                Text("Disconnect")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            Text("Device info")
                .font(Font.headline.bold())
                .padding(6)
            VStack {
                VStack {
                    HStack {
                        Text("  Name device: ")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Text(viewModel.currentDeviceName)
                        Spacer()
                    }
                    HStack {
                        Text("  Serial number: ")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Text(viewModel.currentSerialNumber)
                        Spacer()
                    }
                    HStack {
                        Text("  Hardware on device: ")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Text(viewModel.currentDeviceHardwareVersion)
                        Spacer()
                    }
                    HStack {
                        Text("  Software on device: ")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Text(viewModel.currentDeviceSoftwareVersion)
                        Spacer()
                    }
                    HStack {
                        Text("  Battery: ")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Text(viewModel.currentDeviceCharge)
                        Spacer()
                    }
                }
                HStack {
                    Text("  Connection perephiral status: ")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    switch viewModel.periphiralState {
                    case.connecting:
                        ProgressView()
                    case .connected:
                        Image(systemName: "wave.3.right")
                            .foregroundColor(.green)
                    case .disconnecting:
                        ProgressView()
                    case .disconnected:
                        Image(systemName: "wave.3.right")
                            .foregroundColor(.red)
                    @unknown default:
                        exit(0)
                    }
                    Spacer()
                }
                HStack {
                    Text("  Connection device status: ")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    if viewModel.isConnectedDevice {
                        Image(systemName: "personalhotspot")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "personalhotspot")
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                HStack {
                    Text("  Starting device status: ")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    if viewModel.isStartDevice {
                        Image(systemName: "bolt.horizontal.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "bolt.horizontal.fill")
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                Button {
                    self.showViDocReset.toggle()
                } label: {
                    if showViDocReset {
                        Text("Hide reset viDoc control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Show reset viDoc control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }.buttonStyle(.bordered)
                if showViDocReset {
                    Text("Reset viDoc control")
                        .font(Font.headline.bold())
                        .padding(6)
                    if viewModel.resetMessageError != "" {
                        Text(viewModel.resetMessageError)
                            .font(Font.headline.bold())
                            .padding(6)
                            .foregroundColor(.red)
                    }
                    VStack {
                        Button { viewModel.resetDevice() } label: {
                            Text("Reset viDoc")
                                .font(Font.headline.bold())
                                .foregroundColor(.black)
                        }.buttonStyle(.bordered)
                        Text("GNTXT Messages:")
                            .font(Font.headline.bold())
                            .padding(6)
                        ScrollView{
                            TextEditor(text: .constant(viewModel.viDocState))
                                .font(.system(size: 10.0))
                                .border(Color.black, width: 1)
                                .frame(width: UIScreen.main.bounds.size.width-32, height: 150, alignment: .topLeading)
                        }
                        Button { viewModel.clearTXTLog() } label: {
                            Text("Clear log")
                                .font(Font.headline.bold())
                                .foregroundColor(.black)
                        }.buttonStyle(.bordered)
                    }
                }
            }.padding(6)
            Button { viewModel.requestBattery() } label: {
                Text("Get battery charge")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            Button { viewModel.requestVersion() } label: {
                Text("Get current software / hardware version")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
        }
    }
}
