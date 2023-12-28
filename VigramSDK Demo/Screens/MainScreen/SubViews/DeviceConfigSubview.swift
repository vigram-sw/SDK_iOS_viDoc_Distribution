//
//  DeviceConfigSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 18.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct DeviceConfigSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showNavdop = false
    @State private var showDynamicState = false
    @State private var showGNSS = false
    @State private var showElevation = false
    @State private var showRate = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            Text("Other parameters").font(Font.headline.bold())
            
            Button { self.showDynamicState.toggle() } label: {
                if showDynamicState {
                    Text("Hide dynamic state")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.up").foregroundColor(.black)
                } else {
                    Text("Show dynamic state")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down").foregroundColor(.black)
                }
            }.buttonStyle(.bordered)
            if showDynamicState {
                VStack {
                    Text("Dynamic state info").font(Font.headline.bold())
                    Text("\(viewModel.dynamicState)")
                    Button("Get current dynamic state", action: {viewModel.getDynamicState()}).buttonStyle(.bordered)
                }
                VStack {
                    Text("Set dynamic state of viDoc").font(Font.headline.bold())
                    Text("RAM only").font(Font.headline.bold())
                    HStack {
                        Button("Pedestrian", action: {viewModel.setDynamicState(type: .pedestrian)}).buttonStyle(.bordered)
                        Button("Stationary", action: {viewModel.setDynamicState(type: .stationary)}).buttonStyle(.bordered)
                    }
                }
            }
            Button { self.showNavdop.toggle() } label: {
                if showNavdop {
                    Text("Hide NAV-DOP/PVT Control")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.up").foregroundColor(.black)
                } else {
                    Text("Show NAV-DOP/PVT Control")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down").foregroundColor(.black)
                }
            }.buttonStyle(.bordered)
            
            if showNavdop {
                VStack {
                    Text("NAVDOP").font(Font.headline.bold())
                    HStack {
                        Button("Enable", action: { viewModel.changeStatusNAVDOP(activate: true)}).buttonStyle(.bordered)
                        Button("Disable", action: { viewModel.changeStatusNAVDOP(activate: false)}).buttonStyle(.bordered)
                    }
                    Text("NAVPVT").font(Font.headline.bold())
                    HStack {
                        Button("Enable", action: { viewModel.changeStatusNAVPVT(activate: true)}).buttonStyle(.bordered)
                        Button("Disable", action: { viewModel.changeStatusNAVPVT(activate: false)}).buttonStyle(.bordered)
                    }
                }
            }
        }
        VStack {
            Button { self.showGNSS.toggle() } label: {
                if showGNSS {
                    Text("Hide Constellation info")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.up").foregroundColor(.black)
                } else {
                    Text("Show Constellation info")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down").foregroundColor(.black)
                }
            }.buttonStyle(.bordered)
            if showGNSS {
                VStack {
                    Text("GNSS Constellation info").font(Font.headline.bold())
                    VStack {
                        Text("Satellite: \(viewModel.satelliteGNSS)")
                        Text("Status: \(viewModel.satelliteStatusGNSS)")
                    }
                    VStack {
                        HStack {
                            Button("Status GPS",action: { viewModel.getCurrentStatusGNSS(satellite: .gps)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("Status Glonass",action: { viewModel.getCurrentStatusGNSS(satellite: .glonass)}).buttonStyle(.bordered)
                            Button("Enable", action: { viewModel.changeStatusGNSS(satellite: .glonass, activate: true)}).buttonStyle(.bordered)
                            Button("Disable", action: { viewModel.changeStatusGNSS(satellite: .glonass, activate: false)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("Status BeiDou",action: { viewModel.getCurrentStatusGNSS(satellite: .beidou)}).buttonStyle(.bordered)
                            Button("Enable", action: { viewModel.changeStatusGNSS(satellite: .beidou, activate: true)}).buttonStyle(.bordered)
                            Button("Disable", action: { viewModel.changeStatusGNSS(satellite: .beidou, activate: false)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("Status Galileo",action: { viewModel.getCurrentStatusGNSS(satellite: .galileo)}).buttonStyle(.bordered)
                            Button("Enable", action: { viewModel.changeStatusGNSS(satellite: .galileo, activate: true)}).buttonStyle(.bordered)
                            Button("Disable", action: { viewModel.changeStatusGNSS(satellite: .galileo, activate: false)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("Status QZSS",action: { viewModel.getCurrentStatusGNSS(satellite: .qzss)}).buttonStyle(.bordered)
                            Button("Enable", action: { viewModel.changeStatusGNSS(satellite: .qzss, activate: true)}).buttonStyle(.bordered)
                            Button("Disable", action: { viewModel.changeStatusGNSS(satellite: .qzss, activate: false)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("Status SBAS",action: { viewModel.getCurrentStatusGNSS(satellite: .sbas)}).buttonStyle(.bordered)
                            Button("Enable", action: { viewModel.changeStatusGNSS(satellite: .sbas, activate: true)}).buttonStyle(.bordered)
                            Button("Disable", action: { viewModel.changeStatusGNSS(satellite: .sbas, activate: false)}).buttonStyle(.bordered)
                        }
                        Button("Activate all constellation GNSS", action: { viewModel.activateAllConstellationGNSS()}).buttonStyle(.bordered)
                    }
                }
            }
            VStack {
                Button { self.showElevation.toggle() } label: {
                    if showElevation {
                        Text("Hide Elevation info")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Show Elevation info")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }.buttonStyle(.bordered)
                if showElevation {
                    VStack {
                        Text("Elevation info").font(Font.headline.bold())
                        Text("Current minimum elevation = \(viewModel.elevation)")
                        Button("Get current minimum elevation", action: { viewModel.getCurrentMinimumElevation()}).buttonStyle(.bordered)
                    }
                    VStack {
                        Text("Set minimum elevation").font(Font.headline.bold())
                        HStack {
                            Button("00°", action: {viewModel.setMinimumElevation(angle: .ang0)}).buttonStyle(.bordered)
                            Button("15°", action: {viewModel.setMinimumElevation(angle: .ang15)}).buttonStyle(.bordered)
                            Button("30°", action: {viewModel.setMinimumElevation(angle: .ang30)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("05°", action: {viewModel.setMinimumElevation(angle: .ang5)}).buttonStyle(.bordered)
                            Button("20°", action: {viewModel.setMinimumElevation(angle: .ang20)}).buttonStyle(.bordered)
                            Button("35°", action: {viewModel.setMinimumElevation(angle: .ang35)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("10°", action: {viewModel.setMinimumElevation(angle: .ang10)}).buttonStyle(.bordered)
                            Button("25°", action: {viewModel.setMinimumElevation(angle: .ang25)}).buttonStyle(.bordered)
                            Button("40°", action: {viewModel.setMinimumElevation(angle: .ang40)}).buttonStyle(.bordered)
                        }
                    }
                }
            }
            VStack {
                Button { self.showRate.toggle() } label: {
                    if showRate {
                        Text("Hide Rate Control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Show Rate Control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }.buttonStyle(.bordered)
                if showRate {
                    VStack {
                        Text("Changing rate info").font(Font.headline.bold())
                        HStack {
                            Text("  Current rate: ").font(Font.headline.bold())
                            Text(viewModel.currentRate)
                        }
                        Button("Get current changing rate", action: { viewModel.getChangingRateOfMessages()}).buttonStyle(.bordered)
                    }
                    VStack {
                        Text("Set changing Rate of message").font(Font.headline.bold())
                        Text("RAM only").font(Font.headline.bold())
                        Button("7Hz (Default)", action: {viewModel.setChangingRateOfMessages(.hertz7)}).buttonStyle(.bordered)
                        
                        HStack {
                            Button("1Hz", action: {viewModel.setChangingRateOfMessages(.hertz1)}).buttonStyle(.bordered)
                            Button("4Hz", action: {viewModel.setChangingRateOfMessages(.hertz4)}).buttonStyle(.bordered)
                            Button("8Hz", action: {viewModel.setChangingRateOfMessages(.hertz8)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("2Hz", action: {viewModel.setChangingRateOfMessages(.hertz2)}).buttonStyle(.bordered)
                            Button("5Hz", action: {viewModel.setChangingRateOfMessages(.hertz5)}).buttonStyle(.bordered)
                            Button("9Hz", action: {viewModel.setChangingRateOfMessages(.hertz9)}).buttonStyle(.bordered)
                        }
                        HStack {
                            Button("3Hz", action: {viewModel.setChangingRateOfMessages(.hertz3)}).buttonStyle(.bordered)
                            Button("6Hz", action: {viewModel.setChangingRateOfMessages(.hertz6)}).buttonStyle(.bordered)
                            Button("10Hz", action: {viewModel.setChangingRateOfMessages(.hertz10)}).buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }
}
