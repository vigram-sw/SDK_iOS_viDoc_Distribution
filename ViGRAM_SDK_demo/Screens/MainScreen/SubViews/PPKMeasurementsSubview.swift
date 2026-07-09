//
//  PPKMeasurementsSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI
import UIKit

struct PPKMeasurementsSubview: View {

    @ObservedObject private var viewModel: CorrectionToolsViewModel
    @State private var showFiles = false

    init(viewModel: CorrectionToolsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ClientCard(
            title: "PPK Recorder",
            subtitle: "Raw UBX recording for post-processing workflows."
        ) {
            ClientStatusRow(title: "RXM", value: viewModel.rmxIsActive ? "Active" : "Inactive")

            if viewModel.isRecordingActive {
                ClientStatusRow(title: "Record timer", value: viewModel.timerValue)
            }

            ClientActionGrid(minimumWidth: 150) {
                Button("Activate RXM") {
                    viewModel.changeStatusRXM(activate: true)
                }
                .buttonStyle(.bordered)

                Button("Deactivate RXM") {
                    UIApplication.shared.isIdleTimerDisabled = false
                    viewModel.changeStatusRXM(activate: false)
                }
                .buttonStyle(.bordered)
            }

            if viewModel.rmxIsActive {
                ClientActionGrid(minimumWidth: 150) {
                    Button("Start record") {
                        UIApplication.shared.isIdleTimerDisabled = true
                        viewModel.startRecordPPKMeasurements()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button("Stop record") {
                        UIApplication.shared.isIdleTimerDisabled = false
                        viewModel.stopRecordPPKMeasurements()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if viewModel.isRecordingActive {
                Text("Last raw messages")
                    .font(.subheadline.bold())
                    .foregroundStyle(ClientTheme.textPrimary)

                ClientLogBox(
                    text: """
                        RAWX
                        \(viewModel.rawxMessage.isEmpty ? "No RAWX message yet." : viewModel.rawxMessage)

                        SFRBX
                        \(viewModel.sfrbxMessage.isEmpty ? "No SFRBX message yet." : viewModel.sfrbxMessage)
                        """,
                    placeholder: "No raw messages yet."
                )
            }

            Button {
                showFiles.toggle()
                if showFiles {
                    viewModel.getAllUBXFiles()
                }
            } label: {
                HStack {
                    Text(showFiles ? "Hide record files" : "Show record files")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: showFiles ? "chevron.up" : "chevron.down")
                }
                .foregroundStyle(ClientTheme.textPrimary)
            }
            .buttonStyle(.bordered)

            if showFiles {
                if viewModel.listOfUBXFiles.isEmpty {
                    Text("No UBX files found yet.")
                        .font(.subheadline)
                        .foregroundStyle(ClientTheme.textSecondary)
                } else {
                    ForEach(viewModel.listOfUBXFiles, id: \.self) { file in
                        Button(file) {
                            viewModel.shareUBXFile(filename: file)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isSharePresented, onDismiss: {
            viewModel.clearSharedUBXFile()
        }) {
            if let fileURL = viewModel.fileLinkForUBXFile {
                ActivityViewController(activityItems: [fileURL])
            }
        }
        .onChange(of: viewModel.rmxIsActive) { isActive in
            if !isActive {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}
