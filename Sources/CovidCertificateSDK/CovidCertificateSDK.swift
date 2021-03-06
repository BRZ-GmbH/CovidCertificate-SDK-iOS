//
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
import ValidationCore
import class CertLogic.ValueSet

private var instance: ChCovidCert!

public enum CovidCertificateSDK {
    /// The current version of the SDK
    public static let frameworkVersion: String = "1.0.0"

    public static func initialize(environment: SDKEnvironment, apiKey: String) {
        precondition(instance == nil, "CovidCertificateSDK already initialized")
        instance = ChCovidCert(environment: environment, apiKey: apiKey)
    }

    public static func decode(encodedData: String) -> Result<DGCHolder, CovidCertError> {
        instancePrecondition()
        return instance.decode(encodedData: encodedData)
    }

    @available(OSX 10.13, *)
    public static func decodeAndCheckSignature(encodedData: String, validationClock: Date, _ completionHandler: @escaping (Result<ValidationResult, ValidationError>) -> Void) {
        instancePrecondition()
        return instance.decodeAndCheckSignature(encodedData: encodedData, validationClock: validationClock, completionHandler)
    }

    public static func checkNationalRules(dgc: HealthCert, realTime: Date, validationClock: Date, issuedAt: Date, expiresAt: Date, countryCode: String = "AT", region: String? = nil, forceUpdate: Bool, _ completionHandler: @escaping (Result<VerificationResult, ValidationError>) -> Void) {
        instancePrecondition()
        return instance.checkNationalRules(dgc: dgc, realTime: realTime, validationClock: validationClock, issuedAt: issuedAt, expiresAt: expiresAt, countryCode: countryCode, region: region, forceUpdate: forceUpdate, completionHandler)
    }

    public static func restartTrustListUpdate(force: Bool, completionHandler: @escaping (Bool, Bool) -> Void) {
        instancePrecondition()
        instance.restartTrustListUpdate(force: force, completionHandler: completionHandler)
    }

    private static func instancePrecondition() {
        precondition(instance != nil, "CovidCertificateSDK not initialized, call `initialize()`")
    }

    public static var currentEnvironment: SDKEnvironment {
        instancePrecondition()
        return instance.environment
    }

    public static var apiKey: String {
        instancePrecondition()
        return instance.apiKey
    }
    
    public static func currentValueSets() -> [String:ValueSet] {
        return instance.currentValueSets()
    }
}
