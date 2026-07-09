//
//  NtripQuickCardSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI

struct NtripQuickCardSubview: View {

    @ObservedObject private var viewModel: NtripToolsViewModel
    @State private var showMountPoints = false
    @State private var showSavedServers = false

    init(viewModel: NtripToolsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ClientCard(
            title: "NTRIP Correction",
            subtitle: nil
        ) {
            HStack {
                ClientBadge(
                    text: viewModel.canConnectToNtrip ? "GGA Ready" : "Waiting for GGA",
                    color: viewModel.canConnectToNtrip ? .green : .orange
                )
                Spacer()
            }

            if !viewModel.ntripCredentials.isEmpty {
                Button {
                    showSavedServers = true
                } label: {
                    HStack {
                        Image(systemName: "server.rack")
                        Text("Saved servers")
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(ClientTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ClientTheme.subtleFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ClientTheme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            ClientFloatingTextField(title: "Caster hostname", text: $viewModel.hostname)
            ClientFloatingTextField(title: "Port", text: $viewModel.port, keyboardType: .numberPad)
            ClientFloatingTextField(title: "Username", text: $viewModel.username)
            ClientFloatingTextField(title: "Password", text: $viewModel.password, isSecure: true)
            ClientFloatingTextField(title: "Mount point", text: $viewModel.mountPoint)

            Toggle(isOn: $viewModel.forceHTTPSMountpointsConnection) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Force HTTPS for mount points")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)
                    Text("Use https:// when loading caster mount points.")
                        .font(.caption)
                        .foregroundStyle(ClientTheme.textSecondary)
                }
            }
            .tint(.green)

            Toggle(isOn: $viewModel.forceHTTPSconnection) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Force HTTPS for NTRIP")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)
                    Text("Use https:// and TLS for the actual NTRIP correction stream.")
                        .font(.caption)
                        .foregroundStyle(ClientTheme.textSecondary)
                }
            }
            .tint(.green)

            if !viewModel.hostname.isEmpty && !viewModel.port.isEmpty {
                Button {
                    viewModel.getMountpoints()
                    showMountPoints = true
                } label: {
                    Text("Load mount points automatically")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)
                }
                .buttonStyle(.bordered)
            }


            ClientActionGrid(minimumWidth: 140) {
                Button {
                    if viewModel.isStartingNtrip {
                        viewModel.reconnectToNTRIP()
                    } else {
                        viewModel.connectToNTRIP()
                    }
                } label: {
                    Text(viewModel.isStartingNtrip ? "Reconnect" : "Connect")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!viewModel.hasConnectionFields)

                Button {
                    viewModel.disconnectNtrip()
                } label: {
                    Text("Disconnect")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isStartingNtrip)
            }

            Button {
                viewModel.reconnectToNTRIPWithReset()
            } label: {
                Text("Reconnect NTRIP with Reset")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.hasConnectionFields)

            ClientStatusRow(title: "Status", value: viewModel.ntripStatus)

            if viewModel.isStartingNtrip || !viewModel.ntripSizeParcel.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Incoming NTRIP packets")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)

                    NtripPacketLogBox(
                        entries: viewModel.ntripPacketLogEntries,
                        placeholder: "Waiting for NTRIP packets...",
                        minHeight: 96,
                        maxHeight: 140
                    )
                }
            }
        }
        .confirmationDialog(
            "Saved servers",
            isPresented: $showSavedServers,
            titleVisibility: .visible
        ) {
            ForEach(viewModel.ntripCredentials, id: \.self) { current in
                Button(savedServerTitle(for: current)) {
                    viewModel.applySavedServer(current)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showMountPoints, onDismiss: {
            viewModel.cancelMountpointsLoading()
        }) {
            NavigationView {
                MountPointsSubview(data: viewModel.mountPointsData)
                    .action { currentValue in
                        viewModel.selectMountPoint(currentValue)
                        viewModel.cancelMountpointsLoading()
                        showMountPoints = false
                    }
                    .dissmiss {
                        viewModel.cancelMountpointsLoading()
                        showMountPoints = false
                    }
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
        }
    }

    private func savedServerTitle(for current: NtripCredentials) -> String {
        let flags = [
            current.forceHTTPSMountpointsConnection ? "Mounts HTTPS" : nil,
            current.forceHTTPSconnection ? "NTRIP HTTPS" : nil
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        guard !flags.isEmpty else {
            return current.host
        }

        return "\(current.host) (\(flags))"
    }
}

private struct NtripPacketLogBox: View {

    let entries: [NtripPacketLogEntry]
    let placeholder: String
    var minHeight: CGFloat = 96
    var maxHeight: CGFloat = 140

    private var latestEntryID: Int {
        entries.last?.id ?? 0
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if entries.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ClientTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(entries) { entry in
                            Text(entry.displayText)
                                .id(entry.id)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(ClientTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(Constants.bottomAnchorID)
                    }
                }
                .padding(10)
            }
            .onAppear {
                scrollToBottom(with: proxy, animated: false)
            }
            .onChange(of: latestEntryID) { _ in
                scrollToBottom(with: proxy, animated: true)
            }
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .background(ClientTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func scrollToBottom(with proxy: ScrollViewProxy, animated: Bool) {
        guard !entries.isEmpty else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(Constants.bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(Constants.bottomAnchorID, anchor: .bottom)
        }
    }

    private enum Constants {
        static let bottomAnchorID = "ntrip-packet-log-bottom"
    }
}
