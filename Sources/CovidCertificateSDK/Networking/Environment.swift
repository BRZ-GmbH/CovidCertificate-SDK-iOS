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

public enum SDKEnvironment {
    case dev
    case abn
    case prod

    var trustBackend: Backend {
        switch self {
        case .dev:
            return Backend("", version: "v1")
        case .abn:
            return Backend("", version: "v1")
        case .prod:
            return Backend("", version: "v1")
        }
    }

    public static let applicationJwtPlusJws: String = "application/json+jws"

    var revocationListService: Endpoint {
        return trustBackend.endpoint("revocationList", headers: ["Accept": SDKEnvironment.applicationJwtPlusJws])
    }

    var nationalRulesListService: Endpoint {
        return trustBackend.endpoint("verificationRules", headers: ["Accept": SDKEnvironment.applicationJwtPlusJws])
    }

    func trustCertificatesService(since: String) -> Endpoint {
        return trustBackend.endpoint("keys/updates", queryParameters: ["certFormat": "IOS", "since": since], headers: ["Accept": SDKEnvironment.applicationJwtPlusJws])
    }

    var activeCertificatesService: Endpoint {
        return trustBackend.endpoint("keys/list", headers: ["Accept": SDKEnvironment.applicationJwtPlusJws])
    }
}
