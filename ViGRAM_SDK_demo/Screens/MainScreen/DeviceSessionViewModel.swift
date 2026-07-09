//
//  DeviceSessionViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import CoreBluetooth
import Foundation
import VigramSDK

@MainActor
final class DeviceSessionViewModel: ObservableObject {

    @Published var message = ""
    @Published var isConfiguringDevice = false
    @Published private(set) var allDeviceNames = [String]()
    @Published private(set) var periphiralState: CBPeripheralState = .disconnected
    @Published private(set) var isStartDevice = false
    @Published private(set) var protocolVersion: Double?
    @Published private(set) var isConnectedDevice = false
    @Published private(set) var isResetingDevice = false
    @Published private(set) var isResetingDeviceWithReconnect = false
    @Published private(set) var currentDevice = ""
    @Published private(set) var currentDeviceName = ""
    @Published private(set) var currentSerialNumber = ""
    @Published private(set) var currentDeviceSoftwareVersion = ""
    @Published private(set) var currentDeviceHardwareVersion = ""
    @Published private(set) var currentDeviceCharge = ""
    @Published private(set) var currentDeviceHasFrontLaser = false
    @Published private(set) var currentDeviceHasBottomLaser = false
    @Published private(set) var currentDeviceHasIMU = false
    @Published private(set) var currentDeviceHasCalibrated = false
    @Published private(set) var currentDeviceHousing = ""
    @Published private(set) var currentDeviceMountDevice = ""
    @Published private(set) var currentVigramRef = ""
    @Published private(set) var currentVigramBat = ""
    @Published private(set) var currentM88Laser = ""
    @Published private(set) var currentL81Laser = ""
    @Published private(set) var currentIMU = ""
    @Published private(set) var deviceNumberStr = ""
    @Published private(set) var numberOfRemaingSwitchOns = ""
    @Published private(set) var isReadyNMEA = false
    @Published private(set) var currentTimeString = ""
    @Published private(set) var unixTimeString = ""
    @Published private(set) var gnssTimeString = ""
    @Published private(set) var rtkStatus = ""
    @Published private(set) var correction = ""
    @Published private(set) var latitude = ""
    @Published private(set) var longitude = ""
    @Published private(set) var lonAccErr = ""
    @Published private(set) var latAccErr = ""
    @Published private(set) var vertAcc = ""
    @Published private(set) var horAcc = ""
    @Published private(set) var horAccTest = ""
    @Published private(set) var countSatellite = ""
    @Published private(set) var pdop = ""
    @Published private(set) var vdop = ""
    @Published private(set) var hdop = ""
    @Published private(set) var tdop = ""
    @Published private(set) var gdop = ""
    @Published private(set) var nVelocity = ""
    @Published private(set) var eVelocity = ""
    @Published private(set) var dVelocity = ""
    @Published private(set) var accurancy = ""
    @Published var durationMeasurements = "5"

    var alertPresenter: ((String, String) -> Void)?
    var laserMeasurementHandler: ((DeviceMessage.Measurement) -> Void)?
    var reconnectNtripIfReadyAfterReset: (() -> Bool)?
    var resumeNtripReconnectAfterReset: (() -> Void)?
    var resetDependentSessionState: (() -> Void)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()
    private let unixTimeDateFormatter = DateFormatter()
    private let currentTimeDateFormatter = DateFormatter()
    private var isNormalDisconnect = false
    private var isIncompatibleDevice = false
    private var incompatibleDeviceMessage = ""
    private var incompatibleDeviceAlertWorkItem: DispatchWorkItem?

    init(model: MainScreenModel) {
        self.model = model
        unixTimeDateFormatter.dateFormat = "HH:mm:ss.SSS"
        unixTimeDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        currentTimeDateFormatter.dateFormat = "HH:mm:ss.SSS"
        configurePublishers()
    }


    var canConnectToNtrip: Bool {
        isReadyNMEA &&
        !gnssTimeString.isEmpty &&
        !latitude.isEmpty &&
        !longitude.isEmpty &&
        !rtkStatus.isEmpty &&
        rtkStatus != "Fix not valid" &&
        rtkStatus != "Not applicable"
    }

    var ntripReadinessMessage: String {
        canConnectToNtrip
            ? "GGA data is ready"
            : "GGA data is not ready yet. Wait for a valid GNSS position before connecting NTRIP."
    }

    func connectToDevice(name: String) {
        currentDevice = ""
        model.connectToDevice(name: name)
    }

    func disconnect() {
        isNormalDisconnect = true
        disconnectToDevice()
    }

    func beginResetReconnect() {
        isResetingDeviceWithReconnect = true
        model.resetDevice()
    }

    private var peripheralStateDescription: String {
        switch periphiralState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnecting:
            return "Disconnecting"
        case .disconnected:
            return "Disconnected"
        @unknown default:
            return "Unknown"
        }
    }

    private func configurePublishers() {
        model.helperErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.presentAlert(title: "Error", message: value)
            }
            .store(in: &subscription)

        model.observableDeviceNames
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.allDeviceNames = value
            }
            .store(in: &subscription)

        model.isConnectedDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isConnectedDevice = value
                self?.isNormalDisconnect = false
                self?.isIncompatibleDevice = false
            }
            .store(in: &subscription)

        model.nameDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentDeviceName = value
            }
            .store(in: &subscription)

        model.serialNumberDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentSerialNumber = value
            }
            .store(in: &subscription)

        model.isStartDevice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isStartDevice = value
            }
            .store(in: &subscription)

        model.currentDeviceType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] device in
                self?.currentDevice = self?.deviceDescription(device.typeOfDevice) ?? ""
            }
            .store(in: &subscription)

        model.deviceMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleDeviceMessage(message)
            }
            .store(in: &subscription)

        model.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.periphiralState = state
                if state == .disconnected {
                    self?.disconnectToDevice()
                }
            }
            .store(in: &subscription)

        model.configurationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConfigurationState(state)
            }
            .store(in: &subscription)

        model.resetState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleResetState(state)
            }
            .store(in: &subscription)

        model.nmeaMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleNMEAMessage(message)
            }
            .store(in: &subscription)

        model.satelliteMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleSatelliteMessage(message)
            }
            .store(in: &subscription)

        model.protocolVersion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] protocolVersion in
                self?.protocolVersion = protocolVersion
            }
            .store(in: &subscription)
    }

    private func handleDeviceMessage(_ message: DeviceMessage) {
        switch message {
        case .version(let version):
            currentDeviceSoftwareVersion = version.software.toString()
            currentDeviceHardwareVersion = version.hardware.toString()
        case .battery(let value):
            currentDeviceCharge = "\(value.percentage) %"
        case .hardwareIndex(let device):
            currentDeviceHasFrontLaser = device.hasFrontLaser
            currentDeviceHasBottomLaser = device.hasBottomLaser
            currentDeviceHasIMU = device.hasIMU
            currentDeviceHasCalibrated = device.hasCalibrated
            currentDeviceHousing = device.getHousing?.rawValue ?? ""
            currentDeviceMountDevice = device.getMount?.rawValue ?? ""
            currentVigramRef = device.getHardwareRevision?.vigramRef ?? ""
            currentVigramBat = device.getHardwareRevision?.vigramBat ?? ""
            currentM88Laser = device.getHardwareRevision?.m88Laser ?? ""
            currentL81Laser = device.getHardwareRevision?.l81Laser ?? ""
        case .measurement(let measurement):
            laserMeasurementHandler?(measurement)
        case .switchProtocolAnswer(let answer):
            numberOfRemaingSwitchOns = "\(answer.countOfRemaingSwitchOns)"
        default:
            break
        }
    }

    private func handleConfigurationState(_ state: StatePeripheralConfiguration) {
        switch state {
        case .inProgress:
            isConfiguringDevice = true
        case .done:
            isConfiguringDevice = false
        case .failed(let error):
            isConfiguringDevice = false
            presentAlert(title: "Error", message: error.localizedDescription)
        case .peripheralError(let error):
            isConfiguringDevice = false
            isIncompatibleDevice = true
            incompatibleDeviceMessage = error.localizedDescription
            incompatibleDeviceAlertWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.incompatibleDeviceAlertWorkItem = nil
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
            incompatibleDeviceAlertWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
        @unknown default:
            isConfiguringDevice = false
        }
    }

    private func handleResetState(_ state: StateResetViDoc) {
        switch state {
        case let .isReseting(value):
            if isResetingDeviceWithReconnect {
                if !value {
                    if isReadyNMEA,
                       reconnectNtripIfReadyAfterReset?() == true {
                        isResetingDeviceWithReconnect = false
                        isResetingDevice = false
                        isConfiguringDevice = false
                    }
                } else {
                    isResetingDevice = value
                    isConfiguringDevice = value
                }
            } else {
                isResetingDevice = value
                isConfiguringDevice = value
            }
        case .failure:
            break
        @unknown default:
            break
        }
    }

    private func handleNMEAMessage(_ message: NMEAMessage) {
        if let ggaMessage = message as? GGAMessage {
            let currentDate = Date()
            currentTimeString = currentTimeDateFormatter.string(from: currentDate)
            unixTimeString = unixTimeDateFormatter.string(from: currentDate)
            gnssTimeString = ggaMessage.time?.description ?? ""

            if ggaMessage.coordinate?.longitude != nil {
                isReadyNMEA = true
                if isResetingDeviceWithReconnect, !isResetingDevice {
                    resumeNtripReconnectAfterReset?()
                    isResetingDeviceWithReconnect = false
                    isResetingDevice = false
                    isConnectedDevice = false
                }

                if let quality = ggaMessage.quality {
                    switch quality {
                    case .invalidFix:
                        rtkStatus = "Fix not valid"
                    case .singlePoint:
                        rtkStatus = "GPS fix"
                    case .pseudoRangeDifferential:
                        rtkStatus = "Differential GPS fix (DGNSS)"
                    case .notApplicable:
                        rtkStatus = "Not applicable"
                    case .rtkFixedAmbiguitySolution:
                        rtkStatus = "RTK Fixed"
                    case .rtkFloatingAmbiguitySolution:
                        rtkStatus = "RTK Float"
                    case .isnDeadReckoning:
                        rtkStatus = "ISN Dead reckoning"
                    case .manualInput:
                        rtkStatus = "Manual input"
                    @unknown default:
                        break
                    }
                }

                correction = ggaMessage.correctionAge?.description ?? ""
                if let latitude = ggaMessage.coordinate?.latitude,
                   let longitude = ggaMessage.coordinate?.longitude {
                    self.latitude = String(latitude)
                    self.longitude = String(longitude)
                } else {
                    latitude = ""
                    longitude = ""
                }
            }
        }

        if let gstMessage = message as? GSTMessage {
            if let latAccErr = gstMessage.latitudeError,
               let lonAccErr = gstMessage.longitudeError {
                self.lonAccErr = String(lonAccErr)
                self.latAccErr = String(latAccErr)
            } else {
                lonAccErr = ""
                latAccErr = ""
            }

            if let horAcc = gstMessage.accuracy?.horizontal,
               let verAcc = gstMessage.accuracy?.vertical {
                self.horAcc = String(horAcc)
                self.vertAcc = String(verAcc)
            } else {
                horAcc = ""
                vertAcc = ""
            }

        }
    }

    private func handleSatelliteMessage(_ message: SatelliteMessage) {
        switch message {
        case .pvt(let value):
            countSatellite = String(value.satelliteCount)
            nVelocity = String(value.northVelocity)
            eVelocity = String(value.eastVelocity)
            dVelocity = String(value.downVelocity)
        case .dop(let value):
            pdop = String(value.positionDop)
            accurancy = String(format: "%.2f", 3 * value.positionDop)
            vdop = String(value.verticalDop)
            hdop = String(value.horizontalDop)
            tdop = String(value.timeDop)
            gdop = String(value.geometricDop)
        default:
            break
        }
    }

    private func disconnectToDevice() {
        isConfiguringDevice = false
        message = ""

        if !isNormalDisconnect {
            if isIncompatibleDevice {
                incompatibleDeviceAlertWorkItem?.cancel()
                incompatibleDeviceAlertWorkItem = nil
                presentAlert(
                    title: "Error",
                    message: incompatibleDeviceMessage.isEmpty
                        ? "The connected device is not supported by this demo."
                        : incompatibleDeviceMessage
                )
            } else {
                presentAlert(title: "Connection lost", message: "viDoc is not response")
            }
        }

        isIncompatibleDevice = false
        incompatibleDeviceMessage = ""
        incompatibleDeviceAlertWorkItem?.cancel()
        incompatibleDeviceAlertWorkItem = nil
        isNormalDisconnect = false
        periphiralState = .disconnected
        currentTimeString = ""
        unixTimeString = ""
        gnssTimeString = ""
        rtkStatus = ""
        correction = ""
        latitude = ""
        longitude = ""
        lonAccErr = ""
        latAccErr = ""
        vertAcc = ""
        horAcc = ""
        horAccTest = ""
        accurancy = ""
        pdop = ""
        vdop = ""
        hdop = ""
        tdop = ""
        gdop = ""
        nVelocity = ""
        eVelocity = ""
        dVelocity = ""
        allDeviceNames.removeAll()
        isConnectedDevice = false
        isStartDevice = false
        isResetingDevice = false
        isReadyNMEA = false
        isResetingDeviceWithReconnect = false
        currentDevice = ""
        currentDeviceName = ""
        currentSerialNumber = ""
        countSatellite = ""
        currentDeviceSoftwareVersion = ""
        currentDeviceHardwareVersion = ""
        protocolVersion = nil
        currentDeviceCharge = ""
        currentDeviceHasFrontLaser = false
        currentDeviceHasBottomLaser = false
        currentDeviceHasIMU = false
        currentDeviceHasCalibrated = false
        currentDeviceHousing = ""
        currentDeviceMountDevice = ""
        currentVigramRef = ""
        currentVigramBat = ""
        currentM88Laser = ""
        currentL81Laser = ""
        currentIMU = ""
        numberOfRemaingSwitchOns = ""
        deviceNumberStr = ""
        resetDependentSessionState?()
        model.disconnect()
        subscription.forEach { $0.cancel() }
        subscription.removeAll(keepingCapacity: true)
        configurePublishers()
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }

    private func deviceDescription(_ type: DeviceVersion) -> String {
        switch type {
        case .viDoc:
            return "viDoc"
        case .viDocLight:
            return "viDoc Light"
        case .unknown:
            return "unknown device"
        case .viDocWithOldSoftware:
            return "viDoc with old software"
        case .viDocOldDevice:
            return "viDoc (old Device)"
        @unknown default:
            return currentDevice
        }
    }
}
