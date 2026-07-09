//
//  CorrectionToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

@MainActor
final class CorrectionToolsViewModel: ObservableObject {

    @Published private(set) var rmxIsActive = false
    @Published private(set) var rawxMessage = ""
    @Published private(set) var sfrbxMessage = ""
    @Published var timerValue = ""
    @Published var listOfUBXFiles = [String]()
    @Published var fileLinkForUBXFile: URL?
    @Published var isSharePresented = false
    @Published var isRecordingActive = false

    var alertPresenter: ((String, String) -> Void)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()

    init(model: MainScreenModel) {
        self.model = model
        configurePublishers()
    }

    func changeStatusRXM(activate: Bool) {
        if !activate {
            isRecordingActive = false
        }
        model.changeStatusRXM(activate: activate)
    }

    func startRecordPPKMeasurements() {
        isRecordingActive = true
        model.startRecordPPKMeasurements()
    }

    func stopRecordPPKMeasurements() {
        isRecordingActive = false
        model.stopRecordPPKMeasurements()
    }

    func getAllUBXFiles() {
        switch model.getAllUBXFiles() {
        case .success(let values):
            listOfUBXFiles = values
        case .failure:
            presentAlert(
                title: "Error",
                message: "Directory PPK is not found. Please check access app to files"
            )
        }
    }

    func shareUBXFile(filename: String, pathName: String = "PPK") {
        fileLinkForUBXFile = model.getUBXFile(filename: filename, pathName: pathName)
        isSharePresented = fileLinkForUBXFile != nil
    }

    func clearSharedUBXFile() {
        fileLinkForUBXFile = nil
        isSharePresented = false
    }

    func resetSessionState() {
        rmxIsActive = false
        rawxMessage = ""
        sfrbxMessage = ""
        timerValue = ""
        listOfUBXFiles.removeAll()
        isRecordingActive = false
        clearSharedUBXFile()
    }

    private func configurePublishers() {
        model.satelliteMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                switch message {
                case .rawx(let value):
                    self?.rawxMessage = value.message.hexStringWithSpace()
                case .sfrbx(let value):
                    self?.sfrbxMessage = value.message.hexStringWithSpace()
                default:
                    break
                }
            }
            .store(in: &subscription)

        model.ppkMeasurementsState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.rmxIsActive = value
                if value == false {
                    self?.isRecordingActive = false
                }
            }
            .store(in: &subscription)

        model.ppkMeasurementsTimer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.timerValue = value
            }
            .store(in: &subscription)

    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }
}
