//
//  FileWorker.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 13.12.23.
//  Copyright © 2020 Vigram. All rights reserved.
//

import Foundation

public enum FileWorkerError: Swift.Error {
    case directoryIsNotExist
    case fileIsNotFound
}

extension FileWorkerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .directoryIsNotExist:
            return NSLocalizedString("Directory is not found", comment: "FileWorkerError")
        case .fileIsNotFound:
            return NSLocalizedString("File for this directory is not found", comment: "FileWorkerError")
        }
    }
}

class FileWorker {
    static func createFile(name: String, fileExtension: String, folder: String) throws -> URL?{
        var path: URL?
        let file = Date().getCurrentDateToString() + "." + fileExtension

        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        if directory.count != 0  {
            path = directory[0].appendingPathComponent(folder)
            path = path?.appendingPathComponent(name)
            if let path = path?.path {
                if !FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                }
            }
            path = path?.appendingPathComponent(file)
        }
        return path
    }
    
    static func createFile(fileExtension: String, folder: String) throws -> URL?{
        var path: URL?
        let file = Date().getCurrentDateToString() + "." + fileExtension

        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        if directory.count != 0  {
            path = directory[0].appendingPathComponent(folder)
            if let path = path?.path {
                if !FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                }
            }
            path = path?.appendingPathComponent(file)
        }
        return path
    }

    static func create(folder: String) throws {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent(folder)
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    static func checkIsExist(folder: String) -> Result<URL, Error>{
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = directory[0].appendingPathComponent(folder)

        return FileManager.default.fileExists(atPath: path.path) ? .success(path) : .failure(FileWorkerError.directoryIsNotExist)
    }
    
    static func checkIsExist(file: URL) -> Bool {
        FileManager.default.fileExists(atPath: file.path)
    }

    static func getListOfItemsFor(path: URL) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path.path)
    }
    
    static func getFileFor(folder: String, fileName: String) throws -> Result<Data, Error> {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard directory.count != 0 else {
            return .failure(FileWorkerError.directoryIsNotExist)
        }

        var path = directory[0].appendingPathComponent(folder)
        path = path.appendingPathComponent(fileName)
        if let linkOfFile = FileManager.default.fileExists(atPath: path.path) ? path : nil {
            do {
                let data = try Data(contentsOf: linkOfFile)
                return .success(data)
            } catch {
                return .failure(error)
            }
        } else {
            return .failure(FileWorkerError.fileIsNotFound)
        }
    }
}
