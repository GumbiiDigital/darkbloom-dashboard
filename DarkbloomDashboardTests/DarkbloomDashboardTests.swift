//
//  Darkbloom_DashboardTests.swift
//  Darkbloom DashboardTests
//
//  Created by Marco Quinten on 5/30/26.
//

import Foundation
import Testing
@testable import DarkbloomDashboard

@MainActor
struct Darkbloom_DashboardTests {

    @Test func trustedMachineHasNoTrustRepairActions() async throws {
        let trust = MachineTrustInfo.trustedFixture()

        #expect(trust.reducedTrustReasons.isEmpty)
    }

    @Test func reducedTrustReasonsExplainFailingTrustChecks() async throws {
        let trust = MachineTrustInfo.trustedFixture(
            status: .untrusted,
            trustLevel: .selfSigned,
            attested: false,
            authenticatedRootEnabled: false,
            mdaVerified: false,
            mdmVerified: false,
            runtimeVerified: false
        )

        #expect(trust.reducedTrustReasons.map(\.title) == [
            "Provider is untrusted",
            "Hardware trust is missing",
            "Attestation is stale",
            "MDA is not verified",
            "MDM is not verified",
            "Authenticated Root is disabled",
            "Runtime verification failed"
        ])
    }

    #if os(macOS)
    @Test func remoteRestartTargetCanRoundTripThroughJson() async throws {
        let target = MachineRestartTarget(
            serialNumber: "SERIAL123",
            user: "provider",
            host: "lab-mac.tailnet.example"
        )

        let data = try JSONEncoder().encode(["SERIAL123": target])
        let decoded = try JSONDecoder().decode([String: MachineRestartTarget].self, from: data)

        #expect(decoded["SERIAL123"] == target)
    }

    @Test func remoteRestartArgumentsUseBatchModeSsh() async throws {
        let target = MachineRestartTarget(
            serialNumber: "SERIAL123",
            user: "provider",
            host: "lab-mac.tailnet.example"
        )

        #expect(target.sshRestartArguments == [
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=10",
            "-o", "StrictHostKeyChecking=accept-new",
            "provider@lab-mac.tailnet.example",
            "~/.darkbloom/bin/darkbloom stop; sleep 2; ~/.darkbloom/bin/darkbloom start --all"
        ])
    }
    #endif
}

private extension MachineTrustInfo {
    static func trustedFixture(
        status: DarkbloomProviderStatus = .serving,
        trustLevel: DarkbloomProviderTrustLevel = .hardware,
        attested: Bool = true,
        acmeVerified: Bool = true,
        authenticatedRootEnabled: Bool = true,
        mdaSerial: String? = "fixture-mda",
        mdaVerified: Bool = true,
        mdmVerified: Bool = true,
        secureBootEnabled: Bool = true,
        secureEnclave: Bool = true,
        sipEnabled: Bool = true,
        runtimeVerified: Bool = true
    ) -> MachineTrustInfo {
        MachineTrustInfo(
            status: status,
            trustLevel: trustLevel,
            attested: attested,
            acmeVerified: acmeVerified,
            authenticatedRootEnabled: authenticatedRootEnabled,
            mdaSerial: mdaSerial,
            mdaVerified: mdaVerified,
            mdmVerified: mdmVerified,
            secureBootEnabled: secureBootEnabled,
            secureEnclave: secureEnclave,
            sipEnabled: sipEnabled,
            runtimeVerified: runtimeVerified
        )
    }
}
