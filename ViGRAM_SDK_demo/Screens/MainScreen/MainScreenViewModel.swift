//
//  MainScreenViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 12.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

extension MainScreenView {
    @MainActor final class MainScreenViewModel: ObservableObject {

        @Published var isShowingAlert = false
        @Published private(set) var titleAlert = ""
        @Published private(set) var messageAlert = ""
 
        let deviceSession: DeviceSessionViewModel
        let ntripTools: NtripToolsViewModel
        let gnssTools: GNSSToolsViewModel
        let supportLogTools: SupportLogToolsViewModel
        let serviceTools: ServiceToolsViewModel
        let correctionTools: CorrectionToolsViewModel
        let laserTools: LaserToolsViewModel
        let singlePointTools: SinglePointToolsViewModel

        init(vigramHelper: VigramHelper) {
            let model = MainScreenModel(vigramHelper: vigramHelper)
            let deviceSession = DeviceSessionViewModel(model: model)
            self.deviceSession = deviceSession
            ntripTools = NtripToolsViewModel(model: model)
            gnssTools = GNSSToolsViewModel(model: model)
            supportLogTools = SupportLogToolsViewModel()
            serviceTools = ServiceToolsViewModel(model: model)
            correctionTools = CorrectionToolsViewModel(model: model)
            laserTools = LaserToolsViewModel(model: model)
            singlePointTools = SinglePointToolsViewModel(model: model)

            let presentAlert: (String, String) -> Void = { [weak self] title, message in
                self?.presentAlert(title: title, message: message)
            }

            deviceSession.alertPresenter = presentAlert
            deviceSession.laserMeasurementHandler = { [weak self] measurement in
                self?.laserTools.handleLaserMeasurement(measurement)
            }
            deviceSession.reconnectNtripIfReadyAfterReset = { [weak self] in
                self?.ntripTools.reconnectToNTRIP(showAlertWhenNotReady: false) ?? false
            }
            deviceSession.resumeNtripReconnectAfterReset = { [weak self] in
                self?.ntripTools.resumeReconnectAfterReset()
            }
            deviceSession.resetDependentSessionState = { [weak self] in
                guard let self else { return }
                self.ntripTools.handleDeviceDisconnect()
                self.gnssTools.resetSessionState()
                self.serviceTools.resetSessionState()
                self.correctionTools.resetSessionState()
                self.laserTools.resetSessionState()
                self.singlePointTools.resetSessionState()
            }

            ntripTools.alertPresenter = presentAlert
            supportLogTools.alertPresenter = presentAlert
            serviceTools.alertPresenter = presentAlert
            gnssTools.alertPresenter = presentAlert
            correctionTools.alertPresenter = presentAlert
            laserTools.alertPresenter = presentAlert
            singlePointTools.alertPresenter = presentAlert

            serviceTools.disconnectHandler = { [weak deviceSession] in
                deviceSession?.disconnect()
            }
            ntripTools.requestReconnectWithReset = { [weak self, weak deviceSession] in
                self?.serviceTools.resetSessionState()
                deviceSession?.beginResetReconnect()
            }

            laserTools.protocolVersionProvider = { [weak deviceSession] in
                deviceSession?.protocolVersion
            }
            laserTools.durationProvider = { [weak deviceSession] in
                deviceSession?.durationMeasurements ?? ""
            }
            laserTools.selectedLaserPositionDidChange = { [weak self] position in
                self?.singlePointTools.activateLaserMeasurement(position: position)
            }

            ntripTools.readinessStatusProvider = { [weak deviceSession] in
                guard let deviceSession else {
                    return .waitingForGNSS
                }
                return NtripReadinessState(
                    canConnect: deviceSession.canConnectToNtrip,
                    message: deviceSession.ntripReadinessMessage
                )
            }
            ntripTools.currentDeviceNameProvider = { [weak deviceSession] in
                deviceSession?.currentDeviceName ?? ""
            }
            ntripTools.currentTimeProvider = { [weak deviceSession] in
                deviceSession?.currentTimeString ?? ""
            }
            ntripTools.clearDependentMeasurementState = { [weak self] in
                self?.singlePointTools.clearMeasurementResult()
            }

            singlePointTools.durationProvider = { [weak deviceSession] in
                deviceSession?.durationMeasurements ?? ""
            }
            singlePointTools.protocolVersionProvider = { [weak deviceSession] in
                deviceSession?.protocolVersion
            }
            singlePointTools.selectedLaserPositionProvider = { [weak self] in
                self?.laserTools.selectedPosition ?? .bottom
            }
            singlePointTools.selectedLaserShotModeProvider = { [weak self] in
                self?.laserTools.selectedShotMode ?? .fast
            }
            singlePointTools.laserDistanceProvider = { [weak self] in
                self?.laserTools.measuredDistance ?? 0.0
            }

            model.start()
            supportLogTools.configureBasicSupportLogOnLaunch()
        }

        private func presentAlert(title: String, message: String) {
            titleAlert = title
            messageAlert = message
            isShowingAlert = true
        }
    }
}
