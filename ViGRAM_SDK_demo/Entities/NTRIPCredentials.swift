//
//  NTRIPCredentials.swift
//  ViGRAM_SDK_demo
//
//  Created by Aleksei Sablin on 14.12.2023.
//  Copyright © 2020 Vigram. All rights reserved.
//

import Foundation

struct NtripCredentials: Codable, Equatable, Hashable {
    var host: String
    var port: Int
    var login: String
    var pass: String
    var mountpoint: String
    var forceHTTPSconnection: Bool
    var forceHTTPSMountpointsConnection: Bool

    init(
        host: String,
        port: Int,
        login: String,
        pass: String,
        mountpoint: String,
        forceHTTPSconnection: Bool = false,
        forceHTTPSMountpointsConnection: Bool = false
    ) {
        self.host = host
        self.port = port
        self.login = login
        self.pass = pass
        self.mountpoint = mountpoint
        self.forceHTTPSconnection = forceHTTPSconnection
        self.forceHTTPSMountpointsConnection = forceHTTPSMountpointsConnection
    }

    private enum CodingKeys: String, CodingKey {
        case host
        case port
        case login
        case pass
        case mountpoint
        case forceHTTPSconnection
        case forceHTTPSMountpointsConnection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        login = try container.decode(String.self, forKey: .login)
        pass = try container.decode(String.self, forKey: .pass)
        mountpoint = try container.decode(String.self, forKey: .mountpoint)
        let legacySharedHTTPSFlag = try container.decodeIfPresent(Bool.self, forKey: .forceHTTPSconnection) ?? false
        forceHTTPSconnection = legacySharedHTTPSFlag
        forceHTTPSMountpointsConnection =
            try container.decodeIfPresent(Bool.self, forKey: .forceHTTPSMountpointsConnection)
            ?? legacySharedHTTPSFlag
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(login, forKey: .login)
        try container.encode(pass, forKey: .pass)
        try container.encode(mountpoint, forKey: .mountpoint)
        try container.encode(forceHTTPSconnection, forKey: .forceHTTPSconnection)
        try container.encode(forceHTTPSMountpointsConnection, forKey: .forceHTTPSMountpointsConnection)
    }
}
