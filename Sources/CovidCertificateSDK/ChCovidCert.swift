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

import base45_swift
import Foundation
import Gzip
import JSON
import ValidationCore
import class CertLogic.ValueSet

public enum CovidCertError: Error, Equatable {
    case NOT_IMPLEMENTED
    case INVALID_SCHEME_PREFIX
    case BASE_45_DECODING_FAILED
    case DECOMPRESSION_FAILED
    case COSE_DESERIALIZATION_FAILED
    case HCERT_IS_INVALID

    public var errorCode: String {
        switch self {
        case .NOT_IMPLEMENTED:
            return "D|NI"
        case .INVALID_SCHEME_PREFIX:
            return "D|ISP"
        case .BASE_45_DECODING_FAILED:
            return "D|B45"
        case .DECOMPRESSION_FAILED:
            return "D|ZLB"
        case .COSE_DESERIALIZATION_FAILED:
            return "D|CDF"
        case .HCERT_IS_INVALID:
            return "D|HII"
        }
    }
}

public struct DGCHolder {
    public var healthCert: EuHealthCert {
        return cwt.euHealthCert!
    }

    public var issuedAt: Date? {
        return cwt.issuedAt
    }

    public var expiresAt: Date? {
        return cwt.expiresAt
    }

    public let encodedData: String
    let cwt: CWT

    init(encodedData: String, cwt: CWT) {
        self.encodedData = encodedData
        self.cwt = cwt
    }
}

extension ValidationError {
    func asCovidCertError() -> CovidCertError {
        switch self {
        case .INVALID_SCHEME_PREFIX: return .INVALID_SCHEME_PREFIX
        case .BASE_45_DECODING_FAILED: return .BASE_45_DECODING_FAILED
        case .DECOMPRESSION_FAILED: return .DECOMPRESSION_FAILED
        case .COSE_DESERIALIZATION_FAILED: return .COSE_DESERIALIZATION_FAILED
        case .CBOR_DESERIALIZATION_FAILED: return .COSE_DESERIALIZATION_FAILED
        default: return .COSE_DESERIALIZATION_FAILED
        }
    }
}

public struct ChCovidCert {
    private let validationCore: ValidationCore

    public let environment: SDKEnvironment
    public let apiKey: String

    init(environment: SDKEnvironment, apiKey: String) {
        self.environment = environment
        self.apiKey = apiKey
        validationCore = ValidationCore(trustlistUrl: environment.trustlistUrl,
                                        signatureUrl: environment.trustlistSignatureUrl,
                                        trustAnchor: environment.trustlistAnchor,
                                        businessRulesUrl: environment.businessRulesUrl,
                                        businessRulesSignatureUrl: environment.businessRulesSignatureUrl,
                                        businessRulesTrustAnchor: environment.trustlistAnchor,
                                        valueSetsUrl: environment.valueSetsUrl,
                                        valueSetsSignatureUrl: environment.valueSetsSignatureUrl,
                                        valueSetsTrustAnchor: environment.trustlistAnchor,
                                        apiToken: apiKey)
    }

    public func decode(encodedData: String) -> Swift.Result<DGCHolder, CovidCertError> {
        #if DEBUG
            print(encodedData)
        #endif

        let decodingResult = validationCore.decodeCwt(encodedData: encodedData)

        switch decodingResult {
        case let .failure(error):
            return .failure(error.asCovidCertError())
        case let .success(result):
            return .success(DGCHolder(encodedData: encodedData, cwt: result))
        }
    }

    public func decodeAndCheckSignature(encodedData: String, validationClock: Date, _ completionHandler: @escaping (Swift.Result<ValidationResult, ValidationError>) -> Void) {
        validationCore.validate(encodedData: encodedData, validationClock: validationClock) { result in
            if result.isValid {
                completionHandler(.success(result))
            } else {
                completionHandler(.failure(result.error ?? .GENERAL_ERROR))
            }
        }
    }

    public func checkNationalRules(dgc: EuHealthCert, realTime: Date, validationClock: Date, issuedAt: Date, expiresAt: Date, countryCode: String, region: String?, forceUpdate _: Bool, _ completionHandler: @escaping (Swift.Result<VerificationResult, ValidationError>) -> Void) {
        validationCore.validateBusinessRules(forCertificate: dgc, realTime: realTime, validationClock: validationClock, issuedAt: issuedAt, expiresAt: expiresAt, countryCode: countryCode, region: region) { result, validUntilDate, error in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                let failedRules = result.filter { $0.result == .fail }
                if failedRules.isEmpty {
                    switch dgc.type {
                    case .recovery:
                        completionHandler(.success(VerificationResult(isValid: true, validUntil: validUntilDate, validFrom: nil)))
                    case .vaccination:
                        completionHandler(.success(VerificationResult(isValid: true, validUntil: validUntilDate, validFrom: nil)))
                    case .test:
                        completionHandler(.success(VerificationResult(isValid: true, validUntil: validUntilDate, validFrom: nil)))
                    }
                    return
                } else {
                    switch dgc.type {
                    case .recovery:
                        completionHandler(.success(VerificationResult(isValid: failedRules.isEmpty, validUntil: validUntilDate, validFrom: nil)))
                    case .vaccination:
                        completionHandler(.success(VerificationResult(isValid: false, validUntil: validUntilDate, validFrom: nil)))
                    case .test:
                        completionHandler(.success(VerificationResult(isValid: false, validUntil: validUntilDate, validFrom: nil)))
                    }
                }
            }
        }
    }

    public func restartTrustListUpdate(force: Bool, completionHandler: @escaping (Bool, Bool) -> Void) {
        validationCore.updateTrustlistAndRules(force: force) { wasUpdated, error in
            DispatchQueue.main.async {
                completionHandler(wasUpdated, error != nil)
            }            
        }
    }

    func allRecoveriesAreValid(recoveries _: [Recovery]) -> Bool {
        return false
    }
    
    func currentValueSets() -> [String:ValueSet] {
        return validationCore.getCurrentValueSets()
    }
}
