//
//  PreyConfigBiometricTests.swift
//  PreyTests
//
//  Created on 2026-04-08.
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

@testable import Prey
import XCTest

class PreyConfigBiometricTests: XCTestCase {

    // MARK: - Feature Flag Tests

    func testBiometricAuthFeatureFlagIsDisabled() {
        XCTAssertFalse(PreyConfig.isBiometricAuthEnabled,
                       "Biometric auth feature flag should be disabled")
    }

    // MARK: - isTouchIDEnabled Interaction Tests

    func testTouchIDEnabledDoesNotOverrideFeatureFlag() {
        let original = PreyConfig.sharedInstance.isTouchIDEnabled

        PreyConfig.sharedInstance.isTouchIDEnabled = true

        // Even with isTouchIDEnabled = true, the feature flag remains off
        XCTAssertFalse(PreyConfig.isBiometricAuthEnabled,
                       "Feature flag should remain disabled regardless of isTouchIDEnabled")

        PreyConfig.sharedInstance.isTouchIDEnabled = original
    }

    func testBiometricAuthGuardBlocksWhenFlagDisabled() {
        PreyConfig.sharedInstance.isTouchIDEnabled = true

        // Simulates the guard condition used in authenticateWithBiometrics
        let shouldProceed = PreyConfig.isBiometricAuthEnabled && PreyConfig.sharedInstance.isTouchIDEnabled
        XCTAssertFalse(shouldProceed,
                       "Biometric auth should be blocked when feature flag is disabled")
    }
}
