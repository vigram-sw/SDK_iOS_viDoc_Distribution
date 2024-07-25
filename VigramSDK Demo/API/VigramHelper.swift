//
//  VigramHelper.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2020 Vigram. All rights reserved.
//

import Combine
import CoreBluetooth
import Foundation
import VigramSDK

final class VigramHelper: NSObject {

    // MARK: Public properties

    static let shared = VigramHelper()

    // MARK: Public properties

    public var observableDevices: SinglePublisher<[CBPeripheral]> { _observableDevices.eraseToAnyPublisher() }
    public var isConnectedDevice: SinglePublisher<Bool> { _isConnectedDevice.eraseToAnyPublisher() }
    public var isStartDevice: SinglePublisher<Bool> { _isStartDevice.eraseToAnyPublisher() }
    public var currentNtripTask: SinglePublisher<NtripTask> { _currentNtripTask.eraseToAnyPublisher() }
    public var spMeasurementTime: SinglePublisher<TimeInterval> { _spMeasurementTime.eraseToAnyPublisher() }
    public var errorForUp: SinglePublisher<String> { _errorForUp.eraseToAnyPublisher() }
    public var currentDevice: SinglePublisher<Peripheral> { _currentDevice.eraseToAnyPublisher() }

    // MARK: Private properties

    // Subject
    private let _observableDevices = Current<[CBPeripheral]>([])
    private let _isConnectedDevice = Current<Bool>(false)
    private let _isStartDevice = Current<Bool>(false)
    private let _currentDevice = Passthrough<Peripheral>()
    private let _currentNtripTask = Passthrough<NtripTask>()
    private let _spMeasurementTime = Passthrough<TimeInterval>()
    private let _errorForUp = Passthrough<String>()

    // SDK Services
    private var bluetoothService: BluetoothService?
    private var ntripService: NtripService?
    private var gpsService: GPSService?
    private var ntripTask: NtripTask?
    private var laserService: LaserService?
    private var environmentDataService: EnvironmentDataService?
    private var singlePointRecordingService: SinglePointRecordingService?
    // Stored properties
    private var subscription = Set<AnyCancellable>()
    private var peripheral: Peripheral?

    // MARK: Init

    private override init() {
        super.init()
        setDefaultParametres()
        authenticationToken()
    }

    // MARK: Public methods

    // MARK: Authentication

    func authenticationToken() {
        // ENTER TOKEN HERE
        // MARK: Token
        Vigram.initial(token: "")
            .check()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    if Configuration.debug {
                        print(error.localizedDescription)
                    }
                }
            }) { [weak self] resultAuthentication in
                switch resultAuthentication {
                case .success:
                    self?.bluetoothService = Vigram.bluetoothService()
                    self?.ntripService = Vigram.ntripService()
                    self?.startScanBluetooth()
                case .failure(let error):
                    if Configuration.debug {
                        print("[VigramHelper]: \(error.localizedDescription)")
                    }
                    self?._errorForUp.send(error.localizedDescription)
                }
            }.store(in: &subscription)
    }

    // MARK: BluetoothService

    func startScanBluetooth() {
        bluetoothService?.startScan()
        bluetoothService?.observeAvailableDevices()
            .sink { [weak self] devices in
                self?._observableDevices.send(devices)
            }.store(in: &subscription)
    }

    func conectTo(device peripheral: CBPeripheral) {
        // Uncomment if needed - CONFIGURATION
        /*
         let peripheralConfiguration = PeripheralConfiguration(
         rateOfChangeMessages: .hertz7,
         dynamicType: .stationary
         )
         */

        let logFile = createLogFile(nameDevice: peripheral.name, fileExtension: "txt", folder: "LOG")

        do {
            try self.peripheral = Vigram.peripheral(
                peripheral,
                log: logFile
                // Uncomment if needed - CONFIGURATION
                // configuration: peripheralConfiguration
            )
        } catch {
            if Configuration.debug {
                print("[VigramHelper]: \(error.localizedDescription)")
            }
        }

        bluetoothService?.connect(to: peripheral.identifier)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    guard let self = self else { return }
                    self._isConnectedDevice.send(true)
                    
                    if let peripheral = self.peripheral {
                        self._currentDevice.send(peripheral)
                    }

                    self.peripheral?.start()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                self._isStartDevice.send(true)
                            case .failure(let error):
                                self._isStartDevice.send(false)
                                if Configuration.debug {
                                    print("[VigramHelper]: \(error.localizedDescription)")
                                }
                            }
                        }) { _ in }.store(in: &self.subscription)
                case .failure(let error):
                    self?._isConnectedDevice.send(false)
                    if Configuration.debug {
                        print("[VigramHelper]: \(error.localizedDescription)")
                    }
                }
            }){ _ in }.store(in: &subscription)
    }

    func disconnect(){
        ntripTask?.disconnect()
        bluetoothService?.disconnect()
        _isStartDevice.send(false)
        _isConnectedDevice.send(false)
        peripheral = nil
        laserService = nil
        environmentDataService = nil
        singlePointRecordingService = nil
        subscription.forEach { $0.cancel() }
        subscription.removeAll(keepingCapacity: true)
        startScanBluetooth()
    }

    // MARK: Requests to viDoc

    func requestBattery() {
        peripheral?.requestBattery().sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                if Configuration.debug {
                    print("[VigramHelper]: \(error.localizedDescription)")
                }
            }
        }) { _ in }.store(in: &subscription)
    }

    func requestVersion() -> SingleEventPublisher<DeviceMessage.Version>? {
        peripheral?.requestVersion()
    }

    func resetDevice() {
        peripheral?.resetViDoc()
    }

    func setDynamicState(type: DynamicStateType) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.setDynamicState(type: type)
    }

    func getDynamicState() -> SingleEventPublisher<SatelliteMessage.DynamicState>? {
        peripheral?.getCurrentDynamicState()
    }

    func changeStatusNAVDOP(activate: Bool) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.changeStatusNAVDOP(activate: activate)
    }

    func changeStatusNAVPVT(activate: Bool) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.changeStatusNAVPVT(activate: activate)
    }

    func getCurrentStatusGNSS(satellite: NavigationSystemType) -> SingleEventPublisher<SatelliteMessage.StatusSattelite>? {
        peripheral?.getCurrentStatusGNSS(satellite: satellite)
    }

    func changeStatusGNSS(satellite: NavigationSystemType, activate: Bool) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.changeStatusGNSS(satellite: satellite, activate: activate)
    }

    func activateAllConstellationGNSS() -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.activateAllConstellationGNSS()
    }

    func getCurrentMinimumElevation() -> SingleEventPublisher<SatelliteMessage.Elevation>? {
        peripheral?.getCurrentMinimumElevation()
    }

    func setMinimumElevation(angle: ElevationValue) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.setMinimumElevation(angle: angle)
    }

    func setChangingRateOfMessages(_ rate: RateValue) -> SingleEventPublisher<SatelliteMessage.Acknowledge>? {
        peripheral?.setChangingRateOfMessages(rate)
    }

    func getChangingRateOfMessages() -> SingleEventPublisher<SatelliteMessage.ChangingRate>? {
        peripheral?.getChangingRateOfMessages()
    }

    // MARK: Laser Service

    func turnOnLaser(at typeOfLaser: LaserConfiguration.Position) -> SingleEventPublisher<Void>? {
        if laserService == nil {
            if let peripheral = self.peripheral {
                self.laserService = Vigram.laserService(peripheral: peripheral)
            }
        }

        return laserService?.turnLaserOn(at: typeOfLaser)
    }

    func turnOffLaser(at typeOfLaser: LaserConfiguration.Position) -> SingleEventPublisher<Void>? {
        if laserService == nil {
            if let peripheral = self.peripheral {
                self.laserService = Vigram.laserService(peripheral: peripheral)
            }
        }

        return laserService?.turnLaserOff(at: typeOfLaser)
    }

    func getLaserStatus() -> SingleEventPublisher<DeviceMessage.LaserState>?{
        if laserService == nil {
            if let peripheral = self.peripheral {
                self.laserService = Vigram.laserService(peripheral: peripheral)
            }
        }

        return laserService?.getLasersStatus()
    }

    func startLaser(with configuration: LaserConfiguration) -> SingleEventPublisher<DeviceMessage.Measurement>? {
        if laserService == nil {
            if let peripheral = self.peripheral {
                self.laserService = Vigram.laserService(peripheral: peripheral)
            }
        }

        return laserService?.record(configuration: configuration)
    }

    // MARK: NTRIP

    func connectToNTRIP (
        hostname: String,
        port: Int,
        username: String,
        password: String,
        mountPoint: String,
        ggaMessage: GGAMessage
    ) throws {
        ntripTask = nil
        let nci = NtripConnectionInformation.init(
            hostname: hostname,
            port: port,
            username: username,
            password: password
        )

        do {
            try ntripTask = ntripService?.task(
                for: nci,
                atMountPoint: mountPoint,
                message: ggaMessage
            )

            if let peripheral = self.peripheral, let bluetoothService = bluetoothService {
                gpsService = Vigram.gpsService(
                    peripheral: peripheral,
                    bluetoothService: bluetoothService,
                    correctionTask: ntripTask
                )
            }

            if let ntripTask = self.ntripTask {
                _currentNtripTask.send(ntripTask)
            }

            ntripTask?.resume().sink(receiveCompletion: { _ in }){ _ in }.store(in: &subscription)
        } catch {
            if Configuration.debug {
                print("[NTRIP]: \(error.localizedDescription)")
            }
        }
    }

    func reConnectToNTRIP() {
        gpsService?.reconnect()
    }

    func disconnectNtrip() {
        ntripTask?.disconnect()
    }

    func getMountpoints(for nci: NtripConnectionInformation) -> SingleEventPublisher<[NtripMountPoint]>? {
        ntripService?.mountpoints(for: nci)
    }

    // MARK: Single point

    func recordSinglePoint(
        for duration: TimeInterval,
        antennaDistanceToGround: Double = 0.0,
        useLaser: Bool = false,
        isBottomLaser: Bool = false,
        offsets: SIMD3<Double>,
        method: CoordinateCorrection.Method,
        isNewProtocol: Bool = false
    ) -> SingleEventPublisher<SinglePoint>? {
        guard let gpsService = gpsService, let peripheral = peripheral else { return nil }
        environmentDataService = nil
        if useLaser {
            guard let laserService = laserService else { return nil }
            environmentDataService = Vigram.environmentDataService(
                gpsService: gpsService,
                laserService: laserService,
                peripheral: peripheral,
                dynamicStateType: .stationary
            )
        } else {
            environmentDataService = Vigram.environmentDataService(
                gpsService: gpsService,
                peripheral: self.peripheral!,
                dynamicStateType: .stationary
            )
        }
        if let environmentDataService = self.environmentDataService {
            singlePointRecordingService = Vigram.singlePointRecordingService(
                environmentDataService: environmentDataService)
            
            singlePointRecordingService?.measurementTime
                .receive(on: DispatchQueue.main)
                .sink { [weak self] value in
                    self?._spMeasurementTime.send(value)
                }
                .store(in: &subscription)
        }
        
        if isNewProtocol {
            return singlePointRecordingService?.startMeasurement(duration: duration, updateInterval: 0.1, with: method)
        } else {
            return singlePointRecordingService?.record(duration: duration, updateInterval: 0.1, with: method)
        }
    }

    func stopSPMeasurement() {
        singlePointRecordingService?.stopMeasurement()
    }
    
    func cancelSPMeasurement() {
        singlePointRecordingService?.cancelMeasurement()
    }

    // MARK: RXM

    func changeStatusRXM(activate: Bool) {
        peripheral?.changeStatusRXM(activate: activate)
    }

    func startRecordPPKMeasurements() {
        do {
            if let ubxFile = try FileWorker.createFile(fileExtension: "ubx", folder: "PPK") {
                peripheral?.startRecordPPKMeasurements(url: ubxFile)
            } else {
                if Configuration.debug {
                    print("[FILE MANAGER]: Document map in local domain not found")
                }
            }
        } catch {
            if Configuration.debug {
                print("[FileWorker]: \(error.localizedDescription)")
            }
        }
    }

    func stopRecordPPKMeasurements() {
        peripheral?.stopRecordPPKMeasurements()
    }

    func getUBXFile(filename: String, pathName: String) -> URL? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        guard directory.count != 0 else {
            if Configuration.debug {
                print("[FILE MANAGER]: Document map in local domain not found")
            }
            return nil
        }

        var path = directory[0].appendingPathComponent(pathName)
        path = path.appendingPathComponent("\(filename)")

        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }
}
// MARK: - Private methods

private extension VigramHelper {
    func setDefaultParametres() {
        // DEFAULT RATE
        Configuration.defaultRate = .hertz7
        // DEBUG CONFIG
        #if DEBUG
        // MARK: Configuration
        Configuration.debug = false
        #endif
    }

    func createLogFile(nameDevice: String?, fileExtension: String, folder: String) -> URL? {
        var file: URL?

        guard let nameDevice = nameDevice else {
            if Configuration.debug {
                print("[VigramHelper]: Name current peripheral is not found")
            }
            return nil
        }

        do {
            file = try FileWorker.createFile(name: nameDevice, fileExtension: fileExtension, folder: folder)
        } catch {
            if Configuration.debug {
                print("[FileWorker]: \(error.localizedDescription)")
            }
        }

        return file
    }
}
