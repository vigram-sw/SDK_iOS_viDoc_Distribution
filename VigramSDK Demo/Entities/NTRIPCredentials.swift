//
//  NTRIPCredentials.swift
//  VigramSDK Demo
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
}
