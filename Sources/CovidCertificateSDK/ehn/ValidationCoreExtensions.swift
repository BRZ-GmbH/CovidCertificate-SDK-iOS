//
//  File.swift
//
//
//  Created by Martin Fitzka-Reichart on 12.07.21.
//

import Foundation
import SwiftCBOR
import ValidationCore

extension Optional where Wrapped: Collection {
    /// Check if this optional array is nil or empty
    func isNilOrEmpty() -> Bool {
        // if self is nil `self?.isEmpty` is nil and hence the value after the ?? operator is used
        // otherwise self!.isEmpty checks for an empty array
        return self?.isEmpty ?? true
    }
}

extension EuHealthCert {
    func certIdentifiers() -> [String] {
        switch type {
        case .vaccination:
            return vaccinations!.map { vac in
                vac.certificateIdentifier
            }
        case .recovery:
            return recovery!.map { rec in
                rec.certificateIdentifier
            }
        case .test:
            return tests!.map { test in
                test.certificateIdentifier
            }
        }
    }
}

public extension Vaccination {
    var isTargetDiseaseCorrect: Bool {
        return disease == Disease.SarsCov2.rawValue
    }

    /// we need a date of vaccination which needs to be in the format of yyyy-MM-dd
    internal var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        return dateFormatter
    }

    var dateOfVaccination: Date? {
        return dateFormatter.date(from: vaccinationDate)
    }

    /// A vaccine which originally had a total dosis number of 2 and now is marked as 1 means that the person who got the shot was previously infected, hence has full protection with just one shot
    var hadPastInfection: Bool {
        guard let totalDoses = AcceptedProducts.shared.totalNumberOfDoses(vaccination: self) else {
            return false
        }
        return totalDoses > self.totalDoses
    }

    var validFromDate: Date? {
        guard let dateOfVaccination = self.dateOfVaccination,
              let totalDoses = AcceptedProducts.shared.totalNumberOfDoses(vaccination: self)
        else {
            return nil
        }

        // if this is a vaccine, which only needs one shot AND we had no previous infections, the vaccine is valid 15 days after the date of vaccination
        if !hadPastInfection,
           totalDoses == 1 {
            return Calendar.current.date(byAdding: DateComponents(day: 15), to: dateOfVaccination)
        } else {
            // in any other case the vaccine is valid from the date of vaccination
            return dateOfVaccination
        }
    }

    func getValidFromDate(daysAfterFirstShot: Int) -> Date? {
        guard let dateOfVaccination = self.dateOfVaccination,
              let totalDoses = AcceptedProducts.shared.totalNumberOfDoses(vaccination: self)
        else {
            return nil
        }

        // if this is a vaccine, which only needs one shot AND we had no previous infections, the vaccine is valid 15 days after the date of vaccination
        if !hadPastInfection,
           totalDoses == 1 {
            return Calendar.current.date(byAdding: DateComponents(day: daysAfterFirstShot), to: dateOfVaccination)
        } else {
            // in any other case the vaccine is valid from the date of vaccination
            return dateOfVaccination
        }
    }

    /// Vaccines are valid for 180 days
    var validUntilDate: Date? {
        guard let dateOfVaccination = self.dateOfVaccination,
              let date = Calendar.current.date(byAdding: DateComponents(day: MAXIMUM_VALIDITY_IN_DAYS), to: dateOfVaccination) else {
            return nil
        }
        return date
    }

    func getValidUntilDate(maximumValidityInDays: Int) -> Date? {
        guard let dateOfVaccination = self.dateOfVaccination,
              let date = Calendar.current.date(byAdding: DateComponents(day: maximumValidityInDays), to: dateOfVaccination) else {
            return nil
        }
        return date
    }

    var name: String? {
        return ProductNameManager.shared.vaccineProductName(key: medicinialProduct)
    }

    var authHolder: String? {
        return ProductNameManager.shared.vaccineManufacturer(key: marketingAuthorizationHolder)
    }

    var prophylaxis: String? {
        return ProductNameManager.shared.vaccineProphylaxisName(key: vaccine)
    }
}

public extension Test {
    var isPcrTest: Bool {
        return type == TestType.Pcr.rawValue
    }

    var isRatTest: Bool {
        return type == TestType.Rat.rawValue
    }

    var validFromDate: Date? {
        return Date.fromISO8601(timestampSample)
    }

    var resultDate: Date? {
        if let res = timestampResult {
            return Date.fromISO8601(res)
        }

        return nil
    }

    /// PCR tests are valid for 72h after sample collection. RAT tests are valid for 24h and have an optional validfrom. We just never set it
    var validUntilDate: Date? {
        guard let startDate = validFromDate else { return nil }

        switch type {
        case TestType.Pcr.rawValue:
            return Calendar.current.date(byAdding: DateComponents(hour: PCR_TEST_VALIDITY_IN_HOURS), to: startDate)
        case TestType.Rat.rawValue:
            return Calendar.current.date(byAdding: DateComponents(hour: RAT_TEST_VALIDITY_IN_HOURS), to: startDate)
        default:
            return nil
        }
    }

    func getValidUntilDate(pcrTestValidityInHours: Int, ratTestValidityInHours: Int) -> Date? {
        guard let startDate = validFromDate else { return nil }
        switch type {
        case TestType.Pcr.rawValue:
            return Calendar.current.date(byAdding: DateComponents(hour: pcrTestValidityInHours), to: startDate)
        case TestType.Rat.rawValue:
            return Calendar.current.date(byAdding: DateComponents(hour: ratTestValidityInHours), to: startDate)
        default:
            return nil
        }
    }

    var isTargetDiseaseCorrect: Bool {
        return disease == Disease.SarsCov2.rawValue
    }

    var isNegative: Bool {
        return result == TestResult.Negative.rawValue
    }

    var testType: String? {
        return ProductNameManager.shared.testTypeName(key: type)
    }

    var readableTestName: String? {
        switch type {
        case TestType.Pcr.rawValue:
            return testName ?? "PCR"
        case TestType.Rat.rawValue:
            return testName
        default:
            return nil
        }
    }

    var readableManufacturer: String? {
        if let val = ProductNameManager.shared.testManufacturerName(key: manufacturer) {
            var r = val.replacingOccurrences(of: testName ?? "", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            if let last = r.last, last == "," {
                r.removeLast()
            }

            return r.isEmpty ? nil : r
        }

        return nil
    }
}

public extension Recovery {
    internal var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT
        return dateFormatter
    }

    var firstPositiveTestResultDate: Date? {
        return dateFormatter.date(from: dateFirstPositiveTest)
    }

    var validFromDate: Date? {
        guard let firstPositiveTestResultDate = self.firstPositiveTestResultDate,
              let date = Calendar.current.date(byAdding: DateComponents(day: INFECTION_VALIDITY_OFFSET_IN_DAYS), to: firstPositiveTestResultDate) else {
            return nil
        }
        return date
    }

    var validUntilDate: Date? {
        guard let firstPositiveTestResultDate = self.firstPositiveTestResultDate,
              let date = Calendar.current.date(byAdding: DateComponents(day: MAXIMUM_VALIDITY_IN_DAYS), to: firstPositiveTestResultDate) else {
            return nil
        }
        return date
    }

    var isTargetDiseaseCorrect: Bool {
        return disease == Disease.SarsCov2.rawValue
    }
}
