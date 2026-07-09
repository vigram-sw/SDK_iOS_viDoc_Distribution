//
//  LaserMeasurementsSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI
import VigramSDK

struct LaserMeasurementsSubview: View {

    @ObservedObject private var viewModel: DeviceSessionViewModel
    @ObservedObject private var laserViewModel: LaserToolsViewModel

    init(
        viewModel: DeviceSessionViewModel,
        laserViewModel: LaserToolsViewModel
    ) {
        self.viewModel = viewModel
        self.laserViewModel = laserViewModel
    }

    var body: some View {
        ClientCard(
            title: "Laser Measurement",
            subtitle: nil
        ) {
            HStack {
                ClientBadge(text: selectedLaserText, color: .green)
                ClientBadge(text: selectedShotModeText, color: .blue)
                Spacer()
            }

            ClientActionGrid(minimumWidth: 120) {
                SelectButton(
                    isSelected: $laserViewModel.isBottomLaserSelected,
                    color: .green,
                    text: "Bottom"
                )
                .onTapGesture {
                    laserViewModel.selectLaserPosition(.bottom)
                }

                SelectButton(
                    isSelected: $laserViewModel.isBackLaserSelected,
                    color: .green,
                    text: "Back"
                )
                .onTapGesture {
                    laserViewModel.selectLaserPosition(.back)
                }
            }

            ClientActionGrid(minimumWidth: 90) {
                SelectButton(
                    isSelected: $laserViewModel.isFastLaserMeasurementsSelected,
                    color: .green,
                    text: "Fast"
                )
                .onTapGesture {
                    laserViewModel.selectShotMode(.fast)
                }

                SelectButton(
                    isSelected: $laserViewModel.isSlowLaserMeasurementsSelected,
                    color: .green,
                    text: "Slow"
                )
                .onTapGesture {
                    laserViewModel.selectShotMode(.slow)
                }

                SelectButton(
                    isSelected: $laserViewModel.isAutoLaserMeasurementsSelected,
                    color: .green,
                    text: "Auto"
                )
                .onTapGesture {
                    laserViewModel.selectShotMode(.auto)
                }
            }

            ClientFloatingTextField(
                title: "Duration, seconds",
                text: $viewModel.durationMeasurements,
                keyboardType: .decimalPad
            )

            ClientActionGrid(minimumWidth: 110) {
                Button {
                    laserViewModel.getLaserStatus()
                } label: {
                    Text("Status")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    laserViewModel.turnOnLaser()
                } label: {
                    Text("Laser On")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    laserViewModel.turnOffLaser()
                } label: {
                    Text("Laser Off")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                laserViewModel.startLaserMeasurement()
            } label: {
                Text(laserViewModel.isLaserMeasurementInProgress ? "Waiting For Laser Response..." : "Start Laser Measurement")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            ClientStatusRow(title: "Measurement status", value: laserViewModel.laserMeasurementStatus)
            ClientStatusRow(title: "Laser state", value: laserStateText)
            ClientStatusRow(title: "Distance", value: laserViewModel.distance)
            ClientStatusRow(title: "Quality", value: laserViewModel.quality)
            ClientOptionalStatusRow(title: "Quality raw", value: laserViewModel.qualityRaw)
        }
    }

    private var selectedLaserText: String {
        laserViewModel.isBackLaserSelected ? "Back laser" : "Bottom laser"
    }

    private var laserStateText: String {
        laserViewModel.lasersState.isEmpty ? "Both lasers are off" : laserViewModel.lasersState
    }

    private var selectedShotModeText: String {
        switch laserViewModel.selectedShotMode {
        case .fast:
            return "Fast"
        case .slow:
            return "Slow"
        case .auto:
            return "Auto"
        @unknown default:
            return "Fast"
        }
    }
}
