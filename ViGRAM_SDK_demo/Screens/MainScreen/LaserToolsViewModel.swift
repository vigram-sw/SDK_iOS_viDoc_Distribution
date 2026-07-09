//
//  LaserToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

@MainActor
final class LaserToolsViewModel: ObservableObject {

    @Published var isBottomLaserSelected = true
    @Published var isBackLaserSelected = false
    @Published var isFastLaserMeasurementsSelected = true
    @Published var isSlowLaserMeasurementsSelected = false
    @Published var isAutoLaserMeasurementsSelected = false
    @Published private(set) var lasersState = ""
    @Published private(set) var distance = ""
    @Published private(set) var quality = ""
    @Published private(set) var qualityRaw = ""
    @Published private(set) var laserMeasurementStatus = "Ready"
    @Published private(set) var isLaserMeasurementInProgress = false

    var alertPresenter: ((String, String) -> Void)?
    var protocolVersionProvider: (() -> Double?)?
    var durationProvider: (() -> String)?
    var selectedLaserPositionDidChange: ((LaserConfiguration.Position) -> Void)?

    var selectedPosition: LaserConfiguration.Position {
        isBackLaserSelected ? .back : .bottom
    }

    var selectedShotMode: LaserConfiguration.ShotMode {
        if isSlowLaserMeasurementsSelected {
            return .slow
        }
        if isAutoLaserMeasurementsSelected {
            return .auto
        }
        return .fast
    }

    var measuredDistance: Double {
        Double(distance) ?? 0.0
    }

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()
    private var laserMeasurementSubscription: AnyCancellable?
    private var laserMeasurementTimeoutWorkItem: DispatchWorkItem?

    init(model: MainScreenModel) {
        self.model = model
    }

    func selectLaserPosition(_ position: LaserConfiguration.Position) {
        turnOffLaser()
        isBottomLaserSelected = position == .bottom
        isBackLaserSelected = position == .back
        selectedLaserPositionDidChange?(position)
    }

    func selectShotMode(_ mode: LaserConfiguration.ShotMode) {
        isFastLaserMeasurementsSelected = mode == .fast
        isSlowLaserMeasurementsSelected = mode == .slow
        isAutoLaserMeasurementsSelected = mode == .auto
    }

    func turnOnLaser() {
        laserMeasurementStatus = "Turning laser on..."

        guard let publisher = model.turnOnLaser(at: selectedPosition) else {
            laserMeasurementStatus = "Laser On command is not available for this device."
            return
        }

        publisher
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.laserMeasurementStatus = "Laser On command sent."
                case .failure(let error):
                    self.laserMeasurementStatus = "Laser On failed: \(error.localizedDescription)"
                    self.presentAlert(error.localizedDescription)
                }
            }) { _ in }
            .store(in: &subscription)

        if let protocolVersion = protocolVersionProvider?(),
           protocolVersion > 1 {
            getLaserStatus()
        }
    }

    func turnOffLaser() {
        laserMeasurementStatus = "Turning laser off..."

        guard let publisher = model.turnOffLaser(at: selectedPosition) else {
            laserMeasurementStatus = "Laser Off command is not available for this device."
            return
        }

        publisher
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.laserMeasurementStatus = "Laser Off command sent."
                case .failure(let error):
                    self.laserMeasurementStatus = "Laser Off failed: \(error.localizedDescription)"
                    self.presentAlert(error.localizedDescription)
                }
            }) { _ in }
            .store(in: &subscription)

        if let protocolVersion = protocolVersionProvider?(),
           protocolVersion > 1 {
            getLaserStatus()
        }
    }

    func getLaserStatus() {
        laserMeasurementStatus = "Requesting laser status..."
        lasersState = ""

        guard let publisher = model.getLasersStatus() else {
            laserMeasurementStatus = "Laser status command is not available for this device."
            return
        }

        publisher
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                if case let .failure(error) = completion {
                    self.laserMeasurementStatus = "Laser status failed: \(error.localizedDescription)"
                    self.presentAlert(error.localizedDescription)
                }
            }) { [weak self] laserState in
                guard let self else { return }
                switch laserState {
                case .backIsOn:
                    self.lasersState = "Back laser is on"
                    self.laserMeasurementStatus = "Laser status received."
                case .bothOff:
                    self.lasersState = "Both lasers are off"
                    self.laserMeasurementStatus = "Laser status received."
                case .bottomIsOn:
                    self.lasersState = "Bottom laser is on"
                    self.laserMeasurementStatus = "Laser status received."
                @unknown default:
                    self.laserMeasurementStatus = "Unknown laser status received."
                }
            }
            .store(in: &subscription)
    }

    func startLaserMeasurement() {
        if isLaserMeasurementInProgress {
            let message = "Laser measurement is already running. Wait for the first response."
            laserMeasurementStatus = message
            presentNotification(message)
            return
        }

        laserMeasurementSubscription?.cancel()
        laserMeasurementStatus = "Sending laser command..."
        distance = ""
        quality = ""
        qualityRaw = ""

        guard let durationText = durationProvider?(),
              let duration = Double(durationText) else {
            laserMeasurementStatus = "Laser measurement was not started: invalid duration."
            presentAlert("Duration value is not correct")
            return
        }

        if let protocolVersion = protocolVersionProvider?(),
           protocolVersion == 1,
           (duration <= 0 || duration > 60) {
            laserMeasurementStatus = "Laser measurement was not started: invalid duration."
            presentAlert("The duration value of a laser recording session in this software version must be between 5 and 60 seconds.")
            return
        }

        let laserConfig = LaserConfiguration(
            shotMode: selectedShotMode,
            position: selectedPosition,
            duration: duration
        )

        guard let publisher = model.startLaser(with: laserConfig) else {
            laserMeasurementStatus = "Laser measurement command is not available for this device."
            return
        }

        beginLaserMeasurementWaitingState()
        laserMeasurementSubscription = publisher
            .prefix(1)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.finishLaserMeasurementWaitingState()
                case .failure(let error):
                    self.finishLaserMeasurementWaitingState()
                    self.laserMeasurementStatus = "Laser measurement failed: \(error.localizedDescription)"
                    self.presentAlert(error.localizedDescription)
                }
            }) { [weak self] measurement in
                self?.applyLaserMeasurement(measurement)
            }
    }

    func handleLaserMeasurement(_ measurement: DeviceMessage.Measurement) {
        applyLaserMeasurement(measurement)
    }

    func resetSessionState() {
        laserMeasurementSubscription?.cancel()
        laserMeasurementSubscription = nil
        laserMeasurementTimeoutWorkItem?.cancel()
        laserMeasurementTimeoutWorkItem = nil
        isLaserMeasurementInProgress = false
        isBottomLaserSelected = true
        isBackLaserSelected = false
        isFastLaserMeasurementsSelected = true
        isSlowLaserMeasurementsSelected = false
        isAutoLaserMeasurementsSelected = false
        lasersState = ""
        distance = ""
        quality = ""
        qualityRaw = ""
        laserMeasurementStatus = "Ready"
    }

    private func beginLaserMeasurementWaitingState() {
        isLaserMeasurementInProgress = true
        laserMeasurementStatus = "Command sent. Waiting up to \(laserFirstMeasurementTimeoutText) seconds for the first laser response..."
        scheduleLaserMeasurementTimeout()
    }

    private func finishLaserMeasurementWaitingState(status: String? = nil) {
        laserMeasurementTimeoutWorkItem?.cancel()
        laserMeasurementTimeoutWorkItem = nil
        isLaserMeasurementInProgress = false
        laserMeasurementSubscription = nil
        if let status {
            laserMeasurementStatus = status
        }
    }

    private func scheduleLaserMeasurementTimeout() {
        laserMeasurementTimeoutWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isLaserMeasurementInProgress else { return }
            self.laserMeasurementSubscription?.cancel()
            self.finishLaserMeasurementWaitingState(
                status: "Laser measurement timed out. Try again."
            )
        }

        laserMeasurementTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Configuration.laserFirstMeasurementTimeout,
            execute: workItem
        )
    }

    private func applyLaserMeasurement(_ measurement: DeviceMessage.Measurement) {
        distance = "\(measurement.distance)"
        
        quality = "\(measurement.quality)"
        if isLaserMeasurementInProgress {
            finishLaserMeasurementWaitingState(status: "Laser measurement received.")
        }
    }

    private var laserFirstMeasurementTimeoutText: String {
        let timeout = Configuration.laserFirstMeasurementTimeout
        if timeout == floor(timeout) {
            return "\(Int(timeout))"
        }
        return String(format: "%.1f", timeout)
    }

    private func presentAlert(_ message: String) {
        alertPresenter?("Error", message)
    }

    private func presentNotification(_ message: String) {
        alertPresenter?("Notification", message)
    }
}
