//
//  MainScreenView.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI
import UIKit
import VigramSDK

struct MainScreenView: View {

    @StateObject private var viewModel: MainScreenViewModel
    @StateObject private var deviceSessionViewModel: DeviceSessionViewModel
    @StateObject private var ntripViewModel: NtripToolsViewModel
    @StateObject private var supportLogViewModel: SupportLogToolsViewModel
    @StateObject private var serviceToolsViewModel: ServiceToolsViewModel
    @StateObject private var gnssToolsViewModel: GNSSToolsViewModel
    @StateObject private var laserViewModel: LaserToolsViewModel
    @StateObject private var singlePointViewModel: SinglePointToolsViewModel
    @StateObject private var correctionToolsViewModel: CorrectionToolsViewModel

    init(vigramHelper: VigramHelper) {
        let mainViewModel = MainScreenViewModel(vigramHelper: vigramHelper)
        _viewModel = StateObject(wrappedValue: mainViewModel)
        _deviceSessionViewModel = StateObject(wrappedValue: mainViewModel.deviceSession)
        _ntripViewModel = StateObject(wrappedValue: mainViewModel.ntripTools)
        _supportLogViewModel = StateObject(wrappedValue: mainViewModel.supportLogTools)
        _serviceToolsViewModel = StateObject(wrappedValue: mainViewModel.serviceTools)
        _gnssToolsViewModel = StateObject(wrappedValue: mainViewModel.gnssTools)
        _laserViewModel = StateObject(wrappedValue: mainViewModel.laserTools)
        _singlePointViewModel = StateObject(wrappedValue: mainViewModel.singlePointTools)
        _correctionToolsViewModel = StateObject(wrappedValue: mainViewModel.correctionTools)
    }

    var body: some View {
        LoadingView(
            isShowing: $deviceSessionViewModel.isConfiguringDevice,
            message: deviceSessionViewModel.message
        ) {
            NavigationView {
                ZStack {
                    ClientTheme.screenBackground
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            mainContent
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("viDoc Demo")
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Submit") { hideKeyboard() }
                            .foregroundStyle(ClientTheme.textPrimary)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: advancedToolsDestination
                        ) {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(ClientTheme.textPrimary)
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .tint(ClientTheme.textPrimary)
        }
        .sheet(isPresented: $supportLogViewModel.isSharePresented, onDismiss: {
            supportLogViewModel.clearSharedItems()
        }, content: {
            ActivityViewController(activityItems: supportLogViewModel.shareItems)
        })
        .alert(
            Text(viewModel.titleAlert),
            isPresented: $viewModel.isShowingAlert,
            actions: {
                Button {
                    viewModel.isShowingAlert.toggle()
                } label: {
                    Text("OK")
                }
            }
        ) {
            Text(viewModel.messageAlert)
        }
        .alertButtonTint(color: ClientTheme.textPrimary)
    }

    @ViewBuilder
    private var advancedToolsDestination: some View {
        AdvancedToolsView(
            deviceSessionViewModel,
            supportLogViewModel: supportLogViewModel,
            serviceToolsViewModel: serviceToolsViewModel,
            gnssToolsViewModel: gnssToolsViewModel,
            correctionToolsViewModel: correctionToolsViewModel
        )
    }

    @ViewBuilder
    private var mainContent: some View {
        if deviceSessionViewModel.isConnectedDevice {
            ConnectedDeviceOverviewSubview(
                viewModel: deviceSessionViewModel,
                gnssToolsViewModel: gnssToolsViewModel,
                ntripViewModel: ntripViewModel
            )
            NtripQuickCardSubview(viewModel: ntripViewModel)
            LaserMeasurementsSubview(
                viewModel: deviceSessionViewModel,
                laserViewModel: laserViewModel
            )
            SinglePointMeasurementSubview(
                viewModel: deviceSessionViewModel,
                laserViewModel: laserViewModel,
                singlePointViewModel: singlePointViewModel,
                ntripViewModel: ntripViewModel
            )
        } else {
            ConnectionLandingSubview(viewModel: deviceSessionViewModel)
        }
    }
}

struct ClientCard<Content: View>: View {

    let title: String
    let subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(ClientTheme.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ClientTheme.textSecondary)
            }

            content
                .foregroundStyle(ClientTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ClientTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ClientTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: ClientTheme.shadow, radius: 12, x: 0, y: 4)
    }
}

struct ClientStatusRow: View {

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(ClientTheme.textPrimary)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundStyle(ClientTheme.textPrimary)
            Spacer()
        }
    }
}

struct ClientOptionalStatusRow: View {

    let title: String
    let value: String

    private var normalizedValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !normalizedValue.isEmpty {
            ClientStatusRow(title: title, value: normalizedValue)
        }
    }
}

struct ClientBadge: View {

    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.caption.bold())
                .foregroundStyle(ClientTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14))
        .overlay(
            Capsule()
                .stroke(color.opacity(0.28), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct ClientFloatingTextField: View {

    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure = false
    @State private var isSecureTextVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !text.isEmpty {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(ClientTheme.textSecondary)
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 8) {
                Group {
                    if isSecure && !isSecureTextVisible {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                }
                .keyboardType(keyboardType)
                .font(.body)
                .foregroundStyle(ClientTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

                if isSecure {
                    Button {
                        isSecureTextVisible.toggle()
                    } label: {
                        Image(systemName: isSecureTextVisible ? "eye.slash" : "eye")
                            .foregroundStyle(ClientTheme.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ClientTheme.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(text.isEmpty ? ClientTheme.border : ClientTheme.activeBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .animation(.easeInOut(duration: 0.16), value: text.isEmpty)
    }
}

struct ClientActionGrid<Content: View>: View {

    private let columns: [GridItem]
    @ViewBuilder private var content: Content

    init(minimumWidth: CGFloat = 130, @ViewBuilder content: () -> Content) {
        columns = [GridItem(.adaptive(minimum: minimumWidth), spacing: 8, alignment: .leading)]
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            content
        }
    }
}

struct ClientLogBox: View {

    let text: String
    let placeholder: String
    var minHeight: CGFloat = 120
    var maxHeight: CGFloat = 180

    private var displayText: String {
        text.isEmpty ? placeholder : text
    }

    var body: some View {
        ScrollView {
            Text(displayText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ClientTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .textSelection(.enabled)
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .background(ClientTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AdvancedToolsView: View {

    @ObservedObject private var viewModel: DeviceSessionViewModel
    @ObservedObject private var supportLogViewModel: SupportLogToolsViewModel
    @ObservedObject private var serviceToolsViewModel: ServiceToolsViewModel
    @ObservedObject private var gnssToolsViewModel: GNSSToolsViewModel
    @ObservedObject private var correctionToolsViewModel: CorrectionToolsViewModel

    init(
        _ viewModel: DeviceSessionViewModel,
        supportLogViewModel: SupportLogToolsViewModel,
        serviceToolsViewModel: ServiceToolsViewModel,
        gnssToolsViewModel: GNSSToolsViewModel,
        correctionToolsViewModel: CorrectionToolsViewModel
    ) {
        self.viewModel = viewModel
        self.supportLogViewModel = supportLogViewModel
        self.serviceToolsViewModel = serviceToolsViewModel
        self.gnssToolsViewModel = gnssToolsViewModel
        self.correctionToolsViewModel = correctionToolsViewModel
    }

    var body: some View {
        ZStack {
            ClientTheme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    SupportLogSettingsView(viewModel: supportLogViewModel)

                    if canShowConnectedTools {
                        GNSSToolsSubview(viewModel: gnssToolsViewModel)
                        PPKMeasurementsSubview(viewModel: correctionToolsViewModel)
                        ServiceToolsSubview(viewModel: serviceToolsViewModel)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Settings")
    }

    private var canShowConnectedTools: Bool {
        viewModel.isConnectedDevice
    }
}

private struct SupportLogSettingsView: View {

    @ObservedObject var viewModel: SupportLogToolsViewModel

    var body: some View {
        ClientCard(
            title: "Support Logs",
            subtitle: "Basic support log is always on. Turn on diagnostic logging only if support asks for a deeper trace."
        ) {
            Text("Basic support log")
                .font(.headline.bold())
            ClientStatusRow(title: "Status", value: viewModel.supportLogStatus)
            ClientStatusRow(title: "Active file", value: viewModel.supportLogFileName)

            Divider()

            Text("Diagnostic log")
                .font(.headline.bold())
            Picker(
                "Diagnostic log mode",
                selection: Binding(
                    get: { viewModel.diagnosticLogMode },
                    set: { viewModel.updateDiagnosticLogMode($0) }
                )
            ) {
                ForEach(DiagnosticLogModeOption.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Button {
                viewModel.exportSupportLog()
            } label: {
                Text("Export active support log")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClientTheme.textPrimary)
            }
            .buttonStyle(.bordered)
        }
    }
}
