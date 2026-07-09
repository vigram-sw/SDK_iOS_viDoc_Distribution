//
//  ServiceToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

@MainActor
final class ServiceToolsViewModel: ObservableObject {

    @Published private(set) var resetMessageError = ""
    @Published private(set) var viDocState = ""

    var alertPresenter: ((String, String) -> Void)?
    var disconnectHandler: (() -> Void)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()

    init(model: MainScreenModel) {
        self.model = model
        configurePublishers()
    }

    func requestBattery() {
        model.requestBattery()
    }

    func requestVersion() {
        model.requestVersion()?
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &subscription)
    }

    func replaceIdentity(isReset: Bool) {
        model.getNewIdentity(isReset: isReset)?
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }) { [weak self] result in
                switch result {
                case .success(let isSuccessful):
                    self?.presentAlert(
                        title: isSuccessful ? "Success" : "Failed",
                        message: isSuccessful
                            ? "Success \(isReset ? "reset" : "to set new") identity. Please reconect to viDoc"
                            : "Failed to set new identity"
                    )

                    if isSuccessful {
                        self?.disconnectHandler?()
                    }
                case .failure(let error):
                    self?.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
            .store(in: &subscription)
    }

    func resetDevice() {
        resetSessionState()
        model.resetDevice()
    }

    func clearTXTLog() {
        viDocState = ""
    }

    func resetSessionState() {
        resetMessageError = ""
        viDocState = ""
    }

    private func configurePublishers() {
        model.resetState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .isReseting(let isResetting):
                    if isResetting {
                        self?.resetMessageError = ""
                    }
                case .failure(let message):
                    self?.resetMessageError = message
                @unknown default:
                    break
                }
            }
            .store(in: &subscription)

        model.viDocState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.appendViDocState(state)
            }
            .store(in: &subscription)
    }

    private func appendViDocState(_ state: StateViDoc) {
        let line: String

        switch state {
        case .user(let message):
            guard message != "Starting viDoc" else { return }
            line = "\(Date().getCurrentDateToString())- GNTXT - User Message: \(message)\r\n "
        case .error(let message):
            guard message != "Starting viDoc" else { return }
            line = "\(Date().getCurrentDateToString())- GNTXT - Error Message: \(message)\r\n "
        case .warning(let message):
            guard message != "Starting viDoc" else { return }
            line = "\(Date().getCurrentDateToString())- GNTXT - Warning Message: \(message)\r\n "
        case .notice(let message):
            guard message != "Starting viDoc" else { return }
            line = "\(Date().getCurrentDateToString())- GNTXT - Notice Message: \(message)\r\n "
        @unknown default:
            return
        }

        viDocState += line
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }
}
