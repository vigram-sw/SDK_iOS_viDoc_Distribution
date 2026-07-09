//
//  GNSSToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

@MainActor
final class GNSSToolsViewModel: ObservableObject {

    @Published private(set) var elevation = ""
    @Published private(set) var satelliteGNSS = ""
    @Published private(set) var satelliteStatusGNSS = ""
    @Published private(set) var dynamicState = ""
    @Published private(set) var currentRate = ""

    var alertPresenter: ((String, String) -> Void)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()

    init(model: MainScreenModel) {
        self.model = model
        configurePublishers()
    }

    func setDynamicState(type: DynamicStateType) {
        model.setDynamicState(type: type)
    }

    func getDynamicState() {
        model.getDynamicState()
    }

    func changeStatusNAVDOP(activate: Bool) {
        model.changeStatusNAVDOP(activate: activate)
    }

    func changeStatusNAVPVT(activate: Bool) {
        model.changeStatusNAVPVT(activate: activate)
    }

    func changeStatusGSTandPVTndDOPmessages(activate: Bool) {
    }

    func getCurrentStatusGNSS(satellite: NavigationSystemType) {
        model.getCurrentStatusGNSS(satellite: satellite)
    }

    func changeStatusGNSS(satellite: NavigationSystemType, activate: Bool) {
        model.changeStatusGNSS(satellite: satellite, activate: activate)
    }

    func activateAllConstellationGNSS() {
        model.activateAllConstellationGNSS()
    }

    func getCurrentMinimumElevation() {
        model.getCurrentMinimumElevation()
    }

    func setMinimumElevation(angle: ElevationValue) {
        model.setMinimumElevation(angle: angle)
    }

    func setChangingRateOfMessages(_ rate: RateValue) {
        model.setChangingRateOfMessages(rate)
    }

    func getChangingRateOfMessages() {
        model.getChangingRateOfMessages()
    }

    func requestChange(baudrate: DeviceMessage.Baudrate) {
        model.requestChange(baudrate: baudrate)
        presentAlert(
            title: "Notification",
            message: "The Bluetooth connection must then be disconnected for 2 seconds, after that the connection can be re-established. After switching off the device, the baud rate is reset to 115200 baud."
        )
    }

    func resetSessionState() {
        elevation = ""
        satelliteGNSS = ""
        satelliteStatusGNSS = ""
        dynamicState = ""
        currentRate = ""
    }

    private func configurePublishers() {
        model.satelliteMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleSatelliteMessage(message)
            }
            .store(in: &subscription)
    }

    private func handleSatelliteMessage(_ message: SatelliteMessage) {
        switch message {
        case .changingRate(let value):
            currentRate = String(value.current.rawValue)
        case .dynamicState(let value):
            dynamicState = dynamicStateDescription(value.current)
        case .statusSattelite(let value):
            satelliteGNSS = satelliteDescription(value.satelliteType)
            satelliteStatusGNSS = value.isEnabled ? "GNSS is enabled" : "GNSS is disabled"
        case .elevation(let value):
            elevation = String(value.current.rawValue)
        default:
            break
        }
    }

    private func dynamicStateDescription(_ state: DynamicStateType) -> String {
        switch state {
        case .pedestrian:
            return "Pedestrian"
        case .stationary:
            return "Stationary"
        @unknown default:
            return "Unknown"
        }
    }

    private func satelliteDescription(_ type: NavigationSystemType) -> String {
        switch type {
        case .gps:
            return "GPS"
        case .glonass:
            return "Glonass"
        case .beidou:
            return "Beidou"
        case .galileo:
            return "Galileo"
        case .qzss:
            return "QZSS"
        case .sbas:
            return "SBAS"
        @unknown default:
            return "Unknown"
        }
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }
}
