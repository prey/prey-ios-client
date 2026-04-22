//
//  QRCodeScannerVCTests.swift
//  PreyTests
//
//  Copyright © 2026 Prey, Inc. All rights reserved.
//

import AVFoundation
@testable import Prey
import XCTest

/// Tests covering the camera-access policy used by QRCodeScannerVC.
///
/// The goal is to guarantee that iOS's camera prompt is shown ONLY when the
/// user is on the QR scanner and the authorization is `.notDetermined`. Any
/// other status must resolve synchronously without triggering `requestAccess`.
class QRCodeScannerVCTests: XCTestCase {
    func testDecisionAuthorizedGrants() {
        XCTAssertEqual(
            QRCodeScannerVC.cameraAccessDecision(for: .authorized),
            .grant,
            "An already-authorized status must proceed without any prompt"
        )
    }

    func testDecisionNotDeterminedPrompts() {
        XCTAssertEqual(
            QRCodeScannerVC.cameraAccessDecision(for: .notDetermined),
            .prompt,
            ".notDetermined is the only status that should trigger the system prompt"
        )
    }

    func testDecisionDeniedRejects() {
        XCTAssertEqual(
            QRCodeScannerVC.cameraAccessDecision(for: .denied),
            .deny,
            "A previously denied status must not prompt again — iOS no longer shows the system dialog"
        )
    }

    func testDecisionRestrictedRejects() {
        XCTAssertEqual(
            QRCodeScannerVC.cameraAccessDecision(for: .restricted),
            .deny,
            "Restricted (e.g., parental controls) must be treated as denied, not prompted"
        )
    }

    func testOnlyNotDeterminedTriggersPrompt() {
        // Sanity check that of all the real statuses, exactly one routes to .prompt.
        let statuses: [AVAuthorizationStatus] = [.authorized, .notDetermined, .denied, .restricted]
        let promptingStatuses = statuses.filter {
            QRCodeScannerVC.cameraAccessDecision(for: $0) == .prompt
        }
        XCTAssertEqual(
            promptingStatuses,
            [.notDetermined],
            "The camera prompt must fire only for .notDetermined"
        )
    }

    // MARK: - Architectural invariant

    /// Static-analysis test: the only place in the codebase allowed to call
    /// `AVCaptureDevice.requestAccess` is the QR scanner. If someone adds a
    /// camera-permission prompt anywhere else (e.g., in DeviceAuth or a future
    /// feature) this test fails, keeping the "only prompt on QR" guarantee honest.
    func testRequestAccessIsOnlyCalledFromQRScanner() throws {
        let classesURL = try classesSourceDirectory()
        let offenders = try swiftFiles(in: classesURL).filter { fileURL in
            let source = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
            return source.contains("AVCaptureDevice.requestAccess")
        }

        let offenderNames = offenders.map { $0.lastPathComponent }.sorted()
        XCTAssertEqual(
            offenderNames,
            ["QRCodeScannerVC.swift"],
            "AVCaptureDevice.requestAccess must only appear in QRCodeScannerVC.swift. Found in: \(offenderNames)"
        )
    }

    // MARK: - Helpers

    /// Resolves `Prey/Classes/` from the location of this test file (`#file`).
    /// Walks up from `PreyTests/QRCodeScannerVCTests.swift` to the repo root.
    private func classesSourceDirectory(file: StaticString = #file) throws -> URL {
        let testFileURL = URL(fileURLWithPath: "\(file)")
        let repoRoot = testFileURL
            .deletingLastPathComponent() // PreyTests/
            .deletingLastPathComponent() // repo root
        let classesURL = repoRoot
            .appendingPathComponent("Prey")
            .appendingPathComponent("Classes")

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: classesURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw XCTSkip("Source directory not reachable from test bundle: \(classesURL.path)")
        }
        return classesURL
    }

    private func swiftFiles(in directory: URL) throws -> [URL] {
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        var results: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "swift" {
                results.append(url)
            }
        }
        return results
    }
}
