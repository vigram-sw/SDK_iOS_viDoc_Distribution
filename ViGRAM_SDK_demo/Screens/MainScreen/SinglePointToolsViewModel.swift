//
//  SinglePointToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

@MainActor
final class SinglePointToolsViewModel: ObservableObject {

    @Published var timerMeasurementValue = ""
    @Published var singlePointMeasurement: SinglePoint?
    @Published var useMeasurementsWithLaser = true
    @Published var useMeasurementsWithoutLaset = false
    @Published private(set) var currentOffsetsString = "With laser: DefaultBottom"
    @Published private(set) var currentOffsets = AntennaOffset.Laser.defaultBottom
    @Published private(set) var currentAllOffsets = [(String, SIMD3<Double>)]()
    @Published var distanceToGround = "50"
    @Published private(set) var correctedCoordinateWithFormula: GPSCoordinate?

    var alertPresenter: ((String, String) -> Void)?
    var durationProvider: (() -> String)?
    var protocolVersionProvider: (() -> Double?)?
    var selectedLaserPositionProvider: (() -> LaserConfiguration.Position)?
    var selectedLaserShotModeProvider: (() -> LaserConfiguration.ShotMode)?
    var laserDistanceProvider: (() -> Double)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()

    init(model: MainScreenModel) {
        self.model = model
        currentAllOffsets = model.chouseAllOffsets(with: .bottom)
        synchronizeCurrentOffsetSelection()
        configurePublishers()
    }

    func activateLaserMeasurement(position: LaserConfiguration.Position) {
        useMeasurementsWithLaser = true
        useMeasurementsWithoutLaset = false
        selectLaserOffsets(position)
    }

    func activateCameraMeasurement() {
        useMeasurementsWithLaser = false
        useMeasurementsWithoutLaset = true
        selectCameraOffsets()
    }

    func selectLaserOffsets(_ position: LaserConfiguration.Position) {
        singlePointMeasurement = nil
        currentAllOffsets = model.chouseAllOffsets(with: position)
        synchronizeCurrentOffsetSelection()
    }

    func selectCameraOffsets() {
        singlePointMeasurement = nil
        currentAllOffsets = model.chouseCameraOffsets()
        synchronizeCurrentOffsetSelection()
    }

    func startMeasurement() {
        timerMeasurementValue = ""

        guard let durationText = durationProvider?(),
              let duration = Double(durationText) else {
            presentAlert(title: "Error", message: "Duration value is not correct")
            return
        }

        if let protocolVersion = protocolVersionProvider?(),
           protocolVersion == 1,
           (duration < 0 || duration > 60) {
            presentAlert(title: "Error", message: "Duration value is not correct")
            return
        }

        singlePointMeasurement = nil
        correctedCoordinateWithFormula = nil

        let selectedLaserPosition = selectedLaserPositionProvider?() ?? .bottom
        let laserShotMode = selectedLaserShotModeProvider?() ?? .fast
        let laserConfig = LaserConfiguration(
            shotMode: laserShotMode,
            position: selectedLaserPosition,
            duration: duration
        )

        if useMeasurementsWithLaser {
            model.turnOffLaser(at: selectedLaserPosition)?
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    switch completion {
                    case .finished:
                        if let protocolVersion = self.protocolVersionProvider?(),
                           protocolVersion > 1 {
                            self.model.recordWithLaser(
                                duration: duration,
                                configuration: laserConfig,
                                offsets: self.currentOffsets,
                                isNewProtocol: true
                            )
                        } else {
                            self.model.recordWithLaser(
                                duration: duration,
                                configuration: laserConfig,
                                offsets: self.currentOffsets
                            )
                        }
                    case .failure(let error):
                        self.presentAlert(title: "Error", message: error.localizedDescription)
                    }
                }) { _ in }
                .store(in: &subscription)
            return
        }

        guard let distanceToGround = Double(distanceToGround) else {
            presentAlert(title: "Error", message: "Distance to ground value is not correct")
            return
        }

        if let protocolVersion = protocolVersionProvider?(),
           protocolVersion > 1 {
            model.recordWithoutLaser(
                duration: duration,
                antennaDistanceToGround: distanceToGround,
                offsets: currentOffsets,
                isNewProtocol: true
            )
        } else {
            model.recordWithoutLaser(
                duration: duration,
                antennaDistanceToGround: distanceToGround,
                offsets: currentOffsets
            )
        }
    }

    func stopMeasurement() {
        timerMeasurementValue = ""
        model.stopSPMeasurement()
    }

    func cancelMeasurement() {
        timerMeasurementValue = ""
        model.cancelSPMeasurement()
    }

    func clearMeasurementResult() {
        singlePointMeasurement = nil
        correctedCoordinateWithFormula = nil
        timerMeasurementValue = ""
    }

    func resetSessionState() {
        timerMeasurementValue = ""
        singlePointMeasurement = nil
        correctedCoordinateWithFormula = nil
        distanceToGround = "50"
        activateLaserMeasurement(position: .bottom)
    }

    func selectOffset(named name: String) {
        guard let offset = currentAllOffsets.first(where: { $0.0 == name }) else {
            return
        }
        currentOffsetsString = offset.0
        currentOffsets = offset.1
        singlePointMeasurement = nil
        correctedCoordinateWithFormula = nil
    }

    private func configurePublishers() {
        model.singlePointTimer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.timerMeasurementValue = value
            }
            .store(in: &subscription)

        model.singlePointMeasurement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                self.timerMeasurementValue = ""
                switch result {
                case .success(let value):
                    self.singlePointMeasurement = value
                    self.correctedCoordinateWithFormula = value.environmentData.coordinate.translate(
                        offset: self.currentOffsets,
                        orientation: value.environmentData.deviceMotion.orientation,
                        laserDistance: self.laserDistanceProvider?() ?? 0.0,
                        typeOfLaser: self.selectedLaserPositionProvider?() ?? .bottom
                    )
                case .failure(let error):
                    self.timerMeasurementValue = ""
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
            .store(in: &subscription)
    }

    private func synchronizeCurrentOffsetSelection() {
        guard !currentAllOffsets.isEmpty else { return }

        if let currentOffset = currentAllOffsets.first(where: { $0.0 == currentOffsetsString }) {
            currentOffsets = currentOffset.1
            return
        }

        let defaultOffset = currentAllOffsets[0]
        currentOffsetsString = defaultOffset.0
        currentOffsets = defaultOffset.1
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }
}
