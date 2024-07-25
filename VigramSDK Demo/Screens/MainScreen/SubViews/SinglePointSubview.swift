//
//  SinglePointSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 15.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct SinglePointSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showOffsets = false
    @State private var showDeviation = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            Text("Single point measurement").font(Font.headline.bold())
            Text(viewModel.timerMeasurementValue).font(Font.headline.bold()).foregroundColor(Color(uiColor: .red))
            if let singlePoint = viewModel.singlePointMeasurement {
                Text("Device parametres").font(Font.headline.bold())
                VStack {
                    HStack {
                        Text("Duration = ").font(Font.headline.bold())
                        Text("\(NSInteger(singlePoint.duration) % 60)")
                        Spacer()
                    }
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
                if viewModel.useMeasurementsWithLaser {
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
                    if let correctedCoordinateWithFormula = viewModel.correctedCoordinateWithFormula {
                        Text("Corrected coordinate with Formula").font(Font.headline.bold())
                        VStack {
                            HStack {
                                Text("Latitude: ").font(Font.headline.bold())
                                Text(
                                    String(
                                        format: "%.10f",
                                        correctedCoordinateWithFormula.latitude
                                    )
                                )
                                Spacer()
                            }
                            HStack {
                                Text("Longitude: ").font(Font.headline.bold())
                                Text(
                                    String(
                                        format: "%.10f",
                                        correctedCoordinateWithFormula.longitude
                                    )
                                )
                                Spacer()
                            }
                            HStack {
                                Text("Reference altitude: ").font(Font.headline.bold())
                                Text(
                                    String(
                                        format: "%.10f",
                                        correctedCoordinateWithFormula.referenceAltitude
                                    )
                                )
                                Spacer()
                            }
                            HStack {
                                Text("Geoid separation: ").font(Font.headline.bold())
                                Text(
                                    String(
                                        format: "%.10f",
                                        correctedCoordinateWithFormula.geoidSeparation
                                    )
                                )
                                Spacer()
                            }
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
                    isSelected: $viewModel.useMeasurementsWithLaser,
                    color: .green,
                    text: "Use laser"
                ).onTapGesture {
                    if viewModel.isBackLaserSelected {
                        viewModel.setCurrentOffset(with: .back)
                    } else {
                        viewModel.setCurrentOffset(with: .bottom)
                    }
                    viewModel.useMeasurementsWithLaser = true
                    if viewModel.useMeasurementsWithLaser {
                        viewModel.useMeasurementsWithoutLaset = false
                    }
                }
                SelectButton(
                    isSelected: $viewModel.useMeasurementsWithoutLaset,
                    color: .green,
                    text: "Without laser"
                ).onTapGesture {
                    viewModel.setCurrentCameraOffsets()
                    viewModel.useMeasurementsWithoutLaset = true
                    if viewModel.useMeasurementsWithoutLaset {
                        viewModel.useMeasurementsWithLaser = false
                    }
                }
            }
            VStack{
                HStack {
                    Text("  The distance to the \n  ground (cm): ").font(Font.headline.bold())
                    TextField("50", text: $viewModel.distanceToGround)
                        .keyboardType(UIKeyboardType.decimalPad)
                    Spacer()
                }
                HStack {
                    Text("  Duration (second): ").font(Font.headline.bold())
                    TextField("5", text: $viewModel.durationMeasurements)
                        .keyboardType(.decimalPad)
                    Spacer()
                }
                Button {
                    self.showOffsets.toggle()
                    if showOffsets {
                        if viewModel.useMeasurementsWithLaser {
                            if viewModel.isBackLaserSelected {
                                viewModel.setCurrentOffset(with: .back)
                            } else {
                                viewModel.setCurrentOffset(with: .bottom)
                            }
                        } else {
                            viewModel.setCurrentCameraOffsets()
                        }
                    }
                } label: {
                    if showOffsets {
                        Text("Offsets option")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.up").foregroundColor(.black)
                    } else {
                        Text("Offsets option")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down").foregroundColor(.black)
                    }
                }
                .buttonStyle(.bordered)
                
                if showOffsets {
                    VStack {
                        Text("Current offsets:").font(Font.headline.bold())
                        Text("\(viewModel.currentOffsetsString)")
                        
                        Text("Current offsets values").font(Font.headline.bold())
                        HStack{
                            Text("x = ").font(Font.headline.bold())
                            Text("\(viewModel.currentOffsets.x)")
                        }
                        HStack{
                            Text("y = ").font(Font.headline.bold())
                            Text("\(viewModel.currentOffsets.y)")
                        }
                        HStack{
                            Text("z = ").font(Font.headline.bold())
                            Text("\(viewModel.currentOffsets.z)")
                        }
                    }
                    ForEach(viewModel.currentAllOffsets, id: \.self.0) { offset in
                        Button {
                            viewModel.currentOffsets = offset.1
                            viewModel.currentOffsetsString = offset.0
                        } label: {
                            Text(offset.0)
                                .font(Font.headline.bold())
                                .foregroundColor(.green)
                        }.buttonStyle(.bordered)
                    }
                }
            }
            Button { viewModel.startSPMeasurement() } label: {
                Text("Start SP measurement")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            if let protocolVersion = viewModel.protocolVersion, protocolVersion > 1 {
                Button { viewModel.stopSPMeasurement() } label: {
                    Text("Stop SP measurement")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                }.buttonStyle(.bordered)
            }
            if let protocolVersion = viewModel.protocolVersion, protocolVersion > 1 {
                Button { viewModel.cancelSPMeasurement() } label: {
                    Text("Cancel SP measurement")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                }.buttonStyle(.bordered)
            }
        }.padding(6)
    }
}
