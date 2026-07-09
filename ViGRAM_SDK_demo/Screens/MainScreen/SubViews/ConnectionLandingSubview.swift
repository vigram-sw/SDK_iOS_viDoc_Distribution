//
//  ConnectionLandingSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI

struct ConnectionLandingSubview: View {

    @ObservedObject var viewModel: DeviceSessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            ClientConnectCard(viewModel: viewModel)
        }
    }
}

private struct ClientQuickStartCard: View {

    var body: some View {
        ClientCard(
            title: "Quick Start",
            subtitle: "Most customers only need these four steps."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Turn on viDoc and keep Bluetooth enabled on the phone or tablet.")
                Text("2. Tap the device name below to connect.")
                Text("3. Wait until GNSS becomes ready.")
                Text("4. If your workflow uses RTCM corrections, fill the NTRIP section and tap Connect.")
            }
            .font(.subheadline)
            .foregroundStyle(ClientTheme.textPrimary)
        }
    }
}

private struct ClientConnectCard: View {

    @ObservedObject var viewModel: DeviceSessionViewModel

    var body: some View {
        ClientCard(
            title: "Connect viDoc",
            subtitle: "If the list is empty, wait a few seconds. The app scans nearby devices automatically."
        ) {
            if viewModel.allDeviceNames.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Searching for nearby viDoc devices…")
                        .font(.subheadline)
                        .foregroundStyle(ClientTheme.textSecondary)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.allDeviceNames, id: \.self) { deviceName in
                        Button {
                            viewModel.connectToDevice(name: deviceName)
                        } label: {
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                Text(deviceName)
                                    .font(.headline)
                                Spacer()
                                Text("Connect")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(ClientTheme.textPrimary)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(ClientTheme.subtleFill)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
