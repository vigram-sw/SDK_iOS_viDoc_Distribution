//
//  ContentView.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 03.08.22.
//  Copyright © 2020 Vigram. All rights reserved.
//

import CoreBluetooth
import SwiftUI
import UIKit
import VigramSDK

struct ContentView: View {
    
    // MARK: Observable objects
    
    @ObservedObject var model: Model
    @State private var showNavdop = false
    @State private var showDynamicState = false
    @State private var showSoftware = false
    @State private var showOffsets = false
    @State private var showGNSS = false
    @State private var showElevation = false
    @State private var showRate = false
    @State private var showRecordFiles = false
    @State private var recordIsActive = false
    @State private var showViDocReset = false
    @State private var message1 = "Configuration in progress"
    @State private var message2 = "viDoc is reseting\n(Estimated time 60 sec)"
    @State private var message3 = "viDoc is reseting. \nAfter reset, NTRIP connection will be restored \n(Estimated time 70 sec)"
    
    // MARK: Init
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: Computed properties
    
    var body: some View {
        LoadingView(isShowing: $model.configuring, message: model.viDocIsReseting ? (model.resetWithReconnect ? $message3 : $message2) : $message1) {
                NavigationView {
                    if !model.configuring {
                    ScrollView (showsIndicators: false) {
                        VStack {
                            if model.flash {
                                Text("Status update device")
                                    .font(Font.headline.bold())
                                    .padding(6)
                                Text("\(model.statusUpdate)")
                                Text("\(model.progressUpdate)")
                            }
                        }
                        if model.connected {
                            VStack {
                                Button {
                                    self.showSoftware.toggle()
                                } label: {
                                    if showSoftware {
                                        Text("Hide Software Info")
                                            .font(Font.headline.bold())
                                            .foregroundColor(.black)
                                        Image(systemName: "chevron.up").foregroundColor(.black)
                                    } else {
                                        Text("Show Software Info")
                                            .font(Font.headline.bold())
                                            .foregroundColor(.black)
                                        Image(systemName: "chevron.down").foregroundColor(.black)
                                    }
                                }
                                .buttonStyle(.bordered)
                                if showSoftware {
                                    VStack {
                                        Text("List of available softwares:")
                                            .font(Font.headline.bold())
                                            .padding(6)
                                        ForEach(model.allAvailableSoftwareVersion, id: \.self.build) { software in
                                            Button {
                                                model.installSoftware(software)
                                            } label: {
                                                Text("Install \(software.toString())")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                            }
                                            .buttonStyle(.bordered)
                                            .padding(6)
                                        }
                                        Button {
                                            model.setForceUpdateSoftware()
                                        } label: {
                                            Text("Force update actual software")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.bordered)
                                        .padding(6)
                                    }
                                }
                            }
                        }
                        if !model.connected && !model.flash {
                            VStack {
                                Text("Available devices")
                                    .font(Font.headline.bold())
                                    .padding(6)
                                if model.peripherals.isEmpty {
                                    ProgressView()
                                } else {
                                    ForEach(model.peripherals, id: \.self.identifier) { perefiral in
                                        Button {
                                            model.conectToVidoc(id: perefiral.identifier)
                                        } label: {
                                            Text("Connect to \(perefiral.name ?? "")")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.bordered)
                                        .padding(6)
                                    }
                                }
                            }
                        } else {
                            VStack {
                                if !model.flash {
                                    VStack {
                                        Button {
                                            model.manualDisconnect()
                                        } label: {
                                            Text("Disconnect")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                    }
                                    Text("Device info")
                                        .font(Font.headline.bold())
                                        .padding(6)
                                    VStack {
                                        VStack {
                                            HStack {
                                                Text("  Name device: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.peripheral?.peripheral.name ?? "")
                                                Spacer()
                                            }
                                            if let peripheral = model.peripheral {
                                                HStack {
                                                    Text("  Protocol: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(peripheral.isNewProtocol ? "New" : "Old")
                                                    Spacer()
                                                }
                                            }
                                            HStack {
                                                Text("  Device number: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.serialNumber)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  Hardware on device: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.currentHardwareVersion)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  Software on device: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.currentSoftwareVersion)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  Battery: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.currentBatteryCharge)
                                                Spacer()
                                            }
                                        }
                                        HStack {
                                            Text("  Connection perephiral status: ")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                            switch model.periphiralState {
                                            case.connecting:
                                                ProgressView()
                                            case .connected:
                                                Image(systemName: "wave.3.right")
                                                    .foregroundColor(.green)
                                            case .disconnecting:
                                                ProgressView()
                                            case .disconnected:
                                                Image(systemName: "wave.3.right")
                                                    .foregroundColor(.red)
                                            @unknown default:
                                                exit(0)
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Text("  Connection device status: ")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                            if model.isConnectedDevice {
                                                Image(systemName: "personalhotspot")
                                                    .foregroundColor(.green)
                                            } else {
                                                Image(systemName: "personalhotspot")
                                                    .foregroundColor(.red)
                                            }
                                            Spacer()
                                        }
                                        HStack {
                                            Text("  Starting device status: ")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                            if model.isStartingDevice {
                                                Image(systemName: "bolt.horizontal.fill")
                                                    .foregroundColor(.green)
                                            } else {
                                                Image(systemName: "bolt.horizontal.fill")
                                                    .foregroundColor(.red)
                                            }
                                            Spacer()
                                        }
                                        Button {
                                            self.showViDocReset.toggle()
                                        } label: {
                                            if showViDocReset {
                                                Text("Hide reset viDoc control")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.up").foregroundColor(.black)
                                            } else {
                                                Text("Show reset viDoc control")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.down").foregroundColor(.black)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        if showViDocReset {
                                            Text("Reset viDoc control")
                                                .font(Font.headline.bold())
                                                .padding(6)
                                            if model.resetMessageError != "" {
                                                Text(model.resetMessageError)
                                                    .font(Font.headline.bold())
                                                    .padding(6)
                                                    .foregroundColor(.red)
                                            }
                                            VStack {
                                                Button { model.resetViDoc() } label: {
                                                    Text("Reset viDoc")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                }.buttonStyle(.bordered)
                                                Text("GNTXT Messages:")
                                                    .font(Font.headline.bold())
                                                    .padding(6)
                                                ScrollView{
                                                    TextEditor(text: .constant(model.viDocState))
                                                        .font(.system(size: 10.0))
                                                        .border(Color.black, width: 1)
                                                        .frame(width: UIScreen.main.bounds.size.width-32, height: 150, alignment: .topLeading)
                                                }
                                                Button { model.clearTXTLog() } label: {
                                                    Text("Clear log")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                }.buttonStyle(.bordered)
                                            }
                                        }
                                        HStack {
                                            Text("  NMEA ready status: ")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                            if model.nmeaReady {
                                                Image(systemName: "network")
                                                    .foregroundColor(.green)
                                            } else {
                                                if !model.rmxIsActive {
                                                    ProgressView()
                                                }
                                            }
                                            Spacer()
                                        }
                                    }.padding(6)
                                    VStack{
                                        Button { model.requestBattery() } label: {
                                            Text("Get battery charge")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                        
                                        Button { model.requestVersion() } label: {
                                            Text("Get current software / hardware version")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                    }
                                    if model.nmeaReady {
                                        VStack {
                                            VStack {
                                                VStack {
                                                    HStack {
                                                        Text("  Current time: ")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Text(model.currentTimeString)
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("  UTC time: ")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Text(model.unixTimeString)
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("  GNSS time: ")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Text(model.gnssTimeString)
                                                        Spacer()
                                                    }
                                                    Text("")
                                                    HStack {
                                                        Text("  Latitude: ")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Text(model.lat)
                                                        Spacer()
                                                    }
                                                }
                                                HStack {
                                                    Text("  Longitude: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(model.lon)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Count satellite: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(model.countSatellite)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Vert. accuracy: ").font(Font.headline.bold())
                                                    Text(model.vertAcc)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Horiz. accuracy: ").font(Font.headline.bold())
                                                    Text(model.horAcc)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Correction: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(model.correction)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Latitude error: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(model.latAccErr)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text("  Longitude error: ")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Text(model.lonAccErr)
                                                    Spacer()
                                                }
                                            }
                                            HStack {
                                                Text("  North velocity: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.nVelocity)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  East velocity: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.eVelocity)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  Down velocity: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.dVelocity)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  PDOP: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.pdop)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  VDOP: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.vdop)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  HDOP: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.hdop)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  TDOP: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.tdop)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  GDOP: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.gdop)
                                                Spacer()
                                            }
                                            HStack {
                                                Text("  RTK: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.rtkStatus)
                                                Spacer()
                                            }
                                        }.padding(6)
                                        NTRIPControlView(model: model)
                                    }
                                    VStack {
                                        Text("Laser configuration").font(Font.headline.bold())
                                        HStack {
                                            Text("  Duration (second): ").font(Font.headline.bold())
                                            TextField("5", text: $model.durationStr)
                                                .keyboardType(.decimalPad)
                                            Spacer()
                                        }
                                        HStack {
                                            SelectButton(
                                                isSelected: $model.isBottomLaser,
                                                color: .green,
                                                text: "Bottom"
                                            ).onTapGesture {
                                                model.turnOffLaser()
                                                model.isBottomLaser = true
                                                if model.isBottomLaser {
                                                    model.isBackLaser = false
                                                    model.singlePointMeasurement = nil
                                                    model.currentAllOffsets.removeAll()
                                                    model.currentAllOffsets = model.laserOffsetsBottom
                                                    model.useLaser = true
                                                    model.withoutLaset = false
                                                    self.showOffsets = false
                                                }
                                            }
                                            SelectButton(
                                                isSelected: $model.isBackLaser,
                                                color: .green,
                                                text: "Back"
                                            ).onTapGesture {
                                                model.turnOffLaser()
                                                model.isBackLaser = true
                                                if model.isBackLaser {
                                                    model.isBottomLaser = false
                                                    model.singlePointMeasurement = nil
                                                    model.currentAllOffsets.removeAll()
                                                    model.currentAllOffsets = model.laserOffsetsBack
                                                    model.useLaser = true
                                                    model.withoutLaset = false
                                                    self.showOffsets = false
                                                }
                                            }
                                        }
                                        if let peripheral = model.peripheral, peripheral.isNewProtocol {
                                            HStack {
                                                Text("  Lasers state: ")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Text(model.lasersState)
                                                Spacer()
                                            }
                                        }
                                        Button { model.getLaserStatus() } label: {
                                            Text("Get lasers status")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                        Button { model.turnOnLaser() } label: {
                                            Text("LaserOn")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                        Button { model.turnOffLaser() } label: {
                                            Text("LaserOff")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                        Button { model.startLaser() } label: {
                                            Text("Start measurements")
                                                .font(Font.headline.bold())
                                                .foregroundColor(.black)
                                        }.buttonStyle(.bordered)
                                        HStack {
                                            Text("  Distance: ").font(Font.headline.bold())
                                            Text(model.distance)
                                            Spacer()
                                        }
                                    }.padding(6)
                                    if model.ntripStarting {
                                        VStack {
                                            Text("Single point measurement").font(Font.headline.bold())
                                            if model.timerBackValueStr != "00:00", model.timerBackValueStr != "" {
                                                ProgressView()
                                            }
                                            Text(model.timerBackValueStr).font(Font.headline.bold()).foregroundColor(Color(uiColor: .red))
                                            if let singlePoint = model.singlePointMeasurement {
                                                Text("Device parametres").font(Font.headline.bold())
                                                VStack {
                                                    HStack {
                                                        Text("x = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.x)")
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("y = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.y)")
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("z = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.z)")
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Yaw = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.yaw)")
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Pitch = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.pitch)")
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Roll = ").font(Font.headline.bold())
                                                        Text("\(singlePoint.environmentData.deviceMotion.orientation.roll)")
                                                        Spacer()
                                                    }
                                                }
                                                Text("Coordinate without correction").font(Font.headline.bold())
                                                VStack {
                                                    HStack {
                                                        Text("Latitude: ").font(Font.headline.bold())
                                                        Text(
                                                            String(
                                                                format: "%.10f",
                                                                singlePoint.environmentData.coordinate.latitude
                                                            )
                                                        )
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Longitude: ").font(Font.headline.bold())
                                                        Text(
                                                            String(
                                                                format: "%.10f",
                                                                singlePoint.environmentData.coordinate.longitude
                                                            )
                                                        )
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Reference altitude: ").font(Font.headline.bold())
                                                        Text(
                                                            String(
                                                                format: "%.10f",
                                                                singlePoint.environmentData.coordinate.referenceAltitude
                                                            )
                                                        )
                                                        Spacer()
                                                    }
                                                    HStack {
                                                        Text("Geoid separation: ").font(Font.headline.bold())
                                                        Text(
                                                            String(
                                                                format: "%.10f",
                                                                singlePoint.environmentData.coordinate.geoidSeparation
                                                            )
                                                        )
                                                        Spacer()
                                                    }
                                                }
                                                if model.useLaser {
                                                    Text("Corrected coordinate").font(Font.headline.bold())
                                                    VStack {
                                                        HStack {
                                                            Text("Latitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.latitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Longitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.longitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Reference altitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.referenceAltitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Geoid separation: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.geoidSeparation
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                    }
                                                } else {
                                                    Text("Corrected coordinate").font(Font.headline.bold())
                                                    VStack {
                                                        HStack {
                                                            Text("Latitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.latitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Longitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.longitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Reference altitude: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.referenceAltitude
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                        HStack {
                                                            Text("Geoid separation: ").font(Font.headline.bold())
                                                            Text(
                                                                String(
                                                                    format: "%.10f",
                                                                    singlePoint.environmentData.correctedCoordinate.geoidSeparation
                                                                )
                                                            )
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                            }
                                            HStack {
                                                SelectButton(
                                                    isSelected: $model.useLaser,
                                                    color: .green,
                                                    text: "Use laser"
                                                ).onTapGesture {
                                                    model.singlePointMeasurement = nil
                                                    model.currentAllOffsets.removeAll()
                                                    if model.isBackLaser {
                                                        model.currentAllOffsets = model.laserOffsetsBack
                                                    } else {
                                                        model.currentAllOffsets = model.laserOffsetsBottom
                                                    }
                                                    model.currentOffsetsString = model.currentAllOffsets.first!.0
                                                    model.currentOffsets = model.currentAllOffsets.first!.1
                                                    model.useLaser = true
                                                    if model.useLaser {
                                                        model.withoutLaset = false
                                                    }
                                                }
                                                SelectButton(
                                                    isSelected: $model.withoutLaset,
                                                    color: .green,
                                                    text: "Without laser"
                                                ).onTapGesture {
                                                    model.singlePointMeasurement = nil
                                                    model.currentAllOffsets.removeAll()
                                                    model.currentAllOffsets = model.cameraOffsets
                                                    model.withoutLaset = true
                                                    if model.withoutLaset {
                                                        model.useLaser = false
                                                    }
                                                }
                                            }
                                            VStack{
                                                HStack {
                                                    Text("  The distance to the \n  ground (cm): ").font(Font.headline.bold())
                                                    TextField("50", text: $model.distanceOfGroundStr)
                                                        .keyboardType(UIKeyboardType.decimalPad)
                                                    Spacer()
                                                }
                                                Button {
                                                    self.showOffsets.toggle()
                                                    if showOffsets {
                                                        model.getAllOffsets()
                                                        model.currentAllOffsets.removeAll()
                                                        if model.useLaser {
                                                            if model.isBackLaser {
                                                                model.currentAllOffsets = model.laserOffsetsBack
                                                            } else {
                                                                model.currentAllOffsets = model.laserOffsetsBottom
                                                            }
                                                        } else {
                                                            model.currentAllOffsets = model.cameraOffsets
                                                        }
                                                    }
                                                } label: {
                                                    if showOffsets {
                                                        Text("Hide offsets option")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Image(systemName: "chevron.up").foregroundColor(.black)
                                                    } else {
                                                        Text("Show offsets option")
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.black)
                                                        Image(systemName: "chevron.down").foregroundColor(.black)
                                                    }
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                if showOffsets {
                                                    VStack {
                                                        Text("Current offsets:").font(Font.headline.bold())
                                                        Text("\(model.currentOffsetsString)")
                                                        
                                                        Text("Current offsets values").font(Font.headline.bold())
                                                        HStack{
                                                            Text("x = ").font(Font.headline.bold())
                                                            Text("\(model.currentOffsets.x)")
                                                        }
                                                        HStack{
                                                            Text("y = ").font(Font.headline.bold())
                                                            Text("\(model.currentOffsets.y)")
                                                        }
                                                        HStack{
                                                            Text("z = ").font(Font.headline.bold())
                                                            Text("\(model.currentOffsets.z)")
                                                        }
                                                    }
                                                    ForEach(model.currentAllOffsets, id: \.self.0) { offset in
                                                        Button {
                                                            model.currentOffsets = offset.1
                                                            model.currentOffsetsString = offset.0
                                                        } label: {
                                                            Text(offset.0)
                                                                .font(Font.headline.bold())
                                                                .foregroundColor(.green)
                                                        }.buttonStyle(.bordered)
                                                    }
                                                }
                                            }
                                            Button { model.startSPMeasurement() } label: {
                                                Text("Start SP measurement")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                            }.buttonStyle(.bordered)
                                        }.padding(6)
                                    }
                                    VStack {
                                        Text("UBX measurements control").font(Font.headline.bold()).foregroundColor(.black)
                                        if model.rmxIsActive {
                                            Text("RMX is active").font(Font.headline.bold()).foregroundColor(.green)
                                        }
                                        HStack {
                                            Button {
                                                model.changeRXM(activate: true)
                                            } label: {
                                                Text("Activate RXM")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                            }.buttonStyle(.bordered)
                                            Button {
                                                model.changeRXM(activate: false)
                                            } label: {
                                                Text("Disactivate RXM")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                            }.buttonStyle(.bordered)
                                        }
                                        if recordIsActive {
                                            Text("Record is active").font(Font.headline.bold()).foregroundColor(.green)
                                            Text(model.timerValueStr)
                                        }
                                        if model.rmxIsActive {
                                            HStack {
                                                Button {
                                                    recordIsActive = true
                                                    UIApplication.shared.isIdleTimerDisabled = true
                                                    model.startMeasurementsPPK()
                                                } label: {
                                                    Text("Start record PPK")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                }.buttonStyle(.bordered)
                                                Button {
                                                    recordIsActive = false
                                                    UIApplication.shared.isIdleTimerDisabled = false
                                                    model.stopMeasurementsPPK()
                                                } label: {
                                                    Text("Stop record PPK")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                }.buttonStyle(.bordered)
                                            }
                                        }
                                        if recordIsActive {
                                            Text("Record log").font(Font.headline.bold())
                                            Text("Last rawx message:").font(Font.headline.bold())
                                            Text(model.rawxMessage)
                                            Text("Last sfrbx message:").font(Font.headline.bold())
                                            Text(model.sfrbxMessage)
                                        }
                                        Button {
                                            self.showRecordFiles.toggle()
                                            model.getAllUBXFiles(pathName: "PPK")
                                        } label: {
                                            if showRecordFiles {
                                                Text("Hide all record files")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.up").foregroundColor(.black)
                                            } else {
                                                Text("Show all record files")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.down").foregroundColor(.black)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        if showRecordFiles,
                                           !model.listOfUBXFiles.isEmpty {
                                            VStack {
                                                Text("Available UBX files").font(Font.headline.bold())
                                                ForEach(model.listOfUBXFiles, id: \.self) { file in
                                                    Button {
                                                        model.getUBXFile(filename: file, pathName: "PPK")
                                                    } label: {
                                                        Text(file)
                                                            .font(Font.headline.bold())
                                                            .foregroundColor(.green)
                                                    }.buttonStyle(.bordered)
                                                }
                                            }.sheet(isPresented: $model.isSharePresented, onDismiss: {
                                                model.fileLinkForUBXFile = nil
                                            }, content: {
                                                ActivityViewController(activityItems: [model.fileLinkForUBXFile!])
                                            })
                                        }
                                    }
                                    VStack {
                                        Text("Other parameters").font(Font.headline.bold())
                                        
                                        Button { self.showDynamicState.toggle() } label: {
                                            if showDynamicState {
                                                Text("Hide dynamic state")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.up").foregroundColor(.black)
                                            } else {
                                                Text("Show dynamic state")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.down").foregroundColor(.black)
                                            }
                                        }.buttonStyle(.bordered)
                                        if showDynamicState {
                                            VStack {
                                                Text("Dynamic state info").font(Font.headline.bold())
                                                Text("\(model.dynamicState)")
                                                Button("Get current dynamic state", action: {model.getDynamicState()}).buttonStyle(.bordered)
                                            }
                                            VStack {
                                                Text("Set dynamic state of viDoc").font(Font.headline.bold())
                                                Text("RAM only").font(Font.headline.bold())
                                                HStack {
                                                    Button("Pedestrian", action: {model.setDynamicState(type: .pedestrian)}).buttonStyle(.bordered)
                                                    Button("Stationary", action: {model.setDynamicState(type: .stationary)}).buttonStyle(.bordered)
                                                }
                                            }
                                        }
                                        Button { self.showNavdop.toggle() } label: {
                                            if showNavdop {
                                                Text("Hide NAV-DOP/PVT Control")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.up").foregroundColor(.black)
                                            } else {
                                                Text("Show NAV-DOP/PVT Control")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.down").foregroundColor(.black)
                                            }
                                        }.buttonStyle(.bordered)
                                        
                                        if showNavdop {
                                            VStack {
                                                Text("NAVDOP").font(Font.headline.bold())
                                                HStack {
                                                    Button("Enable", action: { model.changeStatusNAVDOP(activate: true)}).buttonStyle(.bordered)
                                                    Button("Disable", action: { model.changeStatusNAVDOP(activate: false)}).buttonStyle(.bordered)
                                                }
                                                Text("NAVPVT").font(Font.headline.bold())
                                                HStack {
                                                    Button("Enable", action: { model.changeStatusNAVPVT(activate: true)}).buttonStyle(.bordered)
                                                    Button("Disable", action: { model.changeStatusNAVPVT(activate: false)}).buttonStyle(.bordered)
                                                }
                                            }
                                        }
                                    }
                                    VStack {
                                        Button { self.showGNSS.toggle() } label: {
                                            if showGNSS {
                                                Text("Hide Constellation info")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.up").foregroundColor(.black)
                                            } else {
                                                Text("Show Constellation info")
                                                    .font(Font.headline.bold())
                                                    .foregroundColor(.black)
                                                Image(systemName: "chevron.down").foregroundColor(.black)
                                            }
                                        }.buttonStyle(.bordered)
                                        if showGNSS {
                                            VStack {
                                                Text("GNSS Constellation info").font(Font.headline.bold())
                                                VStack {
                                                    Text("Satellite: \(model.satelliteGNSS)")
                                                    Text("Status: \(model.satelliteStatusGNSS)")
                                                }
                                                VStack {
                                                    HStack {
                                                        Button("Status GPS",action: { model.getCurrentStatusGNSS(satellite: .gps)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("Status Glonass",action: { model.getCurrentStatusGNSS(satellite: .glonass)}).buttonStyle(.bordered)
                                                        Button("Enable", action: { model.changeStatusGNSS(satellite: .glonass, activate: true)}).buttonStyle(.bordered)
                                                        Button("Disable", action: { model.changeStatusGNSS(satellite: .glonass, activate: false)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("Status BeiDou",action: { model.getCurrentStatusGNSS(satellite: .beidou)}).buttonStyle(.bordered)
                                                        Button("Enable", action: { model.changeStatusGNSS(satellite: .beidou, activate: true)}).buttonStyle(.bordered)
                                                        Button("Disable", action: { model.changeStatusGNSS(satellite: .beidou, activate: false)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("Status Galileo",action: { model.getCurrentStatusGNSS(satellite: .galileo)}).buttonStyle(.bordered)
                                                        Button("Enable", action: { model.changeStatusGNSS(satellite: .galileo, activate: true)}).buttonStyle(.bordered)
                                                        Button("Disable", action: { model.changeStatusGNSS(satellite: .galileo, activate: false)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("Status QZSS",action: { model.getCurrentStatusGNSS(satellite: .qzss)}).buttonStyle(.bordered)
                                                        Button("Enable", action: { model.changeStatusGNSS(satellite: .qzss, activate: true)}).buttonStyle(.bordered)
                                                        Button("Disable", action: { model.changeStatusGNSS(satellite: .qzss, activate: false)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("Status SBAS",action: { model.getCurrentStatusGNSS(satellite: .sbas)}).buttonStyle(.bordered)
                                                        Button("Enable", action: { model.changeStatusGNSS(satellite: .sbas, activate: true)}).buttonStyle(.bordered)
                                                        Button("Disable", action: { model.changeStatusGNSS(satellite: .sbas, activate: false)}).buttonStyle(.bordered)
                                                    }
                                                    Button("Activate all constellation GNSS", action: { model.activateAllConstellationGNSS()}).buttonStyle(.bordered)
                                                }
                                            }
                                        }
                                        VStack {
                                            Button { self.showElevation.toggle() } label: {
                                                if showElevation {
                                                    Text("Hide Elevation info")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Image(systemName: "chevron.up").foregroundColor(.black)
                                                } else {
                                                    Text("Show Elevation info")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Image(systemName: "chevron.down").foregroundColor(.black)
                                                }
                                            }.buttonStyle(.bordered)
                                            if showElevation {
                                                VStack {
                                                    Text("Elevation info").font(Font.headline.bold())
                                                    Text("Current minimum elevation = \(model.elevation)")
                                                    Button("Get current minimum elevation", action: { model.getMinimumElevation()}).buttonStyle(.bordered)
                                                }
                                                VStack {
                                                    Text("Set minimum elevation").font(Font.headline.bold())
                                                    HStack {
                                                        Button("00°", action: {model.setMinimumElevation(angle: .ang0)}).buttonStyle(.bordered)
                                                        Button("15°", action: {model.setMinimumElevation(angle: .ang15)}).buttonStyle(.bordered)
                                                        Button("30°", action: {model.setMinimumElevation(angle: .ang30)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("05°", action: {model.setMinimumElevation(angle: .ang5)}).buttonStyle(.bordered)
                                                        Button("20°", action: {model.setMinimumElevation(angle: .ang20)}).buttonStyle(.bordered)
                                                        Button("35°", action: {model.setMinimumElevation(angle: .ang35)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("10°", action: {model.setMinimumElevation(angle: .ang10)}).buttonStyle(.bordered)
                                                        Button("25°", action: {model.setMinimumElevation(angle: .ang25)}).buttonStyle(.bordered)
                                                        Button("40°", action: {model.setMinimumElevation(angle: .ang40)}).buttonStyle(.bordered)
                                                    }
                                                }
                                            }
                                        }
                                        VStack {
                                            Button { self.showRate.toggle() } label: {
                                                if showRate {
                                                    Text("Hide Rate Control")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Image(systemName: "chevron.up").foregroundColor(.black)
                                                } else {
                                                    Text("Show Rate Control")
                                                        .font(Font.headline.bold())
                                                        .foregroundColor(.black)
                                                    Image(systemName: "chevron.down").foregroundColor(.black)
                                                }
                                            }.buttonStyle(.bordered)
                                            if showRate {
                                                VStack {
                                                    Text("Changing rate info").font(Font.headline.bold())
                                                    HStack {
                                                        Text("  Current rate: ").font(Font.headline.bold())
                                                        Text(model.currentRate)
                                                    }
                                                    Button("Get current changing rate", action: { model.getChangingRateOfMessage()}).buttonStyle(.bordered)
                                                }
                                                VStack {
                                                    Text("Set changing Rate of message").font(Font.headline.bold())
                                                    Text("RAM only").font(Font.headline.bold())
                                                    Button("7Hz (Default)", action: {model.setChangingRateOfMessage(.hertz7)}).buttonStyle(.bordered)
                                                    
                                                    HStack {
                                                        Button("1Hz", action: {model.setChangingRateOfMessage(.hertz1)}).buttonStyle(.bordered)
                                                        Button("4Hz", action: {model.setChangingRateOfMessage(.hertz4)}).buttonStyle(.bordered)
                                                        Button("8Hz", action: {model.setChangingRateOfMessage(.hertz8)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("2Hz", action: {model.setChangingRateOfMessage(.hertz2)}).buttonStyle(.bordered)
                                                        Button("5Hz", action: {model.setChangingRateOfMessage(.hertz5)}).buttonStyle(.bordered)
                                                        Button("9Hz", action: {model.setChangingRateOfMessage(.hertz9)}).buttonStyle(.bordered)
                                                    }
                                                    HStack {
                                                        Button("3Hz", action: {model.setChangingRateOfMessage(.hertz3)}).buttonStyle(.bordered)
                                                        Button("6Hz", action: {model.setChangingRateOfMessage(.hertz6)}).buttonStyle(.bordered)
                                                        Button("10Hz", action: {model.setChangingRateOfMessage(.hertz10)}).buttonStyle(.bordered)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Submit") {
                                hideKeyboard()
                            }
                        }
                    }
                    .alert(isPresented: $model.showingAlert) {
                        Alert(title: Text(model.titleAlert), message: Text(model.messageAlert), dismissButton: .default(Text("OK")))
                    }
                }
            }.padding(10)
        }.preferredColorScheme(.light)
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: Model())
    }
}

struct LoadingView<Content>: View where Content: View {

    @Binding var isShowing: Bool
    @Binding var message: String
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)

                VStack {
                    Text("Please wait...")
                    Text(message)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}

struct NTRIPControlView: View {

    // MARK: Observable objects

    @ObservedObject var model: Model
    @State private var showNtrip = false

    // MARK: Init

    init(model: Model) {
        self.model = model
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            VStack{
                Button {
                    self.showNtrip.toggle()
                } label: {
                    if showNtrip {
                        Text("Hide NTRIP control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Show NTRIP control")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }
                .buttonStyle(.bordered)
                
                if showNtrip {
                    VStack {
                        Text("NTRIP configuration").font(Font.headline.bold()).padding()
                        VStack {
                            if !model.ntripCridentials.isEmpty {
                                Text("Save credentials").font(Font.headline.bold())
                                ForEach(model.ntripCridentials, id: \.self) { current in
                                    Button {
                                        model.hostname = current.host
                                        model.port = String(current.port)
                                        model.username = current.login
                                        model.password = current.pass
                                        model.atMountPoint = current.mountpoint
                                    } label: {
                                        Text("Use \(current.host)")
                                            .font(Font.headline.bold())
                                            .foregroundColor(.black)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(6)
                                }
                            }
                        }
                        HStack {
                            Text("  Mount point: ")
                            TextField("Mount point", text: $model.atMountPoint)
                                .keyboardType(UIKeyboardType.default)
                            Spacer()
                        }
                        HStack {
                            Text("  Hostname: ")
                            TextField("Hostname", text: $model.hostname)
                                .keyboardType(UIKeyboardType.default)
                            Spacer()
                        }
                        HStack {
                            Text("  Port: ")
                            TextField("Port", text: $model.port)
                                .keyboardType(UIKeyboardType.decimalPad)
                            Spacer()
                        }
                        HStack {
                            Text("  Username: ")
                            TextField("Username", text: $model.username)
                                .keyboardType(UIKeyboardType.default)
                            Spacer()
                        }
                        HStack {
                            Text("  Password: ")
                            TextField("Password", text: $model.password)
                                .keyboardType(UIKeyboardType.default)
                            Spacer()
                        }
                    }.padding(6)
                    VStack {
                        Text("NTRIP control").font(Font.headline.bold())
                        HStack {
                            Button { model.connectToNtrip() } label: {
                                Text("Connect")
                                    .font(Font.headline.bold())
                                    .foregroundColor(.black)
                            }.buttonStyle(.bordered)
                            Button { model.disconnectNtrip() } label: {
                                Text("Disconnect")
                                    .font(Font.headline.bold())
                                    .foregroundColor(.black)
                            }.buttonStyle(.bordered)
                            Button { model.reccon() } label: {
                                Text("Reconnect")
                                    .font(Font.headline.bold())
                                    .foregroundColor(.black)
                            }.buttonStyle(.bordered)
                        }.padding(10)
                        Button { model.recconWithReset() } label: {
                            Text("Reconnect Ntrip with Reset")
                                .font(Font.headline.bold())
                                .foregroundColor(.black)
                        }.buttonStyle(.bordered)
                    }
                }
            }
            VStack {
                Text("NTRIP info")
                    .font(Font.headline.bold())
                    .padding(6)
                HStack {
                    Text("  Status: ").font(Font.headline.bold())
                    Text("\(model.ntripStatus)")
                    Spacer()
                }
            }.padding(6)
            VStack {
                Text("NTRIP received data info")
                    .font(Font.headline.bold())
                    .padding(6)
                ScrollView{
                    TextEditor(text: .constant(model.ntripSizeParcel))
                        .font(.system(size: 10.0))
                        .border(Color.black, width: 1)
                        .frame(width: UIScreen.main.bounds.size.width-32, height: 150, alignment: .topLeading)
                }
            }.padding(6)
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
