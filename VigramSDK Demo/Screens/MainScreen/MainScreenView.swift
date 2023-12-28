//
//  MainScreenView.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI
import UIKit

struct MainScreenView: View {

    // MARK: Private properties

    @ObservedObject private var viewModel = MainScreenViewModel()

    @State private var showRecordFiles = false
    @State private var recordIsActive = false
    @State private var showDeviation = false
    @State private var useNTRIP = true
    @State private var usePPS = false

    // MARK: Computed properties

    var body: some View {
        LoadingView(
            isShowing: $viewModel.isConfiguringDevice,
            message: viewModel.isResetingDevice ?
                (viewModel.isResetingDeviceWithReconnect ? .resetWithNtrip : .reset) :
                .configuration
        ) {
            NavigationView {
                if !viewModel.isConfiguringDevice {
                    ScrollView (showsIndicators: false) {
                        OnlineSoftwareUpdateSubview(viewModel)
                        if !viewModel.isConnectedDevice && !viewModel.isFlashingDevice {
                            VStack {
                                ConnectToDeviceSubview(viewModel)
                            }
                        } else {
                            if !viewModel.isFlashingDevice {
                                VStack {
                                    DeviceInfoSubview(viewModel)
                                    if !viewModel.rmxIsActive {
                                        HStack {
                                            Text("  NMEA ready status: ").font(Font.headline.bold()).foregroundColor(.black)
                                            if viewModel.isReadyNMEA {
                                                Image(systemName: "network").foregroundColor(.green)
                                            } else {
                                                ProgressView()
                                            }
                                            Spacer()
                                        }
                                        if viewModel.isReadyNMEA {
                                            NMEASubview(viewModel)
                                            VStack {
                                                HStack {
                                                    SelectButton(
                                                        isSelected: $useNTRIP,
                                                        color: .green,
                                                        text: "NTRIP"
                                                    ).onTapGesture {
                                                        useNTRIP = true
                                                        usePPS = false
                                                    }
                                                    SelectButton(
                                                        isSelected: $usePPS,
                                                        color: .green,
                                                        text: "Point Perfect (in dev)"
                                                    ).onTapGesture {
                                                        /*
                                                         useNTRIP = false
                                                         usePPS = true
                                                         */
                                                    }
                                                }
                                                if useNTRIP {
                                                    NTRIPControlSubview(viewModel)
                                                }
                                            }
                                        }
                                        LaserMeasurementsSubview(viewModel)
                                    }
                                }
                                if viewModel.isStartingNtrip {
                                    SinglePointSubview(viewModel)
                                }
                                PPKMeasurementsSubview(viewModel)
                                DeviceConfigSubview(viewModel)
                            }
                        }
                    }.toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Submit") { hideKeyboard() }.foregroundColor(.black)
                        }
                    }.alert(
                        Text(viewModel.titleAlert),
                        isPresented: $viewModel.isShowingAlert,
                        actions: { Button { viewModel.isShowingAlert.toggle() } label: { Text("OK") } }
                    ) { Text(viewModel.messageAlert) }.alertButtonTint(color: .black)
                }
            }.padding(10)
        }.preferredColorScheme(.light)
    }
}
