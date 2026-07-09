//
//  ConnectedDeviceOverviewSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI
import CoreBluetooth
import VigramSDK

struct ConnectedDeviceOverviewSubview: View {

    @ObservedObject var viewModel: DeviceSessionViewModel
    @ObservedObject var gnssToolsViewModel: GNSSToolsViewModel
    @ObservedObject var ntripViewModel: NtripToolsViewModel

    var body: some View {
        VStack(spacing: 16) {
            ClientConnectedDeviceCard(viewModel: viewModel, ntripViewModel: ntripViewModel)
            ClientDeviceDetailsCard(viewModel: viewModel)

            if viewModel.isReadyNMEA {
                ClientLocationSummaryCard(viewModel: viewModel)
                ClientGNSSDetailsCard(viewModel: viewModel, gnssToolsViewModel: gnssToolsViewModel)
            } else {
                ClientWaitingForGNSSCard(viewModel: viewModel, gnssToolsViewModel: gnssToolsViewModel)
            }
        }
    }
}

private struct ClientConnectedDeviceCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel
    @ObservedObject var ntripViewModel: NtripToolsViewModel

    var body: some View {
        ClientCard(
            title: "Device Status",
            subtitle: nil
        ) {
            HStack(spacing: 8) {
                ClientBadge(
                    text: viewModel.isReadyNMEA ? "GNSS Ready" : "Waiting for GNSS",
                    color: viewModel.isReadyNMEA ? .green : .orange
                )
                ClientBadge(
                    text: ntripViewModel.isStartingNtrip ? "NTRIP Active" : "NTRIP Off",
                    color: ntripViewModel.isStartingNtrip ? .green : .gray
                )
                Spacer()
            }

            ClientStatusRow(title: "Device", value: viewModel.currentDeviceName)
            ClientStatusRow(title: "Battery", value: viewModel.currentDeviceCharge)
            ClientIconStatusRow(
                title: "Bluetooth state",
                systemName: "wave.3.right",
                color: peripheralStateColor,
                isLoading: isPeripheralStateLoading
            )
            ClientIconStatusRow(
                title: "Device connection",
                systemName: "personalhotspot",
                color: viewModel.isConnectedDevice ? .green : .red
            )
            ClientIconStatusRow(
                title: "Startup state",
                systemName: "bolt.horizontal.fill",
                color: viewModel.isStartDevice ? .green : .red
            )

            Button(role: .destructive) {
                viewModel.disconnect()
            } label: {
                Text("Disconnect")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private var isPeripheralStateLoading: Bool {
        switch viewModel.periphiralState {
        case .connecting, .disconnecting:
            return true
        case .connected, .disconnected:
            return false
        @unknown default:
            return false
        }
    }

    private var peripheralStateColor: Color {
        switch viewModel.periphiralState {
        case .connected:
            return .green
        case .connecting, .disconnecting:
            return .orange
        case .disconnected:
            return .red
        @unknown default:
            return .gray
        }
    }
}

private struct ClientIconStatusRow: View {

    let title: String
    let systemName: String
    let color: Color
    var isLoading = false

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(ClientTheme.textPrimary)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: systemName)
                    .foregroundStyle(color)
            }

            Spacer()
        }
    }
}

private struct ClientDeviceDetailsCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel

    var body: some View {
        ClientCard(
            title: "Device Details",
            subtitle: nil
        ) {
            ClientStatusRow(title: "SDK version", value: Configuration.sdkVersion)
            ClientStatusRow(title: "Current device type", value: viewModel.currentDevice)
            ClientStatusRow(title: "Protocol", value: protocolVersionText)
            ClientStatusRow(title: "Has front laser", value: yesNo(viewModel.currentDeviceHasFrontLaser))
            ClientStatusRow(title: "Has bottom laser", value: yesNo(viewModel.currentDeviceHasBottomLaser))
            ClientStatusRow(title: "Has IMU", value: yesNo(viewModel.currentDeviceHasIMU))
            ClientOptionalStatusRow(title: "Housing", value: viewModel.currentDeviceHousing)
            ClientOptionalStatusRow(title: "Mount", value: viewModel.currentDeviceMountDevice)
            ClientOptionalStatusRow(title: "HW Ref", value: viewModel.currentVigramRef)
            ClientOptionalStatusRow(title: "HW Bat", value: viewModel.currentVigramBat)
            ClientOptionalStatusRow(title: "HW M88 Laser", value: viewModel.currentM88Laser)
            ClientOptionalStatusRow(title: "HW L81 Laser", value: viewModel.currentL81Laser)
            ClientOptionalStatusRow(title: "IMU", value: viewModel.currentIMU)
        }
    }

    private var protocolVersionText: String {
        guard let protocolVersion = viewModel.protocolVersion else {
            return ""
        }
        return String(format: "%.1f", protocolVersion)
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }
}

private struct ClientWaitingForGNSSCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel
    @ObservedObject var gnssToolsViewModel: GNSSToolsViewModel

    var body: some View {
        ClientCard(
            title: "GNSS Status",
            subtitle: subtitle
        ) {
            ClientStatusRow(title: "Current time", value: viewModel.currentTimeString)
            ClientOptionalStatusRow(title: "UTC time", value: viewModel.unixTimeString)
            ClientStatusRow(title: "GNSS time", value: viewModel.gnssTimeString)
            ClientStatusRow(title: "Satellites", value: viewModel.countSatellite)
            ClientStatusRow(title: "RTK status", value: viewModel.rtkStatus)
            ClientOptionalStatusRow(title: "HDOP", value: viewModel.hdop)
            ClientOptionalStatusRow(title: "TDOP", value: viewModel.tdop)
            ClientOptionalStatusRow(title: "GDOP", value: viewModel.gdop)
            ClientOptionalStatusRow(title: "North velocity", value: viewModel.nVelocity)
            ClientOptionalStatusRow(title: "East velocity", value: viewModel.eVelocity)
            ClientOptionalStatusRow(title: "Down velocity", value: viewModel.dVelocity)
            ClientOptionalStatusRow(title: "Elevation mode", value: gnssToolsViewModel.elevation)
        }
    }

    private var subtitle: String? {
        nil
    }
}

private struct ClientLocationSummaryCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel

    var body: some View {
        ClientCard(
            title: "Position",
            subtitle: nil
        ) {
            HStack {
                ClientBadge(
                    text: viewModel.rtkStatus.isEmpty ? "No Fix Yet" : viewModel.rtkStatus,
                    color: viewModel.rtkStatus.contains("Fixed") ? .green : .orange
                )
                Spacer()
            }

            ClientStatusRow(title: "Latitude", value: viewModel.latitude)
            ClientStatusRow(title: "Longitude", value: viewModel.longitude)
            ClientStatusRow(title: "Horizontal accuracy", value: viewModel.horAcc)
            ClientStatusRow(title: "Vertical accuracy", value: viewModel.vertAcc)
            ClientStatusRow(title: "Correction age", value: viewModel.correction)
        }
    }
}

private struct ClientGNSSDetailsCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel
    @ObservedObject var gnssToolsViewModel: GNSSToolsViewModel

    var body: some View {
        ClientCard(
            title: "GNSS Details",
            subtitle: nil
        ) {
            ClientStatusRow(title: "Current time", value: viewModel.currentTimeString)
            ClientOptionalStatusRow(title: "UTC time", value: viewModel.unixTimeString)
            ClientStatusRow(title: "GNSS time", value: viewModel.gnssTimeString)
            ClientStatusRow(title: "Satellites", value: viewModel.countSatellite)
            ClientStatusRow(title: "RTK status", value: viewModel.rtkStatus)
            ClientStatusRow(title: "PDOP", value: viewModel.pdop)
            ClientOptionalStatusRow(title: "HDOP", value: viewModel.hdop)
            ClientOptionalStatusRow(title: "VDOP", value: viewModel.vdop)
            ClientOptionalStatusRow(title: "TDOP", value: viewModel.tdop)
            ClientOptionalStatusRow(title: "GDOP", value: viewModel.gdop)
            ClientOptionalStatusRow(title: "Latitude error", value: viewModel.latAccErr)
            ClientOptionalStatusRow(title: "Longitude error", value: viewModel.lonAccErr)
            ClientOptionalStatusRow(title: "North velocity", value: viewModel.nVelocity)
            ClientOptionalStatusRow(title: "East velocity", value: viewModel.eVelocity)
            ClientOptionalStatusRow(title: "Down velocity", value: viewModel.dVelocity)
            ClientOptionalStatusRow(title: "Elevation mode", value: gnssToolsViewModel.elevation)
        }
    }
}
