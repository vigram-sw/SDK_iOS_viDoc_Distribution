//
//  SupportLogToolsViewModel.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import Foundation
import VigramSDK

@MainActor
final class SupportLogToolsViewModel: ObservableObject {

    @Published private(set) var diagnosticLogMode: DiagnosticLogModeOption = .off
    @Published private(set) var supportLogStatus = "Basic support log is starting"
    @Published private(set) var supportLogFileName = "No file"
    @Published var isSharePresented = false
    @Published var shareItems = [Any]()

    var alertPresenter: ((String, String) -> Void)?

    private var currentBasicSupportLogFileURL: URL?
    private var currentDiagnosticSupportLogFileURL: URL?
    private var currentSupportLogFileURL: URL?

    func configureBasicSupportLogOnLaunch() {
        do {
            try activateBasicSupportLog()
        } catch {
            currentSupportLogFileURL = nil
            supportLogStatus = "Basic support log could not start"
            supportLogFileName = "No file"
        }
    }

    func updateDiagnosticLogMode(_ newMode: DiagnosticLogModeOption) {
        guard diagnosticLogMode != newMode else { return }

        do {
            switch newMode {
            case .off:
                diagnosticLogMode = .off
                try activateBasicSupportLog()
            case .on:
                diagnosticLogMode = .on
                let fileURL = try ensureSupportLogFileURL(for: .diagnostic)
                try activateSupportLog(mode: .diagnostic, fileURL: fileURL)
            }
        } catch {
            diagnosticLogMode = .off
            refreshSupportLogStatus()
            presentAlert(title: "Error", message: error.localizedDescription)
        }
    }

    func exportSupportLog() {
        guard let fileURL = currentSupportLogFileURL,
              FileWorker.checkIsExist(file: fileURL) else {
            presentAlert(
                title: "Error",
                message: SupportLogExportError.fileIsNotAvailable.localizedDescription
            )
            return
        }

        shareItems = [fileURL]
        isSharePresented = true
        supportLogStatus = diagnosticLogMode == .on
            ? "Diagnostic support log ready to share"
            : "Basic support log ready to share"
        supportLogFileName = fileURL.lastPathComponent
    }

    func clearSharedItems() {
        shareItems.removeAll()
        isSharePresented = false
    }

    private func activateBasicSupportLog() throws {
        let fileURL = try ensureSupportLogFileURL(for: .basic)
        try activateSupportLog(mode: .basic, fileURL: fileURL)
    }

    private func activateSupportLog(
        mode: Vigram.Logger.Mode,
        fileURL: URL
    ) throws {
        _ = try Vigram.Logger(url: fileURL, mode: mode)
        currentSupportLogFileURL = fileURL
        refreshSupportLogStatus()
    }

    private func ensureSupportLogFileURL(for kind: SupportLogFileKind) throws -> URL {
        switch kind {
        case .basic:
            if let currentBasicSupportLogFileURL {
                return currentBasicSupportLogFileURL
            }
        case .diagnostic:
            if let currentDiagnosticSupportLogFileURL {
                return currentDiagnosticSupportLogFileURL
            }
        }

        guard let baseFileURL = try FileWorker.createFile(
            fileExtension: "jsonl",
            folder: "SupportLog/\(kind.fileNameComponent)"
        ) else {
            throw SupportLogExportError.couldNotCreateOutputFile
        }

        let fileURL = baseFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(kind.logFileName)

        switch kind {
        case .basic:
            currentBasicSupportLogFileURL = fileURL
        case .diagnostic:
            currentDiagnosticSupportLogFileURL = fileURL
        }

        return fileURL
    }

    private func refreshSupportLogStatus() {
        if diagnosticLogMode == .on {
            currentSupportLogFileURL = currentDiagnosticSupportLogFileURL
            supportLogStatus = "Diagnostic support log is active"
            supportLogFileName = currentDiagnosticSupportLogFileURL?.lastPathComponent ?? "No file"
        } else {
            currentSupportLogFileURL = currentBasicSupportLogFileURL
            supportLogStatus = "Basic support log is active"
            supportLogFileName = currentBasicSupportLogFileURL?.lastPathComponent ?? "No file"
        }
    }

    private func presentAlert(title: String, message: String) {
        alertPresenter?(title, message)
    }
}

enum DiagnosticLogModeOption: String, CaseIterable, Identifiable {
    case off
    case on

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .on:
            return "On"
        }
    }
}

private enum SupportLogFileKind {
    case basic
    case diagnostic

    var fileNameComponent: String {
        switch self {
        case .basic:
            return "basic"
        case .diagnostic:
            return "diagnostic"
        }
    }

    var logFileName: String {
        "\(fileNameComponent)_\(Date().getCurrentDateToString()).jsonl"
    }
}

private enum SupportLogExportError: LocalizedError {
    case couldNotCreateOutputFile
    case fileIsNotAvailable

    var errorDescription: String? {
        switch self {
        case .couldNotCreateOutputFile:
            return "Could not create the support log file."
        case .fileIsNotAvailable:
            return "Support log file is not available yet."
        }
    }
}
