//
//  MainScreenViewModel.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import Combine
import CoreBluetooth
import SwiftUI
import VigramSDK

extension MainScreenView {
    @MainActor class MainScreenViewModel: ObservableObject {
        
        // MARK: Public properties
        // ALERT
        @Published var isShowingAlert = false
        @Published private(set) var titleAlert = ""
        @Published private(set) var messageAlert = ""
        // PERIPHERAL
        @Published var allDeviceNames = [String]()
        @Published private(set) var periphiralState: CBPeripheralState = .disconnected
        // DEVICE
        @Published var isConfiguringDevice = false
        @Published var isStartDevice = false
        @Published private(set) var isConnectedDevice = false
        @Published private(set) var isResetingDevice = false
        @Published private(set) var isResetingDeviceWithReconnect = false
        @Published private(set) var isFlashingDevice = false
        @Published private(set) var currentDeviceName = ""
        @Published private(set) var currentSerialNumber = ""
        @Published private(set) var currentDeviceSoftwareVersion = ""
        @Published private(set) var currentDeviceHardwareVersion = ""
        @Published private(set) var currentDeviceCharge = ""
        @Published private(set) var resetMessageError = ""
        @Published private(set) var viDocState = ""
        // SOFTWARE
        @Published var allAvailableSoftwareNamesForWeb = [String]()
        @Published private(set) var statusUpdate = ""
        @Published private(set) var progressUpdate = ""
        // SATELLITE
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
        @Published private(set) var countSatellite = ""
        @Published private(set) var rawxMessage = ""
        @Published private(set) var sfrbxMessage = ""
        @Published private(set) var pdop = ""
        @Published private(set) var vdop = ""
        @Published private(set) var hdop = ""
        @Published private(set) var tdop = ""
        @Published private(set) var gdop = ""
        @Published private(set) var nVelocity = ""
        @Published private(set) var eVelocity = ""
        @Published private(set) var dVelocity = ""
        @Published private(set) var accurancy = ""
        @Published private(set) var elevation = ""
        @Published private(set) var satelliteGNSS = ""
        @Published private(set) var satelliteStatusGNSS = ""
        @Published private(set) var dynamicState = ""
        @Published private(set) var currentRate = ""
        @Published private(set) var rmxIsActive = false
        // NTRIP
        @Published var ntripCredentials = [NtripCredentials]()
        @Published var mountPoint = ""
        @Published var hostname = ""
        @Published var port = ""
        @Published var username = ""
        @Published var password = ""
        @Published var ntripSizeParcel = ""
        @Published var ntripStatus = "Not connected"
        @Published var isStartingNtrip = false
        // LASER
        @Published var durationMeasurements = "5"
        @Published var isBottomLaserSelected = true
        @Published var isBackLaserSelected = false
        @Published private(set) var distance = ""
        @Published private(set) var quality = ""
        @Published private(set) var currentAllOffsets = [(String, SIMD3<Double>)]()
        // SINGLE POINT
        @Published var timerMeasurementValue = ""
        @Published var singlePointMeasurement: SinglePoint?
        @Published var useMeasurementsWithLaser = true
        @Published var useMeasurementsWithoutLaset = false
        @Published var currentOffsetsString = "With laset: iPhone14ProMaxBottom"
        @Published var currentOffsets = AntennaOffset.Laser.iPhone14ProMaxBottom
        @Published var distanceToGround = "50"
        @Published private(set) var correctedCoordinateWithFormula: GPSCoordinate?
        // RXM
        @Published var timerValue = ""
        @Published var listOfUBXFiles = [String]()
        @Published var fileLinkForUBXFile: URL?
        @Published var isSharePresented: Bool = false

        // MARK: Private properties
        
        private var model = MainScreenModel()
        private var ggaMessage: GGAMessage?
        private var subscription = Set<AnyCancellable>()
        private let unixTimeDateFormatter = DateFormatter()
        private let currentTimeDateFormatter = DateFormatter()
        private var isNeedUpdateSoftware = false
        private var isSuccesUpdateSoftware = false
        private var isNormalDisconnect = false
        private var isIncompatibleDevice = false
        private var socketCodeError: Int?
        
        // MARK: Init
        
        init() {
            unixTimeDateFormatter.dateFormat = "HH:mm:ss.SSS"
            unixTimeDateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            currentTimeDateFormatter.dateFormat = "HH:mm:ss.SSS"
            configurePublishers()
            ntripCredentials = model.getAllNtripCredential()
        }
        
        // MARK: Public methods (Intens)
        
        // MARK: Software
        
        func installSoftware(name: String) {
            model.installSoftware(name: name)
            titleAlert = "Notification"
            messageAlert = """
                Please restart viDoc to start update.
                Note: If the viDoc doesn't have the bootloader, the installation of the software is not possible.
            """
            isShowingAlert = true
        }

        func setForceUpdateSoftware() {
            model.setForceUpdateSoftware()
            titleAlert = "Notification"
            messageAlert = """
                Please restart viDoc to start update.
                Note: If the viDoc doesn't have the bootloader, the installation of the software is not possible.
            """
            isShowingAlert = true
        }
        
        // MARK: Device
        
        func connectToDevice(name: String) {
            titleAlert = ""
            messageAlert = ""
            model.connectToDevice(name: name)
        }
        
        func disconnect() {
            isNormalDisconnect = true
            disconnectToDevice()
        }
        
        func requestBattery() {
            model.requestBattery()
        }
        
        func requestVersion() {
            model.requestVersion()?.sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    if Configuration.debug {
                        print("Error \(error.localizedDescription)")
                    }
                }
            }) { _ in }.store(in: &subscription)
        }

        func setDynamicState(type: DynamicStateType) {
            model.setDynamicState(type: type)
        }
        
        func getDynamicState() {
            model.getDynamicState()
        }
        
        func changeStatusNAVDOP(activate: Bool){
            model.changeStatusNAVDOP(activate: activate)
        }
        
        func changeStatusNAVPVT(activate: Bool){
            model.changeStatusNAVPVT(activate: activate)
        }

        func getCurrentStatusGNSS(satellite: NavigationSystemType) {
            model.getCurrentStatusGNSS(satellite: satellite)
        }
        
        func changeStatusGNSS(satellite: NavigationSystemType, activate: Bool) {
            model.changeStatusGNSS(satellite: satellite, activate: activate)
        }
        
        func activateAllConstellationGNSS(){
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
        
        // MARK: LASER
        
        func turnOnLaser() {
            let typeOfLaser: LaserConfiguration.Position = isBottomLaserSelected ? .bottom : .back
            model.turnOnLaser(at: typeOfLaser)?
                .sink(receiveCompletion: { [weak self] complition in
                    switch complition {
                    case .finished:
                        break
                    case let .failure(error):
                        self?.titleAlert = "Error"
                        self?.messageAlert = error.localizedDescription
                        self?.isShowingAlert = true
                    }
                }) { _ in }.store(in: &self.subscription)
        }
        
        func turnOffLaser() {
            let typeOfLaser: LaserConfiguration.Position = isBottomLaserSelected ? .bottom : .back
            model.turnOffLaser(at: typeOfLaser)?
                .sink(receiveCompletion: { [weak self] complition in
                    switch complition {
                    case .finished:
                        break
                    case let .failure(error):
                        self?.titleAlert = "Error"
                        self?.messageAlert = error.localizedDescription
                        self?.isShowingAlert = true
                    }
                }) { _ in }.store(in: &self.subscription)
        }
        
        func startLaser(){
            if let duration = Double(durationMeasurements) {
                if (duration <= 0 || duration > 60) {
                    titleAlert = "Error"
                    messageAlert = "The duration value of a laser recording session in this software version must be between 5 and 60 seconds."
                    isShowingAlert = true
                } else {
                    let typeOfLaser: LaserConfiguration.Position = isBottomLaserSelected ? .bottom : .back
                    let laserConfig = LaserConfiguration.init(shotMode: .fast, position: typeOfLaser, duration: duration)
                    model.startLaser(with: laserConfig)?
                        .sink(receiveCompletion: { [weak self] complition in
                            switch(complition) {
                            case .finished:
                                break
                            case .failure(let error):
                                self?.titleAlert = "Error"
                                self?.messageAlert = error.localizedDescription
                                self?.isShowingAlert = true
                            }
                        }) { _ in }.store(in: &self.subscription)
                }
            } else {
                titleAlert = "Error"
                messageAlert = "Duration value is not correct"
                isShowingAlert = true
            }
        }
        
        func setCurrentOffset(with position: LaserConfiguration.Position) {
            isBackLaserSelected = position == .back
            isBottomLaserSelected = position == .bottom
            singlePointMeasurement = nil
            currentAllOffsets.removeAll()
            currentAllOffsets = model.chouseAllOffsets(with: position)
            useMeasurementsWithLaser = true
            useMeasurementsWithoutLaset = false
        }
        
        func setCurrentCameraOffsets() {
            singlePointMeasurement = nil
            currentAllOffsets.removeAll()
            currentAllOffsets = model.chouseCameraOffsets()
            useMeasurementsWithLaser = false
            useMeasurementsWithoutLaset = true
        }

        // MARK: NTRIP
        
        func connectToNTRIP() {
            if let port = Int(port) {
                do {
                    try model.connectToNTRIP(
                        hostname: hostname,
                        port: port,
                        username: username,
                        password: password,
                        mountPoint: mountPoint
                    )
                } catch {
                    titleAlert = "Error"
                    messageAlert = error.localizedDescription
                    isShowingAlert = true
                }
            } else {
                titleAlert = "Error"
                messageAlert = "Incorrect data: port"
                isShowingAlert = true
            }
        }
        
        func reConnectToNTRIP() {
            model.reConnectToNTRIP()
        }
        
        func reConnectToNTRIPWithReset() {
            viDocState = ""
            resetMessageError = ""
            isResetingDeviceWithReconnect = true
            model.resetDevice()
        }
        
        func disconnectNtrip() {
            isStartingNtrip = false
            ntripStatus = "No connection"
            ntripSizeParcel = ""
            model.disconnectNtrip()
        }
        
        // MARK: RESET
        
        func resetDevice() {
            viDocState = ""
            resetMessageError = ""
            model.resetDevice()
        }
        
        func clearTXTLog() {
            viDocState = ""
        }
        
        // MARK: SINGLE POINT
        
        func startSPMeasurement(){
            timerMeasurementValue = ""
            if let duration = Double(durationMeasurements) {
                if (duration < 0 || duration > 60) {
                    titleAlert = "Error"
                    messageAlert = "Duration value is not correct"
                    isShowingAlert = true
                    return
                }
                singlePointMeasurement = nil
                correctedCoordinateWithFormula = nil
                let typeOfLaser: LaserConfiguration.Position = isBottomLaserSelected ? .bottom : .back
                let laserConfig = LaserConfiguration.init(shotMode: .fast, position: typeOfLaser, duration: duration)
                if useMeasurementsWithLaser {
                    let typeOfLaser: LaserConfiguration.Position = isBottomLaserSelected ? .bottom : .back
                    model.turnOffLaser(at: typeOfLaser)?
                        .sink(receiveCompletion: { [weak self] complition in
                            guard let self = self else { return }
                            switch complition {
                            case .finished:
                                self.model.recordWithLaser(duration: duration, configuration: laserConfig, offsets: currentOffsets)
                            case let .failure(error):
                                self.titleAlert = "Error"
                                self.messageAlert = error.localizedDescription
                                self.isShowingAlert = true
                            }
                        }) { _ in }.store(in: &self.subscription)
                } else {
                    if let distanceToGround = Double(distanceToGround) {
                        model.recordWithoutLaser(duration: duration, antennaDistanceToGround: distanceToGround, offsets: currentOffsets)
                    } else {
                        titleAlert = "Error"
                        messageAlert = "Distance to ground value is not correct"
                        isShowingAlert = true
                    }
                }
            } else {
                titleAlert = "Error"
                messageAlert = "Duration value is not correct"
                isShowingAlert = true
            }
        }

        // MARK: RXM
        
        func changeStatusRXM(activate: Bool) {
            model.changeStatusRXM(activate: activate)
        }
        
        func startRecordPPKMeasurements() {
            model.startRecordPPKMeasurements()
        }
        
        func stopRecordPPKMeasurements() {
            model.stopRecordPPKMeasurements()
        }
        
        func getAllUBXFiles() {
            switch model.getAllUBXFiles() {
            case .success(let values):
                listOfUBXFiles = values
            case .failure:
                titleAlert = "Error"
                messageAlert = "Directory PPK is not found. Please check access app to files"
                isShowingAlert = true
            }
        }
        
        func getUBXFile(filename: String, pathName: String){
            fileLinkForUBXFile = model.getUBXFile(filename: filename, pathName: pathName)
            
            if fileLinkForUBXFile != nil {
                isSharePresented = true
            }
        }
    }
}
// MARK: - Private methods

private extension MainScreenView.MainScreenViewModel {

    func configurePublishers() {
        model.allAvailableSoftwareNames.sink { [weak self] values in
            self?.allAvailableSoftwareNamesForWeb = values
        }.store(in: &subscription)

        model.observableDeviceNames.sink { [weak self] value in
            self?.allDeviceNames = value
        }.store(in: &subscription)

        model.isConnectedDevice.sink{ [weak self] value in
            self?.isConnectedDevice = value
            self?.isNormalDisconnect = false
            self?.isIncompatibleDevice = false
        }.store(in: &subscription)

        model.nameDevice.sink{ [weak self] value in
            self?.currentDeviceName = value
        }.store(in: &subscription)

        model.serialNumberDevice.sink{ [weak self] value in
            self?.currentSerialNumber = value
        }.store(in: &subscription)

        model.isStartDevice.sink{ [weak self] value in
            self?.isStartDevice = value
        }.store(in: &subscription)

        model.deviceMessage.sink { [weak self] message in
            switch message {
            case .version(let version):
                self?.currentDeviceSoftwareVersion = version.software.toString()
                self?.currentDeviceHardwareVersion = version.hardware.toString()
            case .battery(let value):
                self?.currentDeviceCharge = "\(value.percentage) %"
            case .measurement(let measurement):
                self?.distance = "\(measurement.distance)"
                self?.quality = "\(measurement.quality)"
            default:
                break
            }
        }.store(in: &subscription)

        model.state.sink{ [weak self] state in
            self?.periphiralState = state
            switch(state){
            case .disconnected:
                self?.disconnectToDevice()
            default:
                break
            }
        }.store(in: &subscription)
        
        model.configurationState.sink{ [weak self] state in
            guard let self = self else { return }
            switch state {
            case .inProgress:
                self.isConfiguringDevice = true
            case .done:
                self.isConfiguringDevice = false
                if self.isNeedUpdateSoftware || self.isSuccesUpdateSoftware {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.isShowingAlert = true
                        self?.isNeedUpdateSoftware = false
                        self?.isSuccesUpdateSoftware = false
                    }
                }
            case .failed(let error):
                self.isConfiguringDevice = false
                self.titleAlert = "Error"
                self.messageAlert = error.localizedDescription
                self.isShowingAlert = true
            @unknown default:
                self.isConfiguringDevice = false
            }
        }.store(in: &subscription)

        model.resetState.sink { [weak self] state in
            guard let self = self else { return }
            switch state {
            case let .isReseting(value):
                if self.isResetingDeviceWithReconnect {
                    if !value {
                        if self.isReadyNMEA {
                            self.reConnectToNTRIP()
                            self.isResetingDeviceWithReconnect = false
                            self.isResetingDevice = false
                            self.isConfiguringDevice = false
                        }
                    } else {
                        self.isResetingDevice = value
                        self.isConfiguringDevice = value
                    }
                } else {
                    self.isResetingDevice = value
                    self.isConfiguringDevice = value
                }
            case let .failure(message):
                self.resetMessageError = message
            @unknown default:
                break
            }
        }.store(in: &self.subscription)
        
        model.viDocState.sink { [weak self] state in
            switch state {
            case let .user(message):
                if message != "Starting viDoc" {
                    self?.viDocState += "\(Date().getCurrentDateToString())- GNTXT - User Message: \(message)\r\n "
                }
            case let .error(message):
                if message != "Starting viDoc" {
                    self?.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Error Message: \(message)\r\n "
                }
            case let .warning(message):
                if message != "Starting viDoc" {
                    self?.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Warning Message: \(message)\r\n "
                }
            case let .notice(message):
                if message != "Starting viDoc" {
                    self?.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Notice Message: \(message)\r\n "
                }
            @unknown default:
                break
            }
        }.store(in: &self.subscription)

        model.nmeaMessage.sink { [weak self] message in
            guard let self = self else { return }
            if let ggaMessage = message as? GGAMessage {
                self.ggaMessage = ggaMessage
                let currentDate = Date()
                let unixDate = NSDate(timeIntervalSince1970: Date().timeIntervalSince1970)
                self.currentTimeString = self.currentTimeDateFormatter.string(from: currentDate)
                self.unixTimeString = self.unixTimeDateFormatter.string(from: unixDate as Date)
                self.gnssTimeString = ggaMessage.time?.description ?? ""

                if ggaMessage.coordinate?.longitude != nil {
                    self.isReadyNMEA = true
                    if isResetingDeviceWithReconnect, !isResetingDevice {
                        self.model.reConnectToNTRIP()
                        self.isResetingDeviceWithReconnect = false
                        self.isResetingDevice = false
                        self.isConnectedDevice = false
                    }

                    if let quality = ggaMessage.quality {
                        switch quality {
                        case .invalidFix:
                            self.rtkStatus = "Fix not valid"
                        case .singlePoint:
                            self.rtkStatus = "GPS fix"
                        case .pseudoRangeDifferential:
                            self.rtkStatus = "Differential GPS fix (DGNSS)"
                        case .notApplicable:
                            self.rtkStatus = "Not applicable"
                        case .rtkFixedAmbiguitySolution:
                            self.rtkStatus = "RTK Fixed"
                        case .rtkFloatingAmbiguitySolution:
                            self.rtkStatus = "RTK Float"
                        case .isnDeadReckoning:
                            self.rtkStatus = "ISN Dead reckoning"
                        case .manualInput:
                            self.rtkStatus = "Manual input"
                        @unknown default:
                            break
                        }
                    }

                    self.correction = ggaMessage.correctionAge?.description ?? ""
                    if let latitude = ggaMessage.coordinate?.latitude,
                       let longitude = ggaMessage.coordinate?.longitude {
                        self.latitude = String(latitude)
                        self.longitude = String(longitude)
                    } else {
                        self.latitude = ""
                        self.longitude = ""
                    }
                } else {
                    self.isReadyNMEA = false
                }
            }
            if let gstMessage = message as? GSTMessage {
                if let latAccErr = gstMessage.latitudeError,
                   let lonAccErr = gstMessage.longitudeError {
                    self.lonAccErr = String(lonAccErr)
                    self.latAccErr = String(latAccErr)
                } else {
                    self.lonAccErr = ""
                    self.latAccErr = ""
                }
                if let horAcc = gstMessage.accuracy?.horizontal,
                   let verAcc = gstMessage.accuracy?.vertical {
                    self.horAcc = String(horAcc)
                    self.vertAcc = String(verAcc)
                } else {
                    self.horAcc = ""
                    self.vertAcc = ""
                }
            }
        }.store(in: &subscription)
        
        model.satelliteMessage.sink { [weak self] message in
            switch message {
            case .rawx(let value):
                self?.rawxMessage = value.message.hexStringWithSpace()
            case .sfrbx(let value):
                self?.sfrbxMessage = value.message.hexStringWithSpace()
            case .pvt(let value):
                self?.countSatellite = String(value.satelliteCount)
                self?.nVelocity = String(value.northVelocity)
                self?.eVelocity = String(value.eastVelocity)
                self?.dVelocity = String(value.downVelocity)
            case .dop(let value):
                self?.pdop = String(value.positionDop)
                self?.accurancy = String(format: "%.2f", 3*value.positionDop)
                self?.vdop = String(value.verticalDop)
                self?.hdop = String(value.horizontalDop)
                self?.tdop = String(value.timeDop)
                self?.gdop = String(value.geometricDop)
            case .changingRate(let value):
                self?.currentRate = String(value.current.rawValue)
            case .dynamicState(let value):
                switch value.current {
                case .pedestrian:
                    self?.dynamicState = "Pedestrian"
                case .stationary:
                    self?.dynamicState = "Stationary"
                @unknown default:
                    break
                }
            case .statusSattelite(let value):
                switch value.satelliteType {
                case .gps:
                    self?.satelliteGNSS = "GPS"
                case .glonass:
                    self?.satelliteGNSS = "Glonass"
                case .beidou:
                    self?.satelliteGNSS = "Beidou"
                case .galileo:
                    self?.satelliteGNSS = "Galileo"
                case .qzss:
                    self?.satelliteGNSS = "QZSS"
                case .sbas:
                    self?.satelliteGNSS = "SBAS"
                @unknown default:
                    break
                }
                self?.satelliteStatusGNSS = value.isEnabled == true ? "GNSS is enabled" : "GNSS is disabled"
            case .elevation(let value):
                self?.elevation = String(value.current.rawValue)
            default:
                break
            }
        }.store(in: &subscription)

        model.softwareUpdateState.sink { [weak self] updateState in
            var status = ""
            switch(updateState) {
            case .startUpdate:
                UIApplication.shared.isIdleTimerDisabled = true
                status = "Start update"
                self?.isFlashingDevice = true
            case .updatingSoftware: 
                status = "Updating..."
            case .endUpdate:
                status = "Update successfull"
                self?.titleAlert = "Update successfull"
                self?.messageAlert = "Please restart viDoc"
                self?.model.successFullUpdateCompelete()
                self?.isSuccesUpdateSoftware = true
                self?.isFlashingDevice = false
                UIApplication.shared.isIdleTimerDisabled = false
            case .errorUpdate:
                self?.titleAlert = "Update error"
                self?.messageAlert = "Please try again..."
                self?.isShowingAlert = true
                UIApplication.shared.isIdleTimerDisabled = false
            case .none: status = ""
            @unknown default:
                break
            }
            self?.statusUpdate = "Status: \(status)"
        }.store(in: &subscription)

        model.softwareUpdateProgress.sink { [weak self] value in
            self?.progressUpdate = "Progress: \(String(format: "%.1f", value)) %"
        }.store(in: &subscription)
        
        model.softwareIsNeedUpdate.sink { [weak self] isNeedUpdate in
            self?.isNeedUpdateSoftware = isNeedUpdate
            if isNeedUpdate {
                self?.titleAlert = "Notice"
                self?.messageAlert = "New software available. Please update the viDoc"
            }
        }.store(in: &subscription)
        
        model.ppkMeasurementsState.sink { [weak self] value in
            self?.rmxIsActive = value
        }.store(in: &subscription)
        
        model.ntripData.sink { [weak self] data in
            guard let self = self else { return }
            var tempString = self.ntripSizeParcel
            if !tempString.isEmpty {
                tempString += "\n"
            }
            tempString += "\(self.currentTimeString) - \(data.count) bytes"
            self.ntripSizeParcel = tempString
        }.store(in: &subscription)
        
        model.ntripState.sink { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.ntripStatus = "Connection is ready"
                self.isStartingNtrip = true
                if let port = Int(self.port) {
                    let currentNtripCridential = NtripCredentials(
                        host: hostname,
                        port: port,
                        login: username,
                        pass: password,
                        mountpoint: mountPoint
                    )
                    if ntripCredentials.first(where: { $0 == currentNtripCridential }) == nil {
                        ntripCredentials.append(currentNtripCridential)
                        do {
                            let res = try JSONEncoder().encode(self.ntripCredentials)
                            UserDefaults.standard.set(res, forKey: "ntrip")
                        }
                        catch {
                            self.titleAlert = "Update error"
                            self.messageAlert = "Please try again..."
                            self.isShowingAlert = true
                        }
                    }
                }
            case .preparing:
                self.ntripStatus = "Connection is preparing"
            case .cancelled:
                if self.socketCodeError == nil {
                    self.ntripStatus = "Connection is cancelled"
                }
                self.isStartingNtrip = false
                self.singlePointMeasurement = nil
                self.correctedCoordinateWithFormula = nil
            case .failed(let error):
                if self.socketCodeError == nil {
                    self.ntripStatus = "Connection is failed: \(error.localizedDescription)"
                }
                self.isStartingNtrip = false
                self.singlePointMeasurement = nil
                self.correctedCoordinateWithFormula = nil
            case .setup:
                self.ntripStatus = "Connection is setup"
            case .waiting(let error):
                if self.socketCodeError == nil {
                    self.ntripStatus = "Connection is waiting: \(error.localizedDescription)"
                }
            case .unknownError(let error):
                self.ntripStatus = "Unknown error connection: \(error.description)"
                self.isStartingNtrip = false
                self.singlePointMeasurement = nil
                self.correctedCoordinateWithFormula = nil
            case .notConnected:
                self.ntripStatus = "Not connected to Ntrip"
                self.isStartingNtrip = false
                self.singlePointMeasurement = nil
                self.correctedCoordinateWithFormula = nil
            case .socketError(let errorCode):
                if self.socketCodeError == nil {
                    if errorCode == 61 {
                        self.ntripStatus = "Connection is failed: Incorrect data: port"
                    } else if errorCode == 173 {
                        self.ntripStatus = "Connection is failed: Incorrect data: mountpoint"
                    } else if errorCode == 221 {
                        self.ntripStatus = "Connection is failed: Incorrect data: login and / or password"
                    } else if errorCode == 65554 {
                        self.ntripStatus = "Connection is failed: Incorrect data: unknown hostname"
                    } else {
                        self.ntripStatus = "No connection. Posix: \(errorCode)"
                    }
                    self.isStartingNtrip = false
                    self.singlePointMeasurement = nil
                    self.correctedCoordinateWithFormula = nil
                }
            @unknown default:
                break
            }
        }.store(in: &subscription)
        
        model.singlePointTimer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.timerMeasurementValue = value
            }.store(in: &subscription)
        
        model.singlePointMeasurement
            .sink { [weak self] result in
                guard let self = self else { return }
                self.timerMeasurementValue = ""
                switch result {
                case .success(let value):
                    self.singlePointMeasurement = value
                    self.correctedCoordinateWithFormula = value.environmentData.coordinate.translate(
                        offset: self.currentOffsets,
                        orientation: value.environmentData.deviceMotion.orientation,
                        laserDistance: Double(self.distance) ?? 0.0,
                        typeOfLaser: self.isBottomLaserSelected ? .bottom : .back
                    )
                case .failure(let error):
                    self.timerMeasurementValue = ""
                    self.titleAlert = "Error"
                    self.messageAlert = error.localizedDescription
                    self.isShowingAlert = true
                }
            }.store(in: &subscription)

        model.ppkMeasurementsTimer
            .sink { [weak self] value in
                self?.timerValue = value
            }.store(in: &subscription)
    }

    func disconnectToDevice() {
        if !isNormalDisconnect {
            if isIncompatibleDevice {
                isShowingAlert = true
            } else {
                titleAlert = "Connection lost"
                messageAlert = "viDoc is not response"
                isShowingAlert = true
            }
        }
        isIncompatibleDevice = false
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
        viDocState = ""
        dynamicState = ""
        vertAcc = ""
        horAcc = ""
        accurancy = ""
        distance = ""
        quality = ""
        distanceToGround = ""
        timerMeasurementValue = ""
        singlePointMeasurement = nil
        timerValue = ""
        rawxMessage = ""
        sfrbxMessage = ""
        satelliteGNSS = ""
        satelliteStatusGNSS = ""
        pdop = ""
        vdop = ""
        hdop = ""
        tdop = ""
        gdop = ""
        nVelocity = ""
        eVelocity = ""
        dVelocity = ""
        lonAccErr = ""
        latAccErr = ""
        currentRate = ""
        resetMessageError = ""
        allDeviceNames.removeAll()
        isConnectedDevice = false
        isStartDevice = false
        isResetingDevice = false
        isReadyNMEA = false
        isNeedUpdateSoftware = false
        isResetingDeviceWithReconnect = false
        isFlashingDevice = false
        statusUpdate = ""
        progressUpdate = ""
        currentDeviceName = ""
        currentSerialNumber = ""
        countSatellite = ""
        currentDeviceSoftwareVersion = ""
        currentDeviceHardwareVersion = ""
        currentDeviceCharge = ""
        resetMessageError = ""
        ntripSizeParcel = ""
        ntripStatus = "Not connected"
        isStartingNtrip = false
        socketCodeError = nil
        singlePointMeasurement = nil
        correctedCoordinateWithFormula = nil
        rmxIsActive = false
        isBottomLaserSelected = true
        isBackLaserSelected = false
        model.disconnect()
        subscription.forEach { $0.cancel() }
        subscription.removeAll(keepingCapacity: true)
        configurePublishers()
    }
}
