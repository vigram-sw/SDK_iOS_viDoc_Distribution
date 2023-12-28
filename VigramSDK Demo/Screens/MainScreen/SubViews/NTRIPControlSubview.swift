//
//  NTRIPControlSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 14.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct NTRIPControlSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showNtrip = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            Button {
                self.showNtrip.toggle()
            } label: {
                if showNtrip {
                    Text("Hide NTRIP control").font(Font.headline.bold()).foregroundColor(.black)
                    Image(systemName: "chevron.up").foregroundColor(.black)
                } else {
                    Text("Show NTRIP control").font(Font.headline.bold()).foregroundColor(.black)
                    Image(systemName: "chevron.down").foregroundColor(.black)
                }
            }.buttonStyle(.bordered)

            if showNtrip {
                VStack {
                    Text("NTRIP configuration").font(Font.headline.bold()).padding()
                    if !viewModel.ntripCredentials.isEmpty {
                        Text("Save credentials").font(Font.headline.bold())
                        ForEach(viewModel.ntripCredentials, id: \.self) { current in
                            Button {
                                viewModel.hostname = current.host
                                viewModel.port = String(current.port)
                                viewModel.username = current.login
                                viewModel.password = current.pass
                                viewModel.mountPoint = current.mountpoint
                            } label: {
                                Text("Use \(current.host)")
                                    .font(Font.headline.bold())
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(.bordered)
                            .padding(6)
                        }
                    }
                    HStack {
                        Text("  Mount point: ")
                        TextField("Mount point", text: $viewModel.mountPoint)
                            .keyboardType(UIKeyboardType.default)
                        Spacer()
                    }
                    HStack {
                        Text("  Hostname: ")
                        TextField("Hostname", text: $viewModel.hostname)
                            .keyboardType(UIKeyboardType.default)
                        Spacer()
                    }
                    HStack {
                        Text("  Port: ")
                        TextField("Port", text: $viewModel.port)
                            .keyboardType(UIKeyboardType.decimalPad)
                        Spacer()
                    }
                    HStack {
                        Text("  Username: ")
                        TextField("Username", text: $viewModel.username)
                            .keyboardType(UIKeyboardType.default)
                        Spacer()
                    }
                    HStack {
                        Text("  Password: ")
                        TextField("Password", text: $viewModel.password)
                            .keyboardType(UIKeyboardType.default)
                        Spacer()
                    }
                }.padding(6)
                VStack {
                    Text("NTRIP control").font(Font.headline.bold())
                    HStack {
                        Button { viewModel.connectToNTRIP() } label: {
                            Text("Connect").font(Font.headline.bold()).foregroundColor(.black)
                        }.buttonStyle(.bordered)
                        Button { viewModel.disconnectNtrip() } label: {
                            Text("Disconnect").font(Font.headline.bold()).foregroundColor(.black)
                        }.buttonStyle(.bordered)
                        Button { viewModel.reConnectToNTRIP() } label: {
                            Text("Reconnect").font(Font.headline.bold()).foregroundColor(.black)
                        }.buttonStyle(.bordered)
                    }.padding(10)
                    Button { viewModel.reConnectToNTRIPWithReset() } label: {
                        Text("Reconnect NTRIP with Reset").font(Font.headline.bold()).foregroundColor(.black)
                    }.buttonStyle(.bordered)
                }
            }
        }
        VStack {
            Text("NTRIP info")
                .font(Font.headline.bold())
                .padding(6)
            HStack {
                Text("  Status: ").font(Font.headline.bold())
                Text(viewModel.ntripStatus)
                Spacer()
            }
        }.padding(6)
        VStack {
            Text("NTRIP received data info")
                .font(Font.headline.bold())
                .padding(6)
            ScrollView{
                TextEditor(text: .constant(viewModel.ntripSizeParcel))
                    .font(.system(size: 10.0))
                    .border(Color.black, width: 1)
                    .frame(width: UIScreen.main.bounds.size.width-32, height: 150, alignment: .topLeading)
            }
        }.padding(6)
    }
}
