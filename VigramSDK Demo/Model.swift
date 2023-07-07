//
//  Model.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 03.08.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import Combine
import CoreBluetooth
import Foundation
import VigramSDK
import UIKit
import CoreMotion
import SwiftUI

class Model: ObservableObject {

    // MARK: Nested types

    struct NtripCredentials: Codable, Equatable, Hashable {
        var host: String
        var port: Int
        var login: String
        var pass: String
        var mountpoint: String
    }

    // MARK: Publishers properties

    @Published var flash = false
    @Published var needUpdate = false
    @Published var statusUpdate = ""
    @Published var progressUpdate = ""
    @Published var timerValueStr = ""
    @Published var timerBackValueStr = ""
    @Published var rawxMessage = ""
    @Published var sfrbxMessage = ""
    @Published var titleAlert = ""
    @Published var dynamicState = " "
    @Published var messageAlert = ""
    @Published var showingAlert = false
    @Published var isSharePresented: Bool = false
    @Published var peripherals = [CBPeripheral]()
    @Published var fileLinkForUBXFile: URL?
    @Published var listOfUBXFiles = [String]()
    @Published var peripheral: Peripheral?

    @Published var atMountPoint = ""
    @Published var hostname = ""
    @Published var port = ""
    @Published var username = ""
    @Published var password = ""
    @Published var ntripCridentials = [NtripCredentials]()
    
    @Published var periphiralState: CBPeripheralState = .disconnected
    @Published var isConnectedDevice = false
    @Published var isStartingDevice = false
    @Published var correction = ""
    @Published var vertAcc = ""
    @Published var horAcc = ""
    @Published var distance = ""
    @Published var connected = false
    @Published var nmeaReady = false
    @Published var ntripStatus = "Not connected"
    @Published var lat = ""
    @Published var lon = ""
    @Published var satelliteGNSS = ""
    @Published var satelliteStatusGNSS = ""
    @Published var elevation = ""
    @Published var countSatellite = ""
    @Published var pdop = ""
    @Published var vdop = ""
    @Published var hdop = ""
    @Published var tdop = ""
    @Published var gdop = ""
    @Published var nVelocity = ""
    @Published var eVelocity = ""
    @Published var dVelocity = ""
    @Published var allAvailableSoftwareVersion = [DeviceMessage.Version.Software]()
    @Published var currentSoftwareVersion = ""
    @Published var currentHardwareVersion = ""
    @Published var currentBatteryCharge = ""
    @Published var lonAccErr = ""
    @Published var latAccErr = ""
    @Published var currentOffsetsString = "With laset: iPhone14ProMaxBottom"
    @Published var currentOffsets = AntennaOffset.Laser.iPhone14ProMaxBottom
    @Published var singlePointMeasurement: SinglePoint?
    @Published var durationStr = "5"
    @Published var distanceOfGroundStr = "50"

    @Published var currentRate = ""
    @Published var configuring = false
    @Published var rmxIsActive = false
    @Published var viDocState = ""
    @Published var resetMessageError = ""
    @Published var viDocIsReseting = false
    @Published var isNewDevice = true
    @Published var isOldDevice = false
    @Published var isBottomLaser = true
    @Published var isBackLaser = false
    @Published var useLaser = true
    @Published var withoutLaset = false
    @Published var ntripStarting = false
    @Published var rtkStatus = ""
    @Published var currentTimeString = ""
    @Published var unixTimeString = ""
    @Published var gnssTimeString = ""

    // MARK: Private properties

    private(set) var resetWithReconnect = false
    private var nci: NtripConnectionInformation?
    private var failDisconnect = false
    private var nameDevice: String?
    private var bluetoothService = Vigram.bluetoothService()
    private var subscription = Set<AnyCancellable>()
    private var ggamessage: GGAMessage?
    private var normalDisconnect = false
    private var timerRequestBattery = Timer()
    private var ntripService = Vigram.ntripService()
    private var gpsService: GPSService?
    private var task: NtripTask?
    private var laser: LaserService?
    private var timer: Timer?
    private var timerBack: Timer?
    private var totalTime: Int?
    private var totalBackTime: Int?
    private var iss = true
    private var mount = [NtripMountPoint]()
    private var socketCodeError: Int?
    let dateFormatter = DateFormatter()
    let dateFormatter2 = DateFormatter()

    let laserOffsetsBottom = [
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
    
    let laserOffsetsBack = [
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

    let cameraOffsets = [
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
        ("Without laset: iPhone14Pro", AntennaOffset.Camera.iPhone14Pro),
        ("Without laset: iPhone14ProMaxTop", AntennaOffset.Camera.iPhone14ProMaxTop),
        ("Without laset: iPhone14ProMaxMiddle", AntennaOffset.Camera.iPhone14ProMaxMiddle),
        ("Without laset: iPhone14ProMaxBottom", AntennaOffset.Camera.iPhone14ProMaxBottom),
        ("Without laset: iPadPro11TopOldDevice", AntennaOffset.Camera.iPadPro11TopOldDevice),
        ("Without laset: iPadPro11TopNewDevice", AntennaOffset.Camera.iPadPro11TopNewDevice),
        ("Without laset: iPadPro11BottomOldDevice", AntennaOffset.Camera.iPadPro11BottomOldDevice),
        ("Without laset: iPadPro11BottomNewDevice", AntennaOffset.Camera.iPadPro11BottomNewDevice)
    ]
    
    var currentAllOffsets = [(String, SIMD3<Double>)]()
    
    // MARK: Init

    init() {
        
        // DEFAULT RATE
        Configuration.defaultRate = .hertz7
        // DEBUG CONFIG
        Configuration.debug = true
//        Configuration.maximumSinglePointVerticalAccuracy = 10
//        Configuration.maximumSinglePointAltitudeDifference = 10
//        Configuration.maximumSinglePointHorizontalAccuracy = 10
        // FORCE UPDATE
        Configuration.forceUpdate = false
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        dateFormatter2.dateFormat = "HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

        // Create directory for firmware
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent("Firmware")
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }

        Vigram.softwareService().getAllAvailableSoftware()
            .sink { _ in } receiveValue: { [unowned self] softwareArray in
                self.allAvailableSoftwareVersion.removeAll()
                softwareArray.forEach({ [unowned self] software in
                    self.allAvailableSoftwareVersion.append(software)
                })
            }
            .store(in: &subscription)

        let tokenIsValid = Vigram.tokenIsValid()

        switch tokenIsValid {
        case .success(let result):
            if result == true {
                self.startScanBluetooth()
            } else {
                authentificationToken()
            }
        case .failure(_):
            authentificationToken()
        }
        currentAllOffsets = laserOffsetsBottom

        do {
            if let data =  UserDefaults.standard.data(forKey: "ntrip") {
                let res = try JSONDecoder().decode([NtripCredentials].self, from: data)
                if !res.isEmpty {
                    ntripCridentials = res
                }
            } else {
                print("[User Defaults]: No ntrip cridentials data")
            }
        }
        catch {
            print("[User Defaults]: \(error)")
        }
    }

    // MARK: Public methods

    func setForceUpdateSoftware(){
        Configuration.forceUpdate = true
        titleAlert = "Notification"
        messageAlert = """
            Please restart viDoc to start update.
            Note: If the viDoc doesn't have the bootloader, the installation of the software is not possible.
        """
        showingAlert = true
    }

    func authentificationToken() {
        // ENTER TOKEN HERE
        // NOTICE: don't forget to change the bundle
        Vigram.initial(token: "").check()
            .sink { _ in } receiveValue: { [unowned self] result in
                switch(result){
                case.success(let resultSuccess):
                    if resultSuccess {
                        self.startScanBluetooth()
                    } else {
                        self.titleAlert = "Authentication is failure"
                        self.messageAlert = "Please connect to web for authentication token"
                        self.showingAlert = true
                    }
                case .failure(_):
                    self.titleAlert = "Authentication is failure"
                    self.messageAlert = "Please connect to web for authentication token"
                    self.showingAlert = true
                }
            }
            .store(in: &subscription)
    }

    private func startScanBluetooth() {
        bluetoothService.startScan()
        bluetoothService.observeAvailableDevices()
            .sink(receiveValue: { [unowned self] peripherals in
                self.peripherals = peripherals
            })
            .store(in: &subscription)
    }

    func installSoftware(_ software: DeviceMessage.Version.Software) {
        peripheral?.setUpdateSoftwareToNextStartup(true, version: software)
        titleAlert = "Notification"
        messageAlert = """
            Please restart viDoc to start update.
            Note: If the viDoc doesn't have the bootloader, the installation of the software is not possible.
        """
        showingAlert = true
    }

    func manualDisconnect() {
        normalDisconnect = true
        disconnect()
    }

    private func disconnect(){
        if !normalDisconnect {
            failDisconnect = true
            titleAlert = "Connection lost"
            messageAlert = "viDoc is not response"
            showingAlert = true
        }
        currentTimeString = ""
        unixTimeString = ""
        gnssTimeString = ""
        rtkStatus = ""
        task?.disconnect()
        dynamicState = " "
        timerValueStr = ""
        timerBackValueStr = ""
        currentBatteryCharge = ""
        currentSoftwareVersion = ""
        currentHardwareVersion = ""
        bluetoothService.stopScan()
        connected = false
        nmeaReady = false
        flash = false
        needUpdate = false
        statusUpdate = ""
        progressUpdate = ""
        rawxMessage = ""
        sfrbxMessage = ""
        isConnectedDevice = false
        isStartingDevice = false
        correction = ""
        vertAcc = ""
        horAcc = ""
        ntripStatus = "Not connected"
        lat = ""
        lon = ""
        satelliteGNSS = ""
        satelliteStatusGNSS = ""
        ntripStarting = false
        timerRequestBattery.invalidate()
        peripherals.removeAll()
        countSatellite = ""
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
        singlePointMeasurement = nil
        periphiralState = .disconnected
        bluetoothService.disconnect()
        startScanBluetooth()
        rmxIsActive = false
        viDocState = ""
        resetMessageError = ""
        viDocIsReseting = false
        isBottomLaser = true
        isBackLaser = false
    }
    
    func conectToVidoc(id: UUID){
        
        peripherals.forEach { peripheral in
            if peripheral.identifier == id {
                self.connected = true

                // Uncomment if needed - CONFIGURATION
//                let peripheralConfiguration = PeripheralConfiguration(
//                    rateOfChangeMessages: .hertz7,
//                    dynamicType: .stationary
//                )

                var path: URL?
                let file = Date().getCurrentDateToString() + ".txt"

                let fileManager = FileManager.default
                let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

                if directory.count != 0  {
                    guard let nameDevice = peripheral.name else { return }
                    
                    self.nameDevice = nameDevice

                    path = directory[0].appendingPathComponent("LOG")
                    path = path?.appendingPathComponent(nameDevice)
                    if let path = path?.path {
                        if !fileManager.fileExists(atPath: path) {
                            do {
                                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                if Configuration.debug {
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    path = path?.appendingPathComponent(file)
                }
                
                do {
                    try self.peripheral = Vigram.peripheral(
                        peripheral,
                        log: path
                        // Uncomment if needed - CONFIGURATION
                        // configuration: peripheralConfiguration
                    )
                } catch {
                    if Configuration.debug {
                        print("Error: \(error.localizedDescription)")
                    }
                }

                self.bluetoothService.connect(to: (self.peripheral?.peripheral.identifier)!)
                    .sink(receiveCompletion: { [unowned self] status in
                        switch status{

                        case .finished:
                            self.isConnectedDevice = true
                            self.normalDisconnect = false
                            self.failDisconnect = false

                            self.peripheral?.isNeedSoftwareUpdate?.sink(
                                receiveCompletion: { _ in },
                                receiveValue: { [unowned self] isNeedUpdate in
                                    self.needUpdate = isNeedUpdate
                                }
                            ).store(in: &self.subscription)

                            self.peripheral?.softwareUpdateState?.sink(
                                receiveCompletion: { _ in },
                                receiveValue: { [unowned self] updateState in
                                    var status = ""
                                    switch(updateState) {
                                    case .startUpdate:
                                        status = "Start update"
                                        self.flash = true
                                    case .updatingSoftware: status = "Updating..."
                                    case .endUpdate:
                                        status = "Update successfull"
                                        self.titleAlert = "Update successfull"
                                        self.messageAlert = "Please restart viDoc"
                                        self.showingAlert = true
                                        self.flash = false
                                        Configuration.forceUpdate = false
                                    case .errorUpdate:
                                        self.titleAlert = "Update error"
                                        self.messageAlert = "Please try again..."
                                        self.showingAlert = true
                                    case .none: status = ""
                                    @unknown default:
                                        break
                                    }
                                    self.statusUpdate = "Status: \(status)"
                                 }
                            )
                            .store(in: &self.subscription)
                            
                            self.peripheral?.softwareUpdateProgress?.sink(
                                receiveCompletion: { _ in },
                                receiveValue: { [unowned self] progress in
                                    self.progressUpdate = "Progress: \(String(format: "%.1f", progress)) %"
                                }
                            )
                            .store(in: &self.subscription)
                            
                            self.peripheral?.start()
                                .sink(receiveCompletion: { [unowned self] status in
                                    switch status{
                                        
                                    case .finished:
                                        self.isStartingDevice = true

                                        self.peripheral?.state
                                            .sink(receiveValue: { [unowned self] state in
                                                self.periphiralState = state
                                                switch(state){
                                                case .disconnected:
                                                    self.disconnect()
                                                default:
                                                    break
                                                }
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.configurationState
                                            .sink(receiveValue: { [unowned self] state in
                                                switch(state){
                                                case .inProgress:
                                                    self.configuring = true
                                                case .done:
                                                    self.configuring = false
                                                case .failed(let error):
                                                    titleAlert = "Error"
                                                    messageAlert = error.localizedDescription
                                                    showingAlert = true
                                                    self.configuring = false
                                                @unknown default:
                                                    break
                                                }
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.viDocResetState
                                            .sink(receiveValue: { [unowned self] state in
                                                switch state {
                                                case let .isReseting(value):
                                                    if resetWithReconnect {
                                                        if !value {
                                                            if nmeaReady {
                                                                reccon()
                                                                resetWithReconnect = false
                                                                self.viDocIsReseting = false
                                                                self.configuring = false
                                                            }
                                                        } else {
                                                            self.viDocIsReseting = value
                                                            self.configuring = value
                                                        }
                                                    } else {
                                                        self.viDocIsReseting = value
                                                        self.configuring = value
                                                    }
                                                case let .failure(message):
                                                    self.resetMessageError = message
                                                @unknown default:
                                                    break
                                                }
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.ppkMeasurementsState
                                            .sink(receiveValue: { [unowned self] value in
                                                self.rmxIsActive = value
                                            })
                                            .store(in: &self.subscription)

                                        self.peripheral?.viDocState
                                            .sink(receiveValue: { [unowned self] state in
                                                switch state {
                                                case let .user(message):
                                                    if message != "Starting viDoc" {
                                                        self.viDocState += "\(Date().getCurrentDateToString())- GNTXT - User Message: \(message)\r\n "
                                                    }
                                                case let .error(message):
                                                    if message != "Starting viDoc" {
                                                        self.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Error Message: \(message)\r\n "
                                                    }
                                                case let .warning(message):
                                                    if message != "Starting viDoc" {
                                                        self.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Warning Message: \(message)\r\n "
                                                    }
                                                case let .notice(message):
                                                    if message != "Starting viDoc" {
                                                        self.viDocState +=  "\(Date().getCurrentDateToString())- GNTXT - Notice Message: \(message)\r\n "
                                                    }
                                                @unknown default:
                                                    break
                                                }
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.satelliteMessages
                                            .sink(receiveValue: { [unowned self] satellite in
                                                switch satellite {
                                                case let .rawx(rawxMessage):
                                                    self.rawxMessage = rawxMessage.message.hexStringWithSpace()
                                                case let .sfrbx(sfrbxMessage):
                                                    self.sfrbxMessage = sfrbxMessage.message.hexStringWithSpace()
                                                case let .pvt(info):
                                                    self.countSatellite = String(info.satelliteCount)
                                                    self.nVelocity = String(info.northVelocity)
                                                    self.eVelocity = String(info.eastVelocity)
                                                    self.dVelocity = String(info.downVelocity)
                                                default:
                                                    break
                                                }
                                            })
                                            .store(in: &self.subscription)
                                        let message = self.peripheral?.satelliteMessages
                                        
                                        if let message = message {
                                            message
                                                .sink(receiveValue: { [unowned self] satellite in
                                                    switch satellite {
                                                    case let .dop(info):
                                                        self.pdop = String(info.positionDop)
                                                        self.vdop = String(info.verticalDop)
                                                        self.hdop = String(info.horizontalDop)
                                                        self.tdop = String(info.timeDop)
                                                        self.gdop = String(info.geometricDop)

                                                    default:
                                                        break
                                                    }
                                                })
                                                .store(in: &self.subscription)
                                        }
                                        
                                        self.peripheral?.requestVersion()
                                            .sink(receiveCompletion: { _ in },
                                                  receiveValue: { [unowned self] version in
                                                self.currentSoftwareVersion = version.software.toString()
                                                self.currentHardwareVersion = version.hardware.toString()
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.requestBattery()
                                            .sink(receiveCompletion: { _ in },
                                                  receiveValue: { [unowned self] battery in
                                                self.currentBatteryCharge = String("\(battery.percentage) %")
                                            })
                                            .store(in: &self.subscription)
                                        
                                        self.peripheral?.nmea
                                            .sink(receiveValue: { [unowned self] nmea in
                                                
                                                if ((nmea as? GGAMessage) != nil)
                                                {
                                                    let currentDate = Date()
                                                    let unixDate = NSDate(timeIntervalSince1970: Date().timeIntervalSince1970)
                                                    self.currentTimeString = self.dateFormatter2.string(from: currentDate)
                                                    self.unixTimeString = self.dateFormatter.string(from: unixDate as Date)
                                                    self.gnssTimeString = (nmea as? GGAMessage)?.time?.description ?? ""

                                                    
                                                    if(nmea.coordinate?.longitude != nil)
                                                    {
                                                        self.nmeaReady = true
                                                        if resetWithReconnect, !viDocIsReseting {
                                                            self.reccon()
                                                            self.resetWithReconnect = false
                                                            self.viDocIsReseting = false
                                                            self.configuring = false
                                                        }

                                                        self.ggamessage = nmea as? GGAMessage
                                                        if let quality = self.ggamessage?.quality {
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

                                                        self.correction = self.ggamessage?.correctionAge?.description ?? ""
                                                        if let latitude = nmea.coordinate?.latitude {
                                                            self.lat = String(latitude)
                                                        } else {
                                                            self.lat = ""

                                                        }
                                                        if let longitude = nmea.coordinate?.longitude {
                                                            self.lon = String(longitude)
                                                        } else {
                                                            self.lon = ""

                                                        }
                                                    } else {
                                                        self.nmeaReady = false
                                                    }
                                                }
                                                if ((nmea as? GSTMessage) != nil) {
                                                    let gstmessage = nmea as? GSTMessage
                                                    if let latAccErr = gstmessage?.latitudeError,
                                                       let lonAccErr = gstmessage?.longitudeError {
                                                        self.lonAccErr = "\(lonAccErr)"
                                                        self.latAccErr = "\(latAccErr)"
                                                    }
                                                    if let horAcc = gstmessage?.accuracy?.horizontal,
                                                       let verAcc = gstmessage?.accuracy?.vertical {
                                                        self.horAcc = "\(horAcc)"
                                                        self.vertAcc = "\(verAcc)"
                                                    }
                                                }
                                            })
                                            .store(in: &self.subscription)
                                    case .failure(_):
                                        self.isStartingDevice = false
                                    }
                                }, receiveValue: {_ in })
                                .store(in: &self.subscription)
                            
                        case .failure(_):
                            self.isConnectedDevice = false
                        }
                    }, receiveValue: {_ in
                        
                    })
                    .store(in: &self.subscription)
            }
        }
    }
    
    private func startCountTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func startBackwardCountTimer() {
        timerBack = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateBackwardTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func updateTimer() {
        if let totalTime = totalTime {
            timerValueStr = "Record time: \(timeFormatted(totalTime))"
            self.totalTime! += 1
        } else {
            if let timer = timer {
                timer.invalidate()
                self.timer = nil
            }
        }
    }
    
    @objc private func updateBackwardTimer() {
        if let totalBackTime = totalBackTime {
            timerBackValueStr = "\(timeFormatted(totalBackTime))"
            if totalBackTime > 0 {
                self.totalBackTime! -= 1
            } else {
                self.totalBackTime = nil
                timerBackValueStr = ""
            }
        } else {
            if let timerBack = timerBack {
                timerBack.invalidate()
                self.timerBack = nil
                timerBackValueStr = ""
            }
        }
    }
            
    private func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func connectToNtrip() {
        socketCodeError = nil
        nci = NtripConnectionInformation.init(
            hostname: self.hostname,
            port: Int(self.port) ?? 0,
            username: self.username,
            password: self.password
        )
        if let nci = nci {
            do {
                if let ggamessage = ggamessage {
                    try self.task = ntripService.task(
                        for: nci,
                        atMountPoint: self.atMountPoint,
                        message: ggamessage
                    )
                }
            } catch {}
            
            if let peripheral = self.peripheral {
                gpsService = Vigram.gpsService(
                    peripheral: peripheral,
                    bluetoothService: bluetoothService,
                    correctionTask: task
                )
            }
            
            task?.ntripState
                .sink(receiveValue: { [unowned self] state in
                    if Configuration.debug {
                        print("NTRIP STATE \(state)")
                    }
                    switch state {
                    case .ready:
                        self.ntripStatus = "Connection is ready"
                        ntripStarting = true
                        if let port = Int(self.port) {
                            let currentNtripCridential = NtripCredentials(
                                host: hostname,
                                port: port,
                                login: username,
                                pass: password,
                                mountpoint: atMountPoint
                            )
                            var isAlreadyExist = false
                            ntripCridentials.forEach { current in
                                if current == currentNtripCridential {
                                    isAlreadyExist = true
                                }
                            }
                            if !isAlreadyExist {
                                ntripCridentials.append(currentNtripCridential)
                                do {
                                    let res = try JSONEncoder().encode(ntripCridentials)
                                    UserDefaults.standard.set(res, forKey: "ntrip")
                                }
                                catch { print(error) }
                            }
                        }
                    case .preparing:
                        self.ntripStatus = "Connection is preparing"
                    case .cancelled:
                        if socketCodeError == nil {
                            self.ntripStatus = "Connection is cancelled"
                        }
                        ntripStarting = false
                        singlePointMeasurement = nil
                    case .failed(let error):
                        if socketCodeError == nil {
                            self.ntripStatus = "Connection is failed"
                        }
                        if Configuration.debug {
                            print("NTRIP STATE MESSAGE FAILED = \(error.localizedDescription)")
                        }
                        ntripStarting = false
                        singlePointMeasurement = nil
                    case .setup:
                        self.ntripStatus = "Connection is setup"
                    case .waiting(let error):
                        if socketCodeError == nil {
                            self.ntripStatus = "Connection is waiting"
                        }
                        if Configuration.debug {
                            print("NTRIP STATE MESSAGE WAITING = \(error.localizedDescription)")
                        }
                    case .unknownError(let errorStr):
                        self.ntripStatus = "Unknown error connection: \(errorStr.description)"
                        if Configuration.debug {
                            print("NTRIP STATE MESSAGE UNKNOWN ERROR = \(errorStr.description)")
                        }
                        ntripStarting = false
                        singlePointMeasurement = nil
                    case .notConnected:
                        self.ntripStatus = "Not connected to Ntrip"
                        ntripStarting = false
                        singlePointMeasurement = nil
                    case .socketError(let errorCode):
                        socketCodeError = errorCode
                        if Configuration.debug {
                            print("NTRIP STATE MESSAGE SOKET ERROR = \(errorCode)")
                        }
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
                        ntripStarting = false
                        singlePointMeasurement = nil
                    @unknown default:
                        break
                    }
                })
                .store(in: &subscription)
            
            task?.resume().sink(receiveCompletion: { _ in },
                                receiveValue: { _ in })
            .store(in: &subscription)
        }
    }
    
    func disconnectNtrip(){
        task?.disconnect()
        ntripStarting = false
        self.ntripStatus = "No connection"

    }

    // Requests GNSS Constellation
    func getCurrentStatusGNSS(satellite: NavigationSystemType){
        peripheral?.getCurrentStatusGNSS(satellite: satellite)
            .sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] value in
                switch value.satelliteType {
                case .gps:
                    self.satelliteGNSS = "GPS"
                case .glonass:
                    self.satelliteGNSS = "Glonass"
                case .beidou:
                    self.satelliteGNSS = "Beidou"
                case .galileo:
                    self.satelliteGNSS = "Galileo"
                case .qzss:
                    self.satelliteGNSS = "QZSS"
                case .sbas:
                    self.satelliteGNSS = "SBAS"
                @unknown default:
                    break
                }
                self.satelliteStatusGNSS = value.isEnabled == true ? "GNSS is enabled" : "GNSS is disabled"
            })
            .store(in: &subscription)
    }
    
    func requestBattery(){
        self.peripheral?.requestBattery()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    if Configuration.debug {
                        print("Error \(error.localizedDescription)")
                    }
                }
            }, receiveValue: { [unowned self] battery in
                self.currentBatteryCharge = String("\(battery.percentage) %")
            })
            .store(in: &subscription)
    }
    
    func requestVersion(){
        self.peripheral?.requestVersion()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    if Configuration.debug {
                        print("Error \(error.localizedDescription)")
                    }
                }
            }, receiveValue: { [unowned self] version in
                self.currentSoftwareVersion = version.software.toString()
                self.currentHardwareVersion = version.hardware.toString()
            })
            .store(in: &subscription)
    }
    
    func changeStatusGNSS(satellite: NavigationSystemType, activate: Bool){
        peripheral?.changeStatusGNSS(satellite: satellite, activate: activate)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &subscription)
    }
    
    func changeStatusNAVDOP(activate: Bool){
        peripheral?.changeStatusNAVDOP(activate: activate)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &subscription)
    }
    
    func changeStatusNAVPVT(activate: Bool){
        peripheral?.changeStatusNAVPVT(activate: activate)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &subscription)
    }
    
    func activateAllConstellationGNSS(){
        peripheral?.activateAllConstellationGNSS()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &subscription)
    }
    
    func getMinimumElevation() {
        peripheral?.getCurrentMinimumElevation()
            .sink(receiveCompletion: { _ in }, receiveValue: { value in
                self.elevation = String(value.current.rawValue)
            })
            .store(in: &subscription)
    }
    
    func setMinimumElevation(angle: ElevationValue) {
        peripheral?.setMinimumElevation(angle: angle)
            .sink(receiveCompletion: { _ in }, receiveValue: { acknowledge in
                if acknowledge.result {
                    self.getMinimumElevation()
                }
            })
            .store(in: &subscription)
    }
    
    func setChangingRateOfMessage(_ rate: RateValue) {
        peripheral?.setChangingRateOfMessages(rate)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                self.getChangingRateOfMessage()
            })
            .store(in: &subscription)
    }
    
    func getChangingRateOfMessage() {
        peripheral?.getChangingRateOfMessages()
            .sink(receiveCompletion: { _ in }, receiveValue: { rate in
                self.currentRate = "\(rate.current.rawValue)"
            })
            .store(in: &subscription)
    }

    func changeRXM(activate: Bool) {
        peripheral?.changeStatusRXM(activate: activate)
    }
    
    func reccon(){
        gpsService?.reconnect()
    }
    
    func recconWithReset(){
        self.viDocState.removeAll()
        resetMessageError = ""
        resetWithReconnect = true
        peripheral?.resetViDoc()
    }

    func getAllUBXFiles(pathName: String) {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

        guard let nameDevice = nameDevice else {
            if Configuration.debug {
                print("Name device is empty")
            }
            return
        }

        var path = directory[0].appendingPathComponent(pathName)
        path = path.appendingPathComponent(nameDevice)

        guard directory.count != 0 else {
            if Configuration.debug {
                print("Document map in local domain not found")
            }
            return
        }

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path.path)
            listOfUBXFiles.removeAll()
            for item in items {
                listOfUBXFiles.append(item)
            }
        } catch {
            if Configuration.debug {
                print("Document map in local domain not found")
            }
            return
        }
    }

    func startMeasurementsPPK(){
        let filename = "\(Date().getCurrentDateToString()).ubx"
        let path = "PPK"
        let ubxFile = createUbxFile(filename: filename, pathName: path)
        if let ubxFile = ubxFile {
            peripheral?.startRecordPPKMeasurements(url: ubxFile)
        }
        self.totalTime = 0
        startCountTimer()
    }

    func stopMeasurementsPPK(){
        peripheral?.stopRecordPPKMeasurements()
        self.totalTime = nil
    }

    func setDynamicState(type: DynamicStateType) {
        peripheral?.setDynamicState(type: type)
            .sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] _ in
                self.getDynamicState()
            })
            .store(in: &subscription)
    }
    
    func getDynamicState() {
        peripheral?.getCurrentDynamicState()
            .sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] state in
                switch state.current {
                case .pedestrian:
                    self.dynamicState = "Pedestrian"
                case .stationary:
                    self.dynamicState = "Stationary"
                @unknown default:
                    break
                }
            })
            .store(in: &subscription)
    }

    func startLaser(){
        if let duration = Double(durationStr), duration > 0, duration <= 60 {
            if let peripheral = self.peripheral {
                self.laser = Vigram.laserService(peripheral: peripheral)
                let typeOfLaser: LaserConfiguration.Position = isBottomLaser ? .bottom : .back
                let laserConfig = LaserConfiguration.init(shotMode: .fast, position: typeOfLaser, duration: duration)
                self.laser?.record(configuration: laserConfig)
                    .sink(receiveCompletion: { complition in
                        switch(complition) {
                        case .finished:
                            print("Finish measurement")
                        case .failure(let error):
                            print("Error measurement: \(error.localizedDescription)")
                        }
                    }, receiveValue: { [unowned self] measurement in
                        self.distance = "\(measurement.distance)"
                    })
                    .store(in: &self.subscription)
            }
        } else {
            titleAlert = "Error"
            messageAlert = "Duration value is not correct"
            showingAlert = true
        }
    }

    func startSPMeasurement(){
        if useLaser {
            turnOffLaser()
            recordWithLaser()
        } else {
            recordWithoutLaser()
        }
    }
    
    func recordWithLaser(){
        if let duration = Double(durationStr), duration > 0, duration <= 60 {
            singlePointMeasurement = nil
            if let peripheral = self.peripheral {
                if self.laser == nil {
                    self.laser = Vigram.laserService(peripheral: peripheral)
                }
                let typeOfLaser: LaserConfiguration.Position = isBottomLaser ? .bottom : .back
                self.laser?.turnLaserOn(at: typeOfLaser)
                    .sink(receiveCompletion: { _ in
                    }, receiveValue: { [unowned self] _ in
                        
                        recordSinglePoint(for: duration, useLaser: true)
                        self.singlePointMeasurement = nil
                        self.totalBackTime = Int(duration)
                        self.startBackwardCountTimer()
                    })
                    .store(in: &self.subscription)
            }
        } else {
            titleAlert = "Error"
            messageAlert = "Duration value is not correct"
            showingAlert = true
        }
    }
    
    func recordWithoutLaser(){
        if let duration = Double(durationStr), duration > 0, duration <= 60 {
            
            if self.peripheral != nil {
                singlePointMeasurement = nil
                recordSinglePoint(for: duration, useLaser: false)
                self.totalBackTime = Int(duration) - 1
                startBackwardCountTimer()
            }
        } else {
            titleAlert = "Error"
            messageAlert = "Duration value is not correct"
            showingAlert = true
        }
    }
    
    func turnOnLaser(){
        if let peripheral = self.peripheral {
            self.laser = Vigram.laserService(peripheral: peripheral)
            let typeOfLaser: LaserConfiguration.Position = isBottomLaser ? .bottom : .back
            self.laser?.turnLaserOn(at: typeOfLaser)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { _ in })
                .store(in: &self.subscription)
        }
    }
    
    func turnOffLaser(){
        if let peripheral = self.peripheral {
            self.laser = Vigram.laserService(peripheral: peripheral)
            let typeOfLaser: LaserConfiguration.Position = isBottomLaser ? .bottom : .back
            self.laser?.turnLaserOff(at: typeOfLaser)
                .sink(receiveCompletion: { _ in
                }, receiveValue: { _ in })
                .store(in: &self.subscription)
        }
    }

    func getUBXFile(filename: String, pathName: String){
        fileLinkForUBXFile = nil

        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

        guard directory.count != 0 else {
            if Configuration.debug {
                print("[FILE MANAGER]: Document map in local domain not found")
            }
            return
        }

        guard let nameDevice = nameDevice else {
            if Configuration.debug {
                print("Name device is empty")
            }
            return
        }
        var path = directory[0].appendingPathComponent(pathName)
        path = path.appendingPathComponent(nameDevice)

        path = path.appendingPathComponent("\(filename)")
        fileLinkForUBXFile = fileManager.fileExists(atPath: path.path) ? path : nil

        if fileLinkForUBXFile != nil {
            isSharePresented = true
        }
    }

    func resetViDoc() {
        self.viDocState.removeAll()
        resetMessageError = ""
        peripheral?.resetViDoc()
    }
    
    func clearTXTLog() {
        self.viDocState.removeAll()
    }
    
    private func recordSinglePoint(for duration: TimeInterval, antennaDistanceToGround: Double = 0.0, useLaser: Bool = false) {
        guard let gpsService = gpsService else {
            titleAlert = "Notification"
            messageAlert = "No connection for NTRIP"
            showingAlert = true
            return
        }
        
        let environmentDataService: VigramSDK.EnvironmentDataService
        let singlePointRecordingService: VigramSDK.SinglePointRecordingService
        let method: VigramSDK.CoordinateCorrection.Method
        
        if useLaser {

            environmentDataService = Vigram.environmentDataService(
                gpsService: gpsService, laserService: laser, peripheral: peripheral!, dynamicStateType: .stationary
            )
            singlePointRecordingService = Vigram.singlePointRecordingService(environmentDataService: environmentDataService)
            let typeOfLaser: LaserConfiguration.Position = isBottomLaser ? .bottom : .back

            let laserConfiguration = LaserConfiguration(
                shotMode: .auto,
                position: typeOfLaser,
                duration: duration
            )
            
            self.laser?.record(configuration: laserConfiguration)
                .sink(receiveCompletion: { complition in
                    switch(complition) {
                    case .finished:
                        print("Finish measurement")
                    case .failure(let error):
                        print("Error measurement: \(error.localizedDescription)")
                    }
                }, receiveValue: { [unowned self] measurement in
                    self.distance = "\(measurement.distance)"
                })
                .store(in: &self.subscription)
            
            method = CoordinateCorrection.Method.laser(
                configuration: laserConfiguration,
                antennaOffset: currentOffsets,
                useDeviceMotion: true
            )
        } else {
            environmentDataService = Vigram.environmentDataService(
                gpsService: gpsService,
                peripheral: self.peripheral!,
                dynamicStateType: .stationary
            )
            singlePointRecordingService = Vigram.singlePointRecordingService(environmentDataService: environmentDataService)
            if let distanceFromAntennaToGround = Double(distanceOfGroundStr) {
                method = CoordinateCorrection.Method.constant(distanceFromAntennaToGround: distanceFromAntennaToGround)
            } else {
                method = CoordinateCorrection.Method.constant(distanceFromAntennaToGround: 0)
            }
        }
        singlePointRecordingService
            .record (duration: duration, updateInterval: 0.1, with: method)
            .sink { completion in
                switch completion {
                case .failure(_):
                    self.titleAlert = "Error"
                    self.messageAlert = "Bad measurement"
                    self.showingAlert = true
                case .finished:
                    break
                }
            } receiveValue: { singlePoint in
                self.singlePointMeasurement = singlePoint
            }.store(in: &subscription)
    }

    private func createUbxFile(filename: String, pathName: String) -> URL? {
        var path: URL?

        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

        if directory.count != 0  {
            guard let nameDevice = nameDevice else {
                if Configuration.debug {
                    print("Name device is empty")
                }
                return nil
            }
            path = directory[0].appendingPathComponent(pathName)
            path = path?.appendingPathComponent(nameDevice)
            if let path = path?.path {
                if !fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.createDirectory(
                            atPath: path,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    } catch {
                        if Configuration.debug {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            path = path?.appendingPathComponent(filename)
        }
        return path
    }
}

extension Date {
    func getCurrentDateToString() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        let second = calendar.component(.second, from: self)
        let dayString = "\(day)."
        let monthString = month < 10 ? "0\(month)." : "\(month)."
        let yearString = "\(year)-"
        let hourString = hour < 10 ? "0\(hour):" : "\(hour):"
        let minuteString = minute < 10 ? "0\(minute):" : "\(minute):"
        let secondString = second < 10 ? "0\(second)" : "\(second)"
        
        return dayString + monthString + yearString + hourString + minuteString + secondString
    }
}

extension Data {
    func hexStringWithSpace(uppercase: Bool = true) -> String {
        let format = uppercase ? "%02hhX " : "%02hhx "
        return map { String(format: format, $0) }.joined()
    }
    
    func hexString(uppercase: Bool = true) -> String {
        let format = uppercase ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension String {
    func getNumber() -> Int? {
        return Int(components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
