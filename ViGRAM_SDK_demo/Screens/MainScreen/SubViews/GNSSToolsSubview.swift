//
//  GNSSToolsSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI
import VigramSDK

struct GNSSToolsSubview: View {

    @ObservedObject var viewModel: GNSSToolsViewModel
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 16) {
            ClientCard(
                title: "Device Settings",
                subtitle: "Advanced receiver settings. Leave defaults unless you know exactly what you need."
            ) {
                Text("Dynamic state")
                    .font(.headline.bold())
                ClientStatusRow(title: "Current", value: normalized(viewModel.dynamicState))
                ClientActionGrid(minimumWidth: 120) {
                    Button("Refresh") {
                        viewModel.getDynamicState()
                    }
                    .buttonStyle(.bordered)

                    Button("Pedestrian") {
                        viewModel.setDynamicState(type: .pedestrian)
                    }
                    .buttonStyle(.bordered)

                    Button("Stationary") {
                        viewModel.setDynamicState(type: .stationary)
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                Text("Minimum elevation")
                    .font(.headline.bold())
                ClientStatusRow(title: "Current", value: normalized(viewModel.elevation))
                Button("Refresh") {
                    viewModel.getCurrentMinimumElevation()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 8) {
                    Button("0°") { viewModel.setMinimumElevation(angle: .ang0) }.buttonStyle(.bordered)
                    Button("5°") { viewModel.setMinimumElevation(angle: .ang5) }.buttonStyle(.bordered)
                    Button("10°") { viewModel.setMinimumElevation(angle: .ang10) }.buttonStyle(.bordered)
                    Button("15°") { viewModel.setMinimumElevation(angle: .ang15) }.buttonStyle(.bordered)
                    Button("20°") { viewModel.setMinimumElevation(angle: .ang20) }.buttonStyle(.bordered)
                    Button("25°") { viewModel.setMinimumElevation(angle: .ang25) }.buttonStyle(.bordered)
                    Button("30°") { viewModel.setMinimumElevation(angle: .ang30) }.buttonStyle(.bordered)
                    Button("35°") { viewModel.setMinimumElevation(angle: .ang35) }.buttonStyle(.bordered)
                    Button("40°") { viewModel.setMinimumElevation(angle: .ang40) }.buttonStyle(.bordered)
                }

                Divider()

                Text("Message rate")
                    .font(.headline.bold())
                ClientStatusRow(title: "Current", value: normalized(viewModel.currentRate))
                Button("Refresh") {
                    viewModel.getChangingRateOfMessages()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 8) {
                    Button("1 Hz") { viewModel.setChangingRateOfMessages(.hertz1) }.buttonStyle(.bordered)
                    Button("2 Hz") { viewModel.setChangingRateOfMessages(.hertz2) }.buttonStyle(.bordered)
                    Button("3 Hz") { viewModel.setChangingRateOfMessages(.hertz3) }.buttonStyle(.bordered)
                    Button("4 Hz") { viewModel.setChangingRateOfMessages(.hertz4) }.buttonStyle(.bordered)
                    Button("5 Hz") { viewModel.setChangingRateOfMessages(.hertz5) }.buttonStyle(.bordered)
                    Button("6 Hz") { viewModel.setChangingRateOfMessages(.hertz6) }.buttonStyle(.bordered)
                    Button("7 Hz") { viewModel.setChangingRateOfMessages(.hertz7) }.buttonStyle(.bordered)
                    Button("8 Hz") { viewModel.setChangingRateOfMessages(.hertz8) }.buttonStyle(.bordered)
                    Button("9 Hz") { viewModel.setChangingRateOfMessages(.hertz9) }.buttonStyle(.bordered)
                    Button("10 Hz") { viewModel.setChangingRateOfMessages(.hertz10) }.buttonStyle(.bordered)
                    Button("15 Hz") { viewModel.setChangingRateOfMessages(.hertz15) }.buttonStyle(.bordered)
                }

            }

            ClientCard(
                title: "GNSS Receiver Settings",
                subtitle: "Advanced receiver output and constellation controls."
            ) {
                DisclosureGroup("Receiver message output") {
                    VStack(alignment: .leading, spacing: 10) {
                        ClientOptionalStatusRow(title: "Last constellation query", value: viewModel.satelliteGNSS)
                        ClientOptionalStatusRow(title: "Last reported status", value: viewModel.satelliteStatusGNSS)


                        ClientActionGrid(minimumWidth: 160) {
                            Button("Enable NAV-DOP") {
                                viewModel.changeStatusNAVDOP(activate: true)
                            }
                            .buttonStyle(.bordered)

                            Button("Disable NAV-DOP") {
                                viewModel.changeStatusNAVDOP(activate: false)
                            }
                            .buttonStyle(.bordered)
                        }

                        ClientActionGrid(minimumWidth: 160) {
                            Button("Enable NAV-PVT") {
                                viewModel.changeStatusNAVPVT(activate: true)
                            }
                            .buttonStyle(.bordered)

                            Button("Disable NAV-PVT") {
                                viewModel.changeStatusNAVPVT(activate: false)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 8)
                }

                DisclosureGroup("Constellations") {
                    VStack(alignment: .leading, spacing: 12) {
                        constellationRow(title: "GPS", type: .gps)
                        constellationRow(title: "GLONASS", type: .glonass)
                        constellationRow(title: "BeiDou", type: .beidou)
                        constellationRow(title: "Galileo", type: .galileo)
                        constellationRow(title: "QZSS", type: .qzss)
                        constellationRow(title: "SBAS", type: .sbas)

                        Button("Activate all constellations") {
                            viewModel.activateAllConstellationGNSS()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    @ViewBuilder
    private func constellationRow(title: String, type: NavigationSystemType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(ClientTheme.textPrimary)

            ClientActionGrid(minimumWidth: 100) {
                Button("Status") {
                    viewModel.getCurrentStatusGNSS(satellite: type)
                }
                .buttonStyle(.bordered)

                Button("Enable") {
                    viewModel.changeStatusGNSS(satellite: type, activate: true)
                }
                .buttonStyle(.bordered)

                Button("Disable") {
                    viewModel.changeStatusGNSS(satellite: type, activate: false)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func normalized(_ value: String) -> String {
        value.isEmpty ? "Not loaded yet" : value
    }
}
