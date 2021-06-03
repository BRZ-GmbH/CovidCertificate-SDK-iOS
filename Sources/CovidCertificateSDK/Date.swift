/*
 * Copyright (c) 2021 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

extension Date {
    static func fromISO8601(_ dateString:String) -> Date? {
        // `ISO8601DateFormatter` does not support fractional zeros if not
        // configured (`.withFractionalSeconds`) and if configured, does not
        // parse dates without fractional seconds.

        let formatter = ISO8601DateFormatter()

        // Try to parse without fractional seconds
        if let d = formatter.date(from: dateString) {
            return d
        }

        // Retry with fraction
        formatter.formatOptions = [.withFractionalSeconds]
        if let d = formatter.date(from: dateString) {
            return d
        }

        return nil
    }
}