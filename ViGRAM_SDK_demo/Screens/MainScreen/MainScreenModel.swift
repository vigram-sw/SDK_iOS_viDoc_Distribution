//
//  MainScreenModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import Combine
import CoreBluetooth
import Foundation
import UIKit
import VigramSDK

class MainScreenModel {

    // MARK: Public properties

    public var currentDeviceType: SinglePublisher<DeviceMessage.Device> { _currentDeviceType.eraseToAnyPublisher() }
    public var ppkMeasurementsState: SinglePublisher<Bool>  { _ppkMeasurementsState.eraseToAnyPublisher() }
    public var ppkMeasurementsTimer: SinglePublisher<String> { _ppkMeasurementsTimer.eraseToAnyPublisher() }
    public var softwareUpdateState: SinglePublisher<StateUpdateSoftware>  { _softwareUpdateState.eraseToAnyPublisher() }
    public var softwareUpdateProgress: SinglePublisher<Double>  { _softwareUpdateProgress.eraseToAnyPublisher() }
    public var observableDeviceNames: SinglePublisher<[String]> { _observableDeviceNames.eraseToAnyPublisher() }
    public var configurationState: SinglePublisher<StatePeripheralConfiguration>  { _configurationState.eraseToAnyPublisher() }
    public var calibrationMessage: SinglePublisher<CalibrationMessage>  { _calibrationMessage.eraseToAnyPublisher() }
    public var resetState: SinglePublisher<StateResetViDoc>  { _resetState.eraseToAnyPublisher() }
    public var deviceMessage: SinglePublisher<DeviceMessage> { _deviceMessage.eraseToAnyPublisher() }
    public var nmeaMessage: SinglePublisher<NMEAMessage> { _nmeaMessage.eraseToAnyPublisher() }
    public var satelliteMessage: SinglePublisher<SatelliteMessage> { _satelliteMessage.eraseToAnyPublisher() }
    public var state: SinglePublisher<CBPeripheralState> { _state.eraseToAnyPublisher() }
    public var viDocState: SinglePublisher<StateViDoc> { _viDocState.eraseToAnyPublisher() }
    public var protocolVersion: SinglePublisher<Double> { _protocolVersion.eraseToAnyPublisher() }
    public var ntripData: SinglePublisher<Data> { _ntripData.eraseToAnyPublisher() }
    public var ntripState: SinglePublisher<StateNtripConnection> { _ntripState.eraseToAnyPublisher() }
    public var singlePointTimer: SinglePublisher<String> { _singlePointTimer.eraseToAnyPublisher() }
    public var singlePointMeasurement: SinglePublisher<Result<SinglePoint, Error>> { _singlePointMeasurement.eraseToAnyPublisher() }

    public lazy var isConnectedDevice: SinglePublisher<Bool> = vigramHelper.isConnectedDevice
    public lazy var isStartDevice: SinglePublisher<Bool> = vigramHelper.isStartDevice
    public lazy var nameDevice: SinglePublisher<String> = vigramHelper.nameDevice
    public lazy var serialNumberDevice: SinglePublisher<String> = vigramHelper.serialNumberDevice
    public lazy var helperErrorMessage: SinglePublisher<String> = vigramHelper.errorForUp

    // MARK: Private properties

    private let _singlePointMeasurement = Passthrough<Result<SinglePoint, Error>>()
    private let _singlePointTimer = Passthrough<String>()
    private let _ppkMeasurementsState = Passthrough<Bool>()
    private let _ppkMeasurementsTimer = Passthrough<String>()
    private let _softwareUpdateState = Passthrough<StateUpdateSoftware>()
    private let _softwareUpdateProgress = Current<Double>(0.0)
    private let _observableDeviceNames = Current<[String]>([])
    private let _isConnectedDevice = Current<Bool>(false)
    private let _deviceMessage = Passthrough<DeviceMessage>()
    private let _nmeaMessage = Passthrough<NMEAMessage>()
    private let _satelliteMessage = Passthrough<SatelliteMessage>()
    private let _state = Passthrough<CBPeripheralState>()
    private let _viDocState = Passthrough<StateViDoc>()
    private let _resetState = Passthrough<StateResetViDoc>()
    private let _protocolVersion = Passthrough<Double>()
    private let _ntripData = Passthrough<Data>()
    private let _ntripState = Passthrough<StateNtripConnection>()
    private let _configurationState = Passthrough<StatePeripheralConfiguration>()
    private let _calibrationMessage = Passthrough<CalibrationMessage>()
    private let _currentDeviceType = Passthrough<DeviceMessage.Device>()
    private let vigramHelper: VigramHelper
    private var observableDevices = [CBPeripheral]()
    private var subscription = Set<AnyCancellable>()
    private var subscriptionSP = Set<AnyCancellable>()
    private var currentDevice: Peripheral?
    private var currentNtripTask: NtripTask?
    private var currentGGAMessage: GGAMessage?
    private var currentDeviceVersion: DeviceVersion = .unknown
    private var laserOffsetsBottom = [(String, SIMD3<Double>)]()
    private var laserOffsetsBack = [(String, SIMD3<Double>)]()
    private var cameraOffsets = [(String, SIMD3<Double>)]()
    private var totalRXMTime: Int?
    private var timerRXM: Timer?
    private var duration: Double?

    // MARK: Init

    init(vigramHelper: VigramHelper) {
        self.vigramHelper = vigramHelper
        configurePublishers()
    }

    // MARK: Public methods

    func start() {
        vigramHelper.start()
    }


    // MARK: Device

    func connectToDevice(name: String) {
        if let deviceToConnect = observableDevices.first(where: { $0.name == name }) {
            vigramHelper.conectTo(device: deviceToConnect)
        } else {
            if Configuration.debug {
                print("[MainScreenModel]: Name current peripheral is not found")
            }
        }
    }

    func disconnect() {
        stopRXMCountTimer()
        vigramHelper.disconnect()
        subscription.forEach { $0.cancel() }
        subscription.removeAll(keepingCapacity: true)
        configurePublishers()
    }

    func requestBattery() {
        vigramHelper.requestBattery()
    }

    func requestVersion() -> SingleEventPublisher<DeviceMessage.Version>? {
        vigramHelper.requestVersion()
    }
    
    func resetDevice() {
        vigramHelper.resetDevice()
    }

//    func requestWriteDeviceHardware(firstFrameByte: UInt8, secondFrameByte: UInt8) -> SingleEventPublisher<Void>? {
//        vigramHelper.requestWriteDeviceHardware(firstFrameByte: firstFrameByte, secondFrameByte: secondFrameByte)
//    }
//
//    func requestWriteDevice(number: String) -> SingleEventPublisher<Void>? {
//        vigramHelper.requestWriteDevice(number: number)
//    }

//    func requestGetCurrentDevice() {
//        vigramHelper.requestGetCurrentDevice()
//    }
    
    func setDynamicState(type: DynamicStateType) {
        vigramHelper.setDynamicState(type: type)?
            .sink(receiveCompletion: { _ in }) { [weak self] _ in
                self?.getDynamicState()
            }.store(in: &subscription)
    }
    
    func getDynamicState() {
        vigramHelper.getDynamicState()?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func changeStatusNAVDOP(activate: Bool){
        vigramHelper.changeStatusNAVDOP(activate: activate)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func changeStatusNAVPVT(activate: Bool){
        vigramHelper.changeStatusNAVPVT(activate: activate)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }

    func changeStatusGSTandPVTndDOPmessages(activate: Bool) {
    }

    func getCurrentStatusGNSS(satellite: NavigationSystemType) {
        vigramHelper.getCurrentStatusGNSS(satellite: satellite)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }

    func changeStatusGNSS(satellite: NavigationSystemType, activate: Bool) {
        vigramHelper.changeStatusGNSS(satellite: satellite, activate: activate)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func activateAllConstellationGNSS(){
        vigramHelper.activateAllConstellationGNSS()?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func getCurrentMinimumElevation() {
        vigramHelper.getCurrentMinimumElevation()?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func setMinimumElevation(angle: ElevationValue) {
        vigramHelper.setMinimumElevation(angle: angle)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }
    
    func setChangingRateOfMessages(_ rate: RateValue) {
        vigramHelper.setChangingRateOfMessages(rate)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }

    func getChangingRateOfMessages() {
        vigramHelper.getChangingRateOfMessages()?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }

    func requestChange(baudrate: DeviceMessage.Baudrate) {
        vigramHelper.requestChange(baudrate: baudrate)?
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: &subscription)
    }

    func requestIMUAngle() -> SingleEventPublisher<DeviceMessage.IMUAngle>? {
        vigramHelper.requestIMUAngle()
    }

    func requestIMUDataAcc() -> SingleEventPublisher<DeviceMessage.IMUACC>? {
        vigramHelper.requestIMUDataAcc()
    }

    func requestIMURotation() -> SingleEventPublisher<DeviceMessage.IMURotation>? {
        vigramHelper.requestIMURotation()
    }

    func requestIMURotationRaw() -> SingleEventPublisher<DeviceMessage.IMURotationRaw>? {
        vigramHelper.requestIMURotationRaw()
    }

    func requestIMUMagneticRaw() -> SingleEventPublisher<DeviceMessage.IMUMagneticRaw>? {
        vigramHelper.requestIMUMagneticRaw()
    }

    func requestIMUTemp() -> SingleEventPublisher<DeviceMessage.IMUTemp>? {
        vigramHelper.requestIMUTemp()
    }
    
    func requestIMUCalibration(autoMode: Bool) -> SingleEventPublisher<Void>? {
        vigramHelper.requestIMUCalibration(autoMode: autoMode)
    }

    func nextStepManualIMUCalibration() -> SingleEventPublisher<Void>? {
        vigramHelper.nextStepManualIMUCalibration()
    }

    func exitManualIMUCalibration() -> SingleEventPublisher<Void>? {
        vigramHelper.exitManualIMUCalibration()
    }
    
    func requestIMUCalibrationStatus() -> SingleEventPublisher<DeviceMessage.IMUCalibrationStatus>? {
        vigramHelper.requestIMUCalibrationStatus()
    }

    // MARK: NTRIP

    func getAllNtripCredential() -> [NtripCredentials] {
        do {
            if let data =  UserDefaults.standard.data(forKey: "ntrip") {
                return try JSONDecoder().decode([NtripCredentials].self, from: data)
            } else {
                if Configuration.debug {
                    print("[User Defaults]: No NTRIP credentials data")
                }
                return []
            }
        }
        catch {
            if Configuration.debug {
                print("[User Defaults]: \(error.localizedDescription)")
            }
            return []
        }
    }

    func connectToNTRIP (
        hostname: String,
        port: Int,
        username: String,
        password: String,
        mountPoint: String,
        forceHTTPSconnection: Bool
    ) throws {
        if let currentGGAMessage = currentGGAMessage {
            try vigramHelper.connectToNTRIP(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                mountPoint: mountPoint,
                forceHTTPSconnection: forceHTTPSconnection,
                ggaMessage: currentGGAMessage
            )
        }
    }

    func reConnectToNTRIP(){
        vigramHelper.reConnectToNTRIP()
    }

    func disconnectNtrip() {
        vigramHelper.disconnectNtrip()
    }

    func getMountpoints(for nci: NtripConnectionInformation) -> SingleEventPublisher<[NtripMountPoint]>? {
        vigramHelper.getMountpoints(for: nci)
    }

    // MARK: LASER
    
    func turnOnLaser(at typeOfLaser: LaserConfiguration.Position) -> SingleEventPublisher<Void>? {
        vigramHelper.turnOnLaser(at: typeOfLaser)
    }

    func turnOffLaser(at typeOfLaser: LaserConfiguration.Position) -> SingleEventPublisher<Void>? {
        vigramHelper.turnOffLaser(at: typeOfLaser)
    }
    
    func getLasersStatus() -> SingleEventPublisher<DeviceMessage.LaserState>? {
        vigramHelper.getLaserStatus()
    }

    func startLaser(with configuration: LaserConfiguration) -> SingleEventPublisher<DeviceMessage.Measurement>? {
        vigramHelper.startLaser(with: configuration)
    }
    
    // MARK: SINGLE POINT
    
    func chouseAllOffsets(with position: LaserConfiguration.Position) -> [(String, SIMD3<Double>)] {
        getAllOffsets()
        return position == .back ? laserOffsetsBack : laserOffsetsBottom
    }

    func chouseCameraOffsets() -> [(String, SIMD3<Double>)] {
        getAllOffsets()
        return cameraOffsets
    }

    func recordWithLaser(duration: Double, configuration: LaserConfiguration, offsets: SIMD3<Double>, isNewProtocol: Bool = false) {
        if duration > 0 {
            self.duration = duration
        } else {
            self.duration = nil
        }
        let method = CoordinateCorrection.Method.laser(
            configuration: configuration,
            antennaOffset: offsets,
            useDeviceMotion: true
        )
        vigramHelper.recordSinglePoint(
            for: duration,
            antennaDistanceToGround: 0.0,
            useLaser: true,
            isBottomLaser: configuration.position == .bottom,
            offsets: offsets,
            method: method,
            isNewProtocol: isNewProtocol
        )?.sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._singlePointMeasurement.send(.failure(error))
                case .finished:
                    break
                }
        } receiveValue: { [weak self] singlePoint in
            self?._singlePointMeasurement.send(.success(singlePoint))
        }.store(in: &subscription)
    }

    func recordWithoutLaser(duration: Double, antennaDistanceToGround: Double, offsets: SIMD3<Double>, isNewProtocol: Bool = false) {
        if duration > 0 {
            self.duration = duration
        } else {
            self.duration = nil
        }
        let method = CoordinateCorrection.Method.constant(distanceFromAntennaToGround: antennaDistanceToGround)
        vigramHelper.recordSinglePoint(
            for: duration,
            antennaDistanceToGround: antennaDistanceToGround,
            useLaser: false,
            isBottomLaser: true,
            offsets: offsets,
            method: method,
            isNewProtocol: isNewProtocol
        )?.sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                self?._singlePointMeasurement.send(.failure(error))
            case .finished:
                break
            }
        } receiveValue: { [weak self] singlePoint in
            self?._singlePointMeasurement.send(.success(singlePoint))
        }.store(in: &subscription)
    }
    
    func stopSPMeasurement() {
        vigramHelper.stopSPMeasurement()
        subscriptionSP.forEach { $0.cancel() }
        subscriptionSP.removeAll()
    }

    func cancelSPMeasurement() {
        vigramHelper.cancelSPMeasurement()
        subscriptionSP.forEach { $0.cancel() }
        subscriptionSP.removeAll()
    }

    // MARK: RXM

    func changeStatusRXM(activate: Bool) {
        if !activate {
            stopRXMCountTimer()
        }
        vigramHelper.changeStatusRXM(activate: activate)
    }

    func startRecordPPKMeasurements(){
        startRXMCountTimer()
        vigramHelper.startRecordPPKMeasurements()
    }

    func stopRecordPPKMeasurements(){
        vigramHelper.stopRecordPPKMeasurements()
        stopRXMCountTimer()
    }
    
    func getAllUBXFiles()  -> Result<[String], Error>  {
        let result = FileWorker.checkIsExist(folder: "PPK")
        switch result {
        case .success(let path):
            do {
                let items = try FileWorker.getListOfItemsFor(path: path)
                var listNamesOfUBXFiles = [String]()
                for item in items {
                    listNamesOfUBXFiles.append(item)
                }
                return .success(listNamesOfUBXFiles)
            } catch {
                if Configuration.debug {
                    print("[FileWorker]: \(error.localizedDescription)")
                }
                return .failure(error)
            }
        case .failure(let error):
            if Configuration.debug {
                print("[FileWorker]: \(error.localizedDescription)")
            }
            return .failure(error)
        }
    }
    
    func getUBXFile(filename: String, pathName: String) -> URL? {
        vigramHelper.getUBXFile(filename: filename, pathName: pathName)
    }
    
    // MARK: Identity replacement

    func getNewIdentity(isReset: Bool) -> SingleEventPublisher<Result<Bool, Error>>? {
        vigramHelper.getNewIdentity(isReset: isReset)
    }
}
// MARK: - Private methods

private extension MainScreenModel {
    func configurePublishers() {
        // MARK: Observable CBPeripherals
        vigramHelper.observableDevices
            .sink { [weak self] devices in
                self?.observableDevices.removeAll()
                self?.observableDevices = devices
                self?._observableDeviceNames.send(devices.compactMap{ $0.name })
            }.store(in: &subscription)
        
        // MARK: Peripheral
        vigramHelper.currentDevice
            .sink { [weak self] currentDevice in
                guard let self = self else { return }
                self.currentDevice = currentDevice
                // Software update
                currentDevice.softwareUpdateState?.sink { [weak self] state in
                    self?._softwareUpdateState.send(state)
                }.store(in: &self.subscription)
                currentDevice.softwareUpdateProgress?.sink { [weak self] state in
                    self?._softwareUpdateProgress.send(state)
                }.store(in: &self.subscription)
                // NMEA messages
                currentDevice.nmea.sink { [weak self] message in
                    self?._nmeaMessage.send(message)
                    if let ggaMessage = message as? GGAMessage {
                        self?.currentGGAMessage = ggaMessage
                    }
                }.store(in: &self.subscription)
                // Device messages
                currentDevice.deviceMessages.sink { [weak self] message in
                    self?._deviceMessage.send(message)
                }.store(in: &self.subscription)
                // Satellite messages
                currentDevice.satelliteMessages.sink { [weak self] message in
                    self?._satelliteMessage.send(message)
                }.store(in: &self.subscription)
                // Configuration
                currentDevice.configurationState.sink { [weak self] state in
                    self?._configurationState.send(state)
                }.store(in: &self.subscription)
                // Reset
                currentDevice.viDocResetState.sink { [weak self] state in
                    self?._resetState.send(state)
                }.store(in: &self.subscription)
                // State
                currentDevice.viDocState.sink { [weak self] state in
                    self?._viDocState.send(state)
                }.store(in: &self.subscription)
                // Connection state
                currentDevice.state.sink { [weak self] state in
                    self?._state.send(state)
                }.store(in: &self.subscription)
                // PPK
                currentDevice.ppkMeasurementsState.sink { [weak self] state in
                    self?._ppkMeasurementsState.send(state)
                }.store(in: &self.subscription)
                // Protocol
                currentDevice.protocolVersion.sink { [weak self] state in
                    self?._protocolVersion.send(state)
                }.store(in: &self.subscription)
                // Calibration
                currentDevice.calibrationMessage.sink { [weak self] state in
                    self?._calibrationMessage.send(state)
                }.store(in: &self.subscription)
                // Device type
                currentDevice.currentDevice.sink { [weak self] value in
                    self?.currentDeviceVersion = value.typeOfDevice
                    self?._currentDeviceType.send(value)
                }.store(in: &self.subscription)
            }.store(in: &subscription)

        // MARK: NTRIP
        vigramHelper.currentNtripTask
            .sink { [weak self] currentNtripTask in
                guard let self = self else { return }
                self.currentNtripTask = currentNtripTask
                // NTRIP data
                currentNtripTask.data.sink { [weak self] data in
                    switch data {
                    case .success(let data):
                        self?._ntripData.send(data)
                    case .failure(let error):
                        if Configuration.debug {
                            print("[NTRIP]: \(error.localizedDescription)")
                        }
                    }
                }.store(in: &self.subscription)
                // NTRIP State
                currentNtripTask.ntripState.sink { [weak self] state in
                    self?._ntripState.send(state)
                }.store(in: &self.subscription)
            }.store(in: &subscription)
        
        // MARK: Single Point
        vigramHelper.spMeasurementTime
            .sink { [weak self] value in
                if let duration = self?.duration {
                    let resultTimeInterval = duration - value
                    if resultTimeInterval > 0 {
                        if let timeString = self?.timeFormatted(Int(resultTimeInterval)) {
                            self?._singlePointTimer.send(timeString)
                        }
                    } else {
                        self?._singlePointTimer.send("")
                    }
                } else {
                    if let timeString = self?.timeFormatted(Int(value)) {
                        self?._singlePointTimer.send(timeString)
                    }
                }
            }.store(in: &subscription)
    }

    func getAllOffsets() {
        cameraOffsets.removeAll()
        let cameraPrefix = currentCameraOffsetPresetPrefix()
        switch currentCameraOffsetPresetFamily() {
        case .spcPlus:
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12Pro",
                top: AntennaOffset.SPCPlus.iPhone12ProTop,
                middle: AntennaOffset.SPCPlus.iPhone12ProMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone12ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12ProMax",
                top: AntennaOffset.SPCPlus.iPhone12ProMaxTop,
                middle: AntennaOffset.SPCPlus.iPhone12ProMaxMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone12ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13Pro",
                top: AntennaOffset.SPCPlus.iPhone13ProTop,
                middle: AntennaOffset.SPCPlus.iPhone13ProMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone13ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13ProMax",
                top: AntennaOffset.SPCPlus.iPhone13ProMaxTop,
                middle: AntennaOffset.SPCPlus.iPhone13ProMaxMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone13ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14Pro",
                top: AntennaOffset.SPCPlus.iPhone14ProTop,
                middle: AntennaOffset.SPCPlus.iPhone14ProMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone14ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14ProMax",
                top: AntennaOffset.SPCPlus.iPhone14ProMaxTop,
                middle: AntennaOffset.SPCPlus.iPhone14ProMaxMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone14ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone15Pro",
                top: AntennaOffset.SPCPlus.iPhone15ProTop,
                middle: AntennaOffset.SPCPlus.iPhone15ProMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone15ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone15ProMax",
                top: AntennaOffset.SPCPlus.iPhone15ProMaxTop,
                middle: AntennaOffset.SPCPlus.iPhone15ProMaxMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone15ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone16Pro",
                top: AntennaOffset.SPCPlus.iPhone16ProTop,
                middle: AntennaOffset.SPCPlus.iPhone16ProMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone16ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone16ProMax",
                top: AntennaOffset.SPCPlus.iPhone16ProMaxTop,
                middle: AntennaOffset.SPCPlus.iPhone16ProMaxMiddle,
                bottom: AntennaOffset.SPCPlus.iPhone16ProMaxBottom,
                to: &cameraOffsets
            )
            appendTabletCameraOffsets(
                prefix: cameraPrefix,
                device: "iPadPro11",
                top: AntennaOffset.SPCPlus.iPadPro11Top,
                middle: AntennaOffset.SPCPlus.iPadPro11Middle,
                to: &cameraOffsets
            )
        case .spcPlusLight:
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12Pro",
                top: AntennaOffset.SPCPlusLight.iPhone12ProTop,
                middle: AntennaOffset.SPCPlusLight.iPhone12ProMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone12ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12ProMax",
                top: AntennaOffset.SPCPlusLight.iPhone12ProMaxTop,
                middle: AntennaOffset.SPCPlusLight.iPhone12ProMaxMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone12ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13Pro",
                top: AntennaOffset.SPCPlusLight.iPhone13ProTop,
                middle: AntennaOffset.SPCPlusLight.iPhone13ProMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone13ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13ProMax",
                top: AntennaOffset.SPCPlusLight.iPhone13ProMaxTop,
                middle: AntennaOffset.SPCPlusLight.iPhone13ProMaxMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone13ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14Pro",
                top: AntennaOffset.SPCPlusLight.iPhone14ProTop,
                middle: AntennaOffset.SPCPlusLight.iPhone14ProMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone14ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14ProMax",
                top: AntennaOffset.SPCPlusLight.iPhone14ProMaxTop,
                middle: AntennaOffset.SPCPlusLight.iPhone14ProMaxMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone14ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone15Pro",
                top: AntennaOffset.SPCPlusLight.iPhone15ProTop,
                middle: AntennaOffset.SPCPlusLight.iPhone15ProMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone15ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone15ProMax",
                top: AntennaOffset.SPCPlusLight.iPhone15ProMaxTop,
                middle: AntennaOffset.SPCPlusLight.iPhone15ProMaxMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone15ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone16Pro",
                top: AntennaOffset.SPCPlusLight.iPhone16ProTop,
                middle: AntennaOffset.SPCPlusLight.iPhone16ProMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone16ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone16ProMax",
                top: AntennaOffset.SPCPlusLight.iPhone16ProMaxTop,
                middle: AntennaOffset.SPCPlusLight.iPhone16ProMaxMiddle,
                bottom: AntennaOffset.SPCPlusLight.iPhone16ProMaxBottom,
                to: &cameraOffsets
            )
            appendTabletCameraOffsets(
                prefix: cameraPrefix,
                device: "iPadPro11",
                top: AntennaOffset.SPCPlusLight.iPadPro11Top,
                middle: AntennaOffset.SPCPlusLight.iPadPro11Middle,
                to: &cameraOffsets
            )
        case .spc:
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone11Pro",
                top: AntennaOffset.SPC.iPhone11ProTop,
                middle: AntennaOffset.SPC.iPhone11ProMiddle,
                bottom: AntennaOffset.SPC.iPhone11ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone11ProMax",
                top: AntennaOffset.SPC.iPhone11ProMaxTop,
                middle: AntennaOffset.SPC.iPhone11ProMaxMiddle,
                bottom: AntennaOffset.SPC.iPhone11ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12Pro",
                top: AntennaOffset.SPC.iPhone12ProTop,
                middle: AntennaOffset.SPC.iPhone12ProMiddle,
                bottom: AntennaOffset.SPC.iPhone12ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone12ProMax",
                top: AntennaOffset.SPC.iPhone12ProMaxTop,
                middle: AntennaOffset.SPC.iPhone12ProMaxMiddle,
                bottom: AntennaOffset.SPC.iPhone12ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13Pro",
                top: AntennaOffset.SPC.iPhone13ProTop,
                middle: AntennaOffset.SPC.iPhone13ProMiddle,
                bottom: AntennaOffset.SPC.iPhone13ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone13ProMax",
                top: AntennaOffset.SPC.iPhone13ProMaxTop,
                middle: AntennaOffset.SPC.iPhone13ProMaxMiddle,
                bottom: AntennaOffset.SPC.iPhone13ProMaxBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14Pro",
                top: AntennaOffset.SPC.iPhone14ProTop,
                middle: AntennaOffset.SPC.iPhone14ProMiddle,
                bottom: AntennaOffset.SPC.iPhone14ProBottom,
                to: &cameraOffsets
            )
            appendCameraOffsets(
                prefix: cameraPrefix,
                device: "iPhone14ProMax",
                top: AntennaOffset.SPC.iPhone14ProMaxTop,
                middle: AntennaOffset.SPC.iPhone14ProMaxMiddle,
                bottom: AntennaOffset.SPC.iPhone14ProMaxBottom,
                to: &cameraOffsets
            )
            appendTabletCameraOffsets(
                prefix: cameraPrefix,
                device: "iPadPro11",
                top: AntennaOffset.SPC.iPadPro11Top,
                middle: AntennaOffset.SPC.iPadPro11Middle,
                to: &cameraOffsets
            )
        }
        laserOffsetsBack.removeAll()
        laserOffsetsBack = [
            ("With laser: AutoBack", currentLaserOffset(at: .back, fallback: AntennaOffset.Laser.defaultBack)),
            ("With laser: DefaultBack", AntennaOffset.Laser.defaultBack),
        ]
        laserOffsetsBottom.removeAll()
        laserOffsetsBottom = [
            ("With laser: DefaultBottom", AntennaOffset.Laser.defaultBottom),
            ("With laser: iPadPro11", AntennaOffset.Laser.iPadPro11)
        ]
    }

    private enum CameraOffsetPresetFamily {
        case spc
        case spcPlus
        case spcPlusLight
    }

    private func currentLaserOffset(
        at position: LaserConfiguration.Position,
        fallback: SIMD3<Double>
    ) -> SIMD3<Double> {
        switch UIDevice.current.laserAntennaOffsetResult(at: position) {
        case .success(let offset):
            return offset
        case .failure:
            return fallback
        }
    }

    private func currentCameraOffsetPresetFamily() -> CameraOffsetPresetFamily {
        switch currentDeviceVersion {
        case .viDocOldDevice:
            return .spcPlus
        case .viDocLight:
            return .spcPlusLight
        case .viDoc, .viDocWithOldSoftware, .unknown:
            return .spc
        @unknown default:
            return .spc
        }
    }

    private func currentCameraOffsetPresetPrefix() -> String {
        switch currentCameraOffsetPresetFamily() {
        case .spcPlus:
            return "Without laser: SPC+"
        case .spcPlusLight:
            return "Without laser: SPC+ Light"
        case .spc:
            return "Without laser: SPC"
        }
    }

    private func appendCameraOffsets(
        prefix: String,
        device: String,
        top: SIMD3<Double>,
        middle: SIMD3<Double>,
        bottom: SIMD3<Double>,
        to offsets: inout [(String, SIMD3<Double>)]
    ) {
        offsets.append(("\(prefix) \(device)Top", top))
        offsets.append(("\(prefix) \(device)Middle", middle))
        offsets.append(("\(prefix) \(device)Bottom", bottom))
    }

    private func appendTabletCameraOffsets(
        prefix: String,
        device: String,
        top: SIMD3<Double>,
        middle: SIMD3<Double>,
        to offsets: inout [(String, SIMD3<Double>)]
    ) {
        offsets.append(("\(prefix) \(device)Top", top))
        offsets.append(("\(prefix) \(device)Middle", middle))
    }
    
    func startRXMCountTimer() {
        stopRXMCountTimer(clearDisplay: false)
        totalRXMTime = 0
        timerRXM = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTimerRXM),
            userInfo: nil,
            repeats: true
        )
    }

    func stopRXMCountTimer(clearDisplay: Bool = true) {
        timerRXM?.invalidate()
        timerRXM = nil
        totalRXMTime = nil
        if clearDisplay {
            _ppkMeasurementsTimer.send("")
        }
    }
    
    @objc private func updateTimerRXM() {
        if let totalRXMTime = totalRXMTime {
            _ppkMeasurementsTimer.send("Record time: \(timeFormatted(totalRXMTime))")
            self.totalRXMTime? += 1
        } else {
            stopRXMCountTimer()
        }
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
