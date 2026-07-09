//
//  NtripToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Combine
import Foundation
import VigramSDK

struct NtripReadinessState {
    let canConnect: Bool
    let message: String

    static let waitingForGNSS = NtripReadinessState(
        canConnect: false,
        message: "GGA data is not ready yet. Wait for a valid GNSS position before connecting NTRIP."
    )
}

private struct MountpointsCacheKey: Hashable {
    let hostname: String
    let port: Int
    let username: String
    let password: String
    let forceHTTPSMountpointsConnection: Bool
}

struct NtripPacketLogEntry: Identifiable, Equatable {
    let id: Int
    let sequence: Int
    let timestamp: String
    let packetLength: Int

    var displayText: String {
        "#\(sequence)  \(timestamp)  \(packetLength) bytes"
    }
}

@MainActor
final class NtripToolsViewModel: ObservableObject {

    @Published var ntripCredentials = [NtripCredentials]()
    @Published var mountPoint = ""
    @Published var hostname = ""
    @Published var port = ""
    @Published var username = ""
    @Published var password = ""
    @Published var forceHTTPSconnection = false
    @Published var forceHTTPSMountpointsConnection = false
    @Published private(set) var ntripSizeParcel = ""
    @Published private(set) var ntripPacketLogEntries = [NtripPacketLogEntry]()
    @Published private(set) var ntripStatus = "Not connected"
    @Published private(set) var isStartingNtrip = false
    @Published var mountPointsData = MountPointsValuesData(
        currentMountPointName: "",
        allMountPointNames: []
    )

    var alertPresenter: ((String, String) -> Void)?
    var requestReconnectWithReset: (() -> Void)?
    var clearDependentMeasurementState: (() -> Void)?
    var readinessStatusProvider: (() -> NtripReadinessState)?
    var currentDeviceNameProvider: (() -> String)?
    var currentTimeProvider: (() -> String)?

    private let model: MainScreenModel
    private var subscription = Set<AnyCancellable>()
    private let currentTimeDateFormatter = DateFormatter()
    private var socketCodeError: Int?
    private let maximumNtripPacketLogEntries = 50
    private var ntripPacketLogSequence = 0
    private var mountpointsSubscription: AnyCancellable?
    private var activeMountpointsRequestKey: MountpointsCacheKey?
    private var mountpointsCache = [MountpointsCacheKey: [String]]()

    init(model: MainScreenModel) {
        self.model = model
        currentTimeDateFormatter.dateFormat = "HH:mm:ss.SSS"
        ntripCredentials = model.getAllNtripCredential()
        configurePublishers()
    }

    var canConnectToNtrip: Bool {
        readinessStatusProvider?().canConnect ?? false
    }

    var ntripReadinessMessage: String {
        readinessStatusProvider?().message ?? NtripReadinessState.waitingForGNSS.message
    }

    var hasConnectionFields: Bool {
        !hostname.isEmpty &&
        !port.isEmpty &&
        !username.isEmpty &&
        !password.isEmpty &&
        !mountPoint.isEmpty
    }

    func connectToNTRIP() {
        guard canConnectToNtrip else {
            showNtripNotReadyAlert()
            return
        }

        guard let port = Int(port) else {
            presentAlert(title: "Error", message: "Incorrect data: port")
            return
        }

        do {
            try model.connectToNTRIP(
                hostname: hostname,
                port: port,
                username: username,
                password: password,
                mountPoint: mountPoint,
                forceHTTPSconnection: forceHTTPSconnection
            )
        } catch {
            presentAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @discardableResult
    func reconnectToNTRIP(showAlertWhenNotReady: Bool = true) -> Bool {
        guard canConnectToNtrip else {
            if showAlertWhenNotReady {
                showNtripNotReadyAlert()
            }
            return false
        }

        model.reConnectToNTRIP()
        return true
    }

    func reconnectToNTRIPWithReset() {
        requestReconnectWithReset?()
    }

    func resumeReconnectAfterReset() {
        model.reConnectToNTRIP()
    }

    func disconnectNtrip() {
        socketCodeError = nil
        isStartingNtrip = false
        ntripStatus = "No connection"
        clearNtripLog()
        model.disconnectNtrip()
    }

    func getMountpoints() {
        guard let port = Int(port) else {
            presentAlert(title: "Error", message: "Incorrect data: port")
            return
        }

        let requestKey = MountpointsCacheKey(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            forceHTTPSMountpointsConnection: forceHTTPSMountpointsConnection
        )
        let information = NtripConnectionInformation(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            forceHTTPSconnection: forceHTTPSconnection,
            forceHTTPSMountpointsConnection: forceHTTPSMountpointsConnection
        )

        mountpointsSubscription?.cancel()
        activeMountpointsRequestKey = requestKey
        resetMountpointResults(isLoading: true)

        if let cachedMountpoints = mountpointsCache[requestKey], !cachedMountpoints.isEmpty {
            applyMountpointNames(cachedMountpoints, isLoading: false)
        }

        guard let publisher = model.getMountpoints(for: information) else {
            let shouldPresentError = mountPointsData.allMountPointNames.isEmpty
            applyMountpointsError("NTRIP service is not available.", for: requestKey)
            if shouldPresentError {
                presentAlert(title: "Error", message: "NTRIP service is not available.")
            }
            return
        }

        mountpointsSubscription = publisher
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            guard let self else { return }
            switch completion {
            case .finished:
                guard activeMountpointsRequestKey == requestKey else { return }
                mountPointsData.isLoading = false
            case .failure(let error):
                guard activeMountpointsRequestKey == requestKey else { return }
                let shouldPresentError = mountPointsData.allMountPointNames.isEmpty
                applyMountpointsError(error.localizedDescription, for: requestKey)
                if shouldPresentError {
                    presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }) { [weak self] mountpoints in
            guard let self, activeMountpointsRequestKey == requestKey else { return }
            let mountpointNames = mountpoints.map(\.name)
            mountpointsCache[requestKey] = mountpointNames
            applyMountpointNames(mountpointNames, isLoading: false)
        }
    }

    func cancelMountpointsLoading() {
        mountpointsSubscription?.cancel()
        mountpointsSubscription = nil
        activeMountpointsRequestKey = nil
        mountPointsData.isLoading = false
    }

    func clearFields() {
        mountPoint = ""
        port = ""
        username = ""
        password = ""
        hostname = ""
        forceHTTPSconnection = false
        forceHTTPSMountpointsConnection = false
    }

    func applySavedServer(_ current: NtripCredentials) {
        hostname = current.host
        port = String(current.port)
        username = current.login
        password = current.pass
        mountPoint = current.mountpoint
        forceHTTPSconnection = current.forceHTTPSconnection
        forceHTTPSMountpointsConnection = current.forceHTTPSMountpointsConnection
    }

    func selectMountPoint(_ value: String) {
        mountPoint = value
    }

    func handleDeviceDisconnect() {
        clearNtripLog()
        mountpointsSubscription?.cancel()
        activeMountpointsRequestKey = nil
        resetMountpointResults(isLoading: false)
        ntripStatus = "Not connected"
        isStartingNtrip = false
        socketCodeError = nil
    }

    private func configurePublishers() {
        model.ntripData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self else { return }
                appendNtripPacketLog(packetLength: data.count)
            }
            .store(in: &subscription)

        model.ntripState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    socketCodeError = nil
                    ntripStatus = "Connection is ready"
                    isStartingNtrip = true
                    persistCurrentCredentialsIfNeeded()
                case .preparing:
                    ntripStatus = "Connection is preparing"
                case .setup:
                    ntripStatus = "Connection setup"
                case .waiting(let error):
                    ntripStatus = "Connection is waiting: \(error.localizedDescription)"
                case .socketError(let code):
                    ntripStatus = "Socket error: \(code)"
                    socketCodeError = code
                    isStartingNtrip = false
                case .unknownError(let message):
                    ntripStatus = "Connection error: \(message)"
                    isStartingNtrip = false
                case .cancelled:
                    if socketCodeError == nil {
                        ntripStatus = "Connection is cancelled"
                    }
                    isStartingNtrip = false
                    clearDependentMeasurementState?()
                case .reconnectScheduled(let attempt, let maxAttempts, let delay):
                    ntripStatus = "Retrying NTRIP connection \(attempt)/\(maxAttempts) in \(Int(delay))s"
                    isStartingNtrip = false
                case .reconnecting(let attempt, let maxAttempts):
                    ntripStatus = "Retrying NTRIP connection \(attempt)/\(maxAttempts)"
                    isStartingNtrip = false
                case .reconnectRestored(let attempt):
                    socketCodeError = nil
                    ntripStatus = "NTRIP connection restored on retry \(attempt)"
                    isStartingNtrip = true
                    persistCurrentCredentialsIfNeeded()
                case .reconnectFailed(let maxAttempts, let lastError):
                    let message = "NTRIP reconnect failed after \(maxAttempts) retries"
                    ntripStatus = message
                    isStartingNtrip = false
                    clearDependentMeasurementState?()
                    presentAlert(
                        title: "NTRIP reconnect failed",
                        message: lastError.map { "\(message). \($0.localizedDescription)" } ?? message
                    )
                case .failed(let error):
                    ntripStatus = "Connection is failed: \(error.localizedDescription)"
                    isStartingNtrip = false
                    clearDependentMeasurementState?()
                case .notConnected:
                    ntripStatus = "Not connected to Ntrip"
                    isStartingNtrip = false
                    clearDependentMeasurementState?()
                @unknown default:
                    break
                }
            }
            .store(in: &subscription)
    }

    private func persistCurrentCredentialsIfNeeded() {
        guard let port = Int(port) else { return }

        let currentNtripCredential = NtripCredentials(
            host: hostname,
            port: port,
            login: username,
            pass: password,
            mountpoint: mountPoint,
            forceHTTPSconnection: forceHTTPSconnection,
            forceHTTPSMountpointsConnection: forceHTTPSMountpointsConnection
        )

        guard ntripCredentials.first(where: { $0 == currentNtripCredential }) == nil else {
            return
        }

        ntripCredentials.append(currentNtripCredential)
        do {
            let data = try JSONEncoder().encode(ntripCredentials)
            UserDefaults.standard.set(data, forKey: "ntrip")
        } catch {
            presentAlert(title: "Update error", message: "Please try again...")
        }
    }

    private func showNtripNotReadyAlert() {
        presentAlert(
            title: "GNSS is not ready",
            message: "GGA data is not valid yet. Keep the viDoc under open sky and wait until GNSS is ready, then connect NTRIP."
        )
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }

    private func resetMountpointResults(isLoading: Bool) {
        mountPointsData.currentMountPointName = ""
        mountPointsData.allMountPointNames = []
        mountPointsData.errorMessage = nil
        mountPointsData.isLoading = isLoading
    }

    private func applyMountpointNames(_ names: [String], isLoading: Bool) {
        mountPointsData.currentMountPointName = names.first ?? ""
        mountPointsData.allMountPointNames = names
        mountPointsData.errorMessage = nil
        mountPointsData.isLoading = isLoading
    }

    private func applyMountpointsError(_ message: String, for requestKey: MountpointsCacheKey) {
        guard activeMountpointsRequestKey == requestKey else { return }

        mountPointsData.isLoading = false
        if mountPointsData.allMountPointNames.isEmpty {
            mountPointsData.errorMessage = message
        }
    }

    private func currentLogTimestamp() -> String {
        let providerValue = currentTimeProvider?().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !providerValue.isEmpty {
            return providerValue
        }
        return currentTimeDateFormatter.string(from: Date())
    }

    private func appendNtripPacketLog(packetLength: Int) {
        ntripPacketLogSequence += 1
        let entry = NtripPacketLogEntry(
            id: ntripPacketLogSequence,
            sequence: ntripPacketLogSequence,
            timestamp: currentLogTimestamp(),
            packetLength: packetLength
        )

        ntripPacketLogEntries.append(entry)
        if ntripPacketLogEntries.count > maximumNtripPacketLogEntries {
            ntripPacketLogEntries.removeFirst(ntripPacketLogEntries.count - maximumNtripPacketLogEntries)
        }
        ntripSizeParcel = ntripPacketLogEntries.map(\.displayText).joined(separator: "\n")
    }

    private func clearNtripLog() {
        ntripPacketLogEntries.removeAll(keepingCapacity: true)
        ntripPacketLogSequence = 0
        ntripSizeParcel = ""
    }
}
