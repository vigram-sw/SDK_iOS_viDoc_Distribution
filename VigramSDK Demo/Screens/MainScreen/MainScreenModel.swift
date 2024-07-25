//
//  MainScreenModel.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import Combine
import CoreBluetooth
import Foundation
import VigramSDK

class MainScreenModel {

    // MARK: Public properties

    public var ppkMeasurementsState: SinglePublisher<Bool>  { _ppkMeasurementsState.eraseToAnyPublisher() }
    public var ppkMeasurementsTimer: SinglePublisher<String> { _ppkMeasurementsTimer.eraseToAnyPublisher() }
    public var observableDeviceNames: SinglePublisher<[String]> { _observableDeviceNames.eraseToAnyPublisher() }
    public var configurationState: SinglePublisher<StatePeripheralConfiguration>  { _configurationState.eraseToAnyPublisher() }
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
    public lazy var helperErrorMessage: SinglePublisher<String> = vigramHelper.errorForUp

    // MARK: Private properties

    private let _singlePointMeasurement = Passthrough<Result<SinglePoint, Error>>()
    private let _singlePointTimer = Passthrough<String>()
    private let _ppkMeasurementsState = Passthrough<Bool>()
    private let _ppkMeasurementsTimer = Passthrough<String>()
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
    private let vigramHelper = VigramHelper.shared
    private var observableDevices = [CBPeripheral]()
    private var subscription = Set<AnyCancellable>()
    private var subscriptionSP = Set<AnyCancellable>()
    private var currentDevice: Peripheral?
    private var currentNtripTask: NtripTask?
    private var currentGGAMessage: GGAMessage?
    private var laserOffsetsBottom = [(String, SIMD3<Double>)]()
    private var laserOffsetsBack = [(String, SIMD3<Double>)]()
    private var cameraOffsets = [(String, SIMD3<Double>)]()
    private var totalRXMTime: Int?
    private var timerRXM: Timer?
    private var duration: Double?

    // MARK: Init

    init() {
        configurePublishers()
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
        mountPoint: String
    ) throws {
        if let currentGGAMessage = currentGGAMessage {
            try vigramHelper.connectToNTRIP(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                mountPoint: mountPoint,
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
        vigramHelper.changeStatusRXM(activate: activate)
    }

    func startRecordPPKMeasurements(){
        totalRXMTime = 0
        startRXMCountTimer()
        vigramHelper.startRecordPPKMeasurements()
    }

    func stopRecordPPKMeasurements(){
        vigramHelper.stopRecordPPKMeasurements()
        totalRXMTime = nil
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
                // viDoc state
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
        cameraOffsets =
        [
            ("Without laset: iPhoneXR", AntennaOffset.Camera.iPhoneXR),
            ("Without laset: iPhone11ProTop", AntennaOffset.Camera.iPhone11ProTop),
            ("Without laset: iPhone11ProMiddle", AntennaOffset.Camera.iPhone11ProMiddle),
            ("Without laset: iPhone11ProBottom", AntennaOffset.Camera.iPhone11ProBottom),
            ("Without laset: iPhone11ProMaxTop", AntennaOffset.Camera.iPhone11ProMaxTop),
            ("Without laset: iPhone11ProMaxMiddle", AntennaOffset.Camera.iPhone11ProMaxMiddle),
            ("Without laset: iPhone11ProMaxBottom", AntennaOffset.Camera.iPhone11ProMaxBottom),
            ("Without laset: iPhone12ProTop", AntennaOffset.Camera.iPhone12ProTop),
            ("Without laset: iPhone12ProMiddle", AntennaOffset.Camera.iPhone12ProMiddle),
            ("Without laset: iPhone12ProBottom", AntennaOffset.Camera.iPhone12ProBottom),
            ("Without laset: iPhone12ProMaxTop", AntennaOffset.Camera.iPhone12ProMaxTop),
            ("Without laset: iPhone12ProMaxMiddle", AntennaOffset.Camera.iPhone12ProMaxMiddle),
            ("Without laset: iPhone12ProMaxBottom", AntennaOffset.Camera.iPhone12ProMaxBottom),
            ("Without laset: iPhone13ProTop", AntennaOffset.Camera.iPhone13ProTop),
            ("Without laset: iPhone13ProMiddle", AntennaOffset.Camera.iPhone13ProMiddle),
            ("Without laset: iPhone13ProBottom", AntennaOffset.Camera.iPhone13ProBottom),
            ("Without laset: iPhone13ProMaxTop", AntennaOffset.Camera.iPhone13ProMaxTop),
            ("Without laset: iPhone13ProMaxMiddle", AntennaOffset.Camera.iPhone13ProMaxMiddle),
            ("Without laset: iPhone13ProMaxBottom", AntennaOffset.Camera.iPhone13ProMaxBottom),
            ("Without laset: iPhone14ProTop", AntennaOffset.Camera.iPhone14ProTop),
            ("Without laset: iPhone14ProMiddle", AntennaOffset.Camera.iPhone14ProMiddle),
            ("Without laset: iPhone14ProBottom", AntennaOffset.Camera.iPhone14ProBottom),
            ("Without laset: iPhone14ProMaxTop", AntennaOffset.Camera.iPhone14ProMaxTop),
            ("Without laset: iPhone14ProMaxMiddle", AntennaOffset.Camera.iPhone14ProMaxMiddle),
            ("Without laset: iPhone14ProMaxBottom", AntennaOffset.Camera.iPhone14ProMaxBottom),
            ("Without laset: iPadPro11TopOldDevice", AntennaOffset.Camera.iPadPro11TopOldDevice),
            ("Without laset: iPadPro11TopNewDevice", AntennaOffset.Camera.iPadPro11TopNewDevice),
            ("Without laset: iPadPro11BottomOldDevice", AntennaOffset.Camera.iPadPro11BottomOldDevice),
            ("Without laset: iPadPro11BottomNewDevice", AntennaOffset.Camera.iPadPro11BottomNewDevice)
        ]
        laserOffsetsBack.removeAll()
        laserOffsetsBack = [
            ("With laset: iPhoneXRBack", AntennaOffset.Laser.iPhoneXRBack),
            ("With laset: iPhone11ProBack", AntennaOffset.Laser.iPhone11ProBack),
            ("With laset: iPhone11ProMaxBack", AntennaOffset.Laser.iPhone11ProMaxBack),
            ("With laset: iPhone12ProBack", AntennaOffset.Laser.iPhone12ProBack),
            ("With laset: iPhone12ProMaxBack", AntennaOffset.Laser.iPhone12ProMaxBack),
            ("With laset: iPhone13ProBack", AntennaOffset.Laser.iPhone13ProBack),
            ("With laset: iPhone13ProMaxBack", AntennaOffset.Laser.iPhone13ProMaxBack),
            ("With laset: iPhone14ProBack", AntennaOffset.Laser.iPhone14ProBack),
            ("With laset: iPhone14ProMaxBack", AntennaOffset.Laser.iPhone14ProMaxBack)
        ]
        laserOffsetsBottom.removeAll()
        laserOffsetsBottom = [
            ("With laset: iPhoneXRBottom", AntennaOffset.Laser.iPhoneXRBottom),
            ("With laset: iPhone11ProBottom", AntennaOffset.Laser.iPhone11ProBottom),
            ("With laset: iPhone11ProMaxBottom", AntennaOffset.Laser.iPhone11ProMaxBottom),
            ("With laset: iPhone12ProBottom", AntennaOffset.Laser.iPhone12ProBottom),
            ("With laset: iPhone12ProMaxBottom", AntennaOffset.Laser.iPhone12ProMaxBottom),
            ("With laset: iPhone13ProBottom", AntennaOffset.Laser.iPhone13ProBottom),
            ("With laset: iPhone13ProMaxBottom", AntennaOffset.Laser.iPhone13ProMaxBottom),
            ("With laset: iPhone14ProBottom", AntennaOffset.Laser.iPhone14ProBottom),
            ("With laset: iPhone14ProMaxBottom", AntennaOffset.Laser.iPhone14ProMaxBottom),
            ("With laset: iPadPro11", AntennaOffset.Laser.iPadPro11)
        ]
    }
    
    func startRXMCountTimer() {
        timerRXM = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTimerRXM),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func updateTimerRXM() {
        if let totalRXMTime = totalRXMTime {
            _ppkMeasurementsTimer.send("Record time: \(timeFormatted(totalRXMTime))")
            self.totalRXMTime? += 1
        } else {
            if let timerRXM = timerRXM {
                timerRXM.invalidate()
                self.timerRXM = nil
                _ppkMeasurementsTimer.send("")
            }
        }
    }

    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
