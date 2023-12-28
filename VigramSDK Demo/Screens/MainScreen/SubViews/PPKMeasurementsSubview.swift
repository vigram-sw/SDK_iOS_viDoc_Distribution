//
//  PPKMeasurementsSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 18.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct PPKMeasurementsSubview: View {
    
    // MARK: Private properties
    
    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showRecordFiles = false
    @State private var recordIsActive = false

    // MARK: Init
    
    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: Computed properties
    
    var body: some View {
        VStack {
            Text("UBX measurements control").font(Font.headline.bold()).foregroundColor(.black)
            if viewModel.rmxIsActive {
                Text("RMX is active").font(Font.headline.bold()).foregroundColor(.green)
            }
            HStack {
                Button {
                    viewModel.changeStatusRXM(activate: true)
                } label: {
                    Text("Activate RXM")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                }.buttonStyle(.bordered)
                Button {
                    viewModel.changeStatusRXM(activate: false)
                } label: {
                    Text("Disactivate RXM")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                }.buttonStyle(.bordered)
            }
            if recordIsActive {
                Text("Record is active").font(Font.headline.bold()).foregroundColor(.green)
                Text(viewModel.timerValue)
            }
            if viewModel.rmxIsActive {
                HStack {
                    Button {
                        recordIsActive = true
                        UIApplication.shared.isIdleTimerDisabled = true
                        viewModel.startRecordPPKMeasurements()
                    } label: {
                        Text("Start record PPK")
                            .font(Font.headline.bold())
                            .foregroundColor(.black)
                    }.buttonStyle(.bordered)
                    Button {
                        recordIsActive = false
                        UIApplication.shared.isIdleTimerDisabled = false
                        viewModel.stopRecordPPKMeasurements()
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
                Text(viewModel.rawxMessage)
                Text("Last sfrbx message:").font(Font.headline.bold())
                Text(viewModel.sfrbxMessage)
            }
            Button {
                self.showRecordFiles.toggle()
                viewModel.getAllUBXFiles()
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
               !viewModel.listOfUBXFiles.isEmpty {
                VStack {
                    Text("Available UBX files").font(Font.headline.bold())
                    ForEach(viewModel.listOfUBXFiles, id: \.self) { file in
                        Button {
                            viewModel.getUBXFile(filename: file, pathName: "PPK")
                        } label: {
                            Text(file)
                                .font(Font.headline.bold())
                                .foregroundColor(.green)
                        }.buttonStyle(.bordered)
                    }
                }.sheet(isPresented: $viewModel.isSharePresented, onDismiss: {
                    viewModel.fileLinkForUBXFile = nil
                }, content: {
                    ActivityViewController(activityItems: [viewModel.fileLinkForUBXFile!])
                })
            }
        }
    }
}
