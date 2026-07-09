//
//  SinglePointMeasurementSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI

struct SinglePointMeasurementSubview: View {

    @ObservedObject private var viewModel: DeviceSessionViewModel
    @ObservedObject private var laserViewModel: LaserToolsViewModel
    @ObservedObject private var singlePointViewModel: SinglePointToolsViewModel
    @ObservedObject private var ntripViewModel: NtripToolsViewModel
    @State private var showOffsets = false

    init(
        viewModel: DeviceSessionViewModel,
        laserViewModel: LaserToolsViewModel,
        singlePointViewModel: SinglePointToolsViewModel,
        ntripViewModel: NtripToolsViewModel
    ) {
        self.viewModel = viewModel
        self.laserViewModel = laserViewModel
        self.singlePointViewModel = singlePointViewModel
        self.ntripViewModel = ntripViewModel
    }

    var body: some View {
        ClientCard(
            title: "Single Point Measurement",
            subtitle: singlePointReadinessText
        ) {
            HStack {
                ClientBadge(
                    text: ntripViewModel.isStartingNtrip ? "NTRIP Active" : "Needs NTRIP",
                    color: ntripViewModel.isStartingNtrip ? .green : .orange
                )
                ClientBadge(text: selectedModeText, color: .blue)
                Spacer()
            }

            ClientActionGrid(minimumWidth: 120) {
                SelectButton(
                    isSelected: $singlePointViewModel.useMeasurementsWithLaser,
                    color: .green,
                    text: "Use laser"
                )
                .onTapGesture {
                    singlePointViewModel.activateLaserMeasurement(position: laserViewModel.selectedPosition)
                }

                SelectButton(
                    isSelected: $singlePointViewModel.useMeasurementsWithoutLaset,
                    color: .green,
                    text: "Without laser"
                )
                .onTapGesture {
                    singlePointViewModel.activateCameraMeasurement()
                }
            }

            ClientFloatingTextField(
                title: "Duration, seconds",
                text: $viewModel.durationMeasurements,
                keyboardType: .decimalPad
            )

            if singlePointViewModel.useMeasurementsWithoutLaset {
                ClientFloatingTextField(
                    title: "Distance to ground, cm",
                    text: $singlePointViewModel.distanceToGround,
                    keyboardType: .decimalPad
                )
            }

            Button {
                showOffsets.toggle()
                refreshOffsetsForCurrentMode()
            } label: {
                HStack {
                    Text(showOffsets ? "Hide offsets" : "Show offsets")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: showOffsets ? "chevron.up" : "chevron.down")
                }
                .foregroundStyle(ClientTheme.textPrimary)
            }
            .buttonStyle(.bordered)

            if showOffsets {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current offsets")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)

                    ClientStatusRow(title: "Name", value: singlePointViewModel.currentOffsetsString)
                    ClientStatusRow(title: "X", value: format(singlePointViewModel.currentOffsets.x))
                    ClientStatusRow(title: "Y", value: format(singlePointViewModel.currentOffsets.y))
                    ClientStatusRow(title: "Z", value: format(singlePointViewModel.currentOffsets.z))

                    if !singlePointViewModel.currentAllOffsets.isEmpty {
                        Text("Available offsets")
                            .font(.subheadline.bold())
                            .foregroundStyle(ClientTheme.textPrimary)

                        ForEach(singlePointViewModel.currentAllOffsets, id: \.0) { offset in
                            Button(offset.0) {
                                singlePointViewModel.selectOffset(named: offset.0)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Button {
                singlePointViewModel.startMeasurement()
            } label: {
                Text("Start Single Point")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!ntripViewModel.isStartingNtrip)

            if let protocolVersion = viewModel.protocolVersion, protocolVersion > 1 {
                ClientActionGrid(minimumWidth: 120) {
                    Button {
                        singlePointViewModel.stopMeasurement()
                    } label: {
                        Text("Stop")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        singlePointViewModel.cancelMeasurement()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            ClientStatusRow(title: "Status", value: singlePointStatusText)
            ClientStatusRow(title: "Offset", value: singlePointViewModel.currentOffsetsString)

            if let singlePoint = singlePointViewModel.singlePointMeasurement {
                Text("Device parameters")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClientTheme.textPrimary)
                ClientStatusRow(title: "Duration", value: "\(NSInteger(singlePoint.duration) % 60)")
                ClientStatusRow(title: "X", value: format(singlePoint.environmentData.deviceMotion.orientation.x))
                ClientStatusRow(title: "Y", value: format(singlePoint.environmentData.deviceMotion.orientation.y))
                ClientStatusRow(title: "Z", value: format(singlePoint.environmentData.deviceMotion.orientation.z))
                ClientStatusRow(title: "Yaw", value: format(singlePoint.environmentData.deviceMotion.orientation.yaw))
                ClientStatusRow(title: "Pitch", value: format(singlePoint.environmentData.deviceMotion.orientation.pitch))
                ClientStatusRow(title: "Roll", value: format(singlePoint.environmentData.deviceMotion.orientation.roll))

                Text("Coordinate without correction")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClientTheme.textPrimary)
                ClientStatusRow(
                    title: "Latitude",
                    value: format(singlePoint.environmentData.coordinate.latitude)
                )
                ClientStatusRow(
                    title: "Longitude",
                    value: format(singlePoint.environmentData.coordinate.longitude)
                )
                ClientStatusRow(
                    title: "Reference altitude",
                    value: format(singlePoint.environmentData.coordinate.referenceAltitude)
                )
                ClientStatusRow(
                    title: "Geoid separation",
                    value: format(singlePoint.environmentData.coordinate.geoidSeparation)
                )

                Text("Corrected coordinate")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClientTheme.textPrimary)
                ClientStatusRow(
                    title: "Latitude",
                    value: format(singlePoint.environmentData.correctedCoordinate.latitude)
                )
                ClientStatusRow(
                    title: "Longitude",
                    value: format(singlePoint.environmentData.correctedCoordinate.longitude)
                )
                ClientStatusRow(
                    title: "Reference altitude",
                    value: format(singlePoint.environmentData.correctedCoordinate.referenceAltitude)
                )
                ClientStatusRow(
                    title: "Geoid separation",
                    value: format(singlePoint.environmentData.correctedCoordinate.geoidSeparation)
                )

                if let correctedCoordinateWithFormula = singlePointViewModel.correctedCoordinateWithFormula,
                   singlePointViewModel.useMeasurementsWithLaser {
                    Text("Corrected coordinate with formula")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)
                    ClientStatusRow(
                        title: "Latitude",
                        value: format(correctedCoordinateWithFormula.latitude)
                    )
                    ClientStatusRow(
                        title: "Longitude",
                        value: format(correctedCoordinateWithFormula.longitude)
                    )
                    ClientStatusRow(
                        title: "Reference altitude",
                        value: format(correctedCoordinateWithFormula.referenceAltitude)
                    )
                    ClientStatusRow(
                        title: "Geoid separation",
                        value: format(correctedCoordinateWithFormula.geoidSeparation)
                    )
                }
            }
        }
    }

    private var singlePointReadinessText: String {
        ntripViewModel.isStartingNtrip
            ? "Ready to measure. Choose laser mode, duration, and start."
            : "Connect NTRIP first. Single point measurement needs an active correction stream."
    }

    private var selectedModeText: String {
        singlePointViewModel.useMeasurementsWithLaser ? "With laser" : "Without laser"
    }

    private var singlePointStatusText: String {
        if !singlePointViewModel.timerMeasurementValue.isEmpty {
            return singlePointViewModel.timerMeasurementValue
        }
        if singlePointViewModel.singlePointMeasurement != nil {
            return "Result ready"
        }
        return "No measurement yet"
    }

    private func format(_ value: Double) -> String {
        String(format: "%.10f", value)
    }

    private func refreshOffsetsForCurrentMode() {
        if singlePointViewModel.useMeasurementsWithLaser {
            singlePointViewModel.selectLaserOffsets(laserViewModel.selectedPosition)
        } else {
            singlePointViewModel.selectCameraOffsets()
        }
    }
}
