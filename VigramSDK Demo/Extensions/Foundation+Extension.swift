//
//  Foundation+Extension.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 13.12.2023.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import Foundation

extension Data {
    func hexStringWithSpace(uppercase: Bool = true) -> String {
        let format = uppercase ? "%02hhX " : "%02hhx "
        return map { String(format: format, $0) }.joined()
    }

    func hexString(uppercase: Bool = true) -> String {
        let format = uppercase ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension Date {
    func getCurrentDateToString() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        let second = calendar.component(.second, from: self)
        let dayString = "\(day)."
        let monthString = month < 10 ? "0\(month)." : "\(month)."
        let yearString = "\(year)-"
        let hourString = hour < 10 ? "0\(hour):" : "\(hour):"
        let minuteString = minute < 10 ? "0\(minute):" : "\(minute):"
        let secondString = second < 10 ? "0\(second)" : "\(second)"

        return dayString + monthString + yearString + hourString + minuteString + secondString
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
