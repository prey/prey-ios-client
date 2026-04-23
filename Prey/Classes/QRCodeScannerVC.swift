//
//  QRCodeScannerVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 19/07/16.
//  Copyright © 2016 Prey, Inc. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

class QRCodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    // MARK: Properties

    let device: AVCaptureDevice! = AVCaptureDevice.default(for: AVMediaType.video)
    let session: AVCaptureSession = .init()
    let output: AVCaptureMetadataOutput = .init()

    var preview: AVCaptureVideoPreviewLayer!

    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()

        // View title for GAnalytics
        // self.screenName = "QRCodeScanner"

        // Set background color
        view.backgroundColor = UIColor.black

        // Config navigationBar
        let widthScreen = UIScreen.main.bounds.size.width
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: widthScreen, height: 44))
        navBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.addSubview(navBar)

        // Config navItem
        let navItem = UINavigationItem(title: "")
        navItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navBar.pushItem(navItem, animated: false)

        // Check camera available
        guard isCameraAvailable() else {
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage: "Error camera isn't available".localized)
            return
        }

        // Camera permission is requested here (and only here) so the user
        // sees the prompt on the QR scan screen instead of on app launch.
        requestCameraAccessIfNeeded { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.showCameraDeniedAlert()
                return
            }
            self.configureSession()
        }
    }

    /// Decision for the camera access flow, given an authorization status.
    /// Kept as a pure function so it can be unit-tested without touching AVFoundation.
    enum CameraAccessDecision: Equatable {
        case grant
        case prompt
        case deny
    }

    static func cameraAccessDecision(for status: AVAuthorizationStatus) -> CameraAccessDecision {
        switch status {
        case .authorized:
            return .grant
        case .notDetermined:
            return .prompt
        case .denied, .restricted:
            return .deny
        @unknown default:
            return .deny
        }
    }

    /// Request camera access if the status is notDetermined; otherwise resolve immediately.
    private func requestCameraAccessIfNeeded(completion: @escaping (Bool) -> Void) {
        switch QRCodeScannerVC.cameraAccessDecision(for: AVCaptureDevice.authorizationStatus(for: .video)) {
        case .grant:
            completion(true)
        case .prompt:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .deny:
            completion(false)
        }
    }

    private func showCameraDeniedAlert() {
        let alert = UIAlertController(
            title: "Enable Camera".localized,
            message: "Prey uses the device's camera only to scan the QR code and add the device.".localized,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to Settings".localized, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            self.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func configureSession() {
        do {
            let inputDevice: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: device)
            setupScanner(inputDevice)
            startScanning()
        } catch let error as NSError {
            PreyLogger("QrCode error: \(error.localizedDescription)")
            displayErrorAlert("Couldn't add your device".localized,
                              titleMessage: "The scanned QR code is invalid".localized)
        }
    }

    // MARK: Methods

    /// Setup scanner
    func setupScanner(_ input: AVCaptureDeviceInput) {
        // Config session
        session.addOutput(output)
        session.addInput(input)

        // Config output
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

        // Config preview
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravity.resizeAspectFill
        preview.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        preview.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(preview, at: 0)

        // Config label
        let screen = UIScreen.main.bounds.size
        let widthLbl = screen.width
        let fontSize: CGFloat = IS_IPAD ? 16.0 : 12.0
        let message = IS_IPAD ? "Visit panel.preyproject.com/qr on your computer and scan the QR code".localized :
            "Visit panel.preyproject.com/qr \non your computer and scan the QR code".localized

        let infoQR = UILabel(frame: CGRect(x: 0, y: screen.height - 50, width: widthLbl, height: 50))
        infoQR.textColor = UIColor(red: 0.3019, green: 0.3411, blue: 0.4, alpha: 0.7)
        infoQR.backgroundColor = UIColor.white
        infoQR.textAlignment = .center
        infoQR.font = UIFont(name: fontTitilliumRegular, size: fontSize)
        infoQR.text = message
        infoQR.numberOfLines = 2
        infoQR.adjustsFontSizeToFitWidth = true
        view.addSubview(infoQR)

        // Config QrZone image
        let qrZoneSize = IS_IPAD ? screen.width * 0.6 : screen.width * 0.78
        let qrZonePosY = (screen.height - qrZoneSize) / 2
        let qrZonePosX = (screen.width - qrZoneSize) / 2
        let qrZoneImg = UIImageView(image: UIImage(named: "QrZone"))
        qrZoneImg.frame = CGRect(x: qrZonePosX, y: qrZonePosY, width: qrZoneSize, height: qrZoneSize)
        view.addSubview(qrZoneImg)
    }

    /// Success scan
    func successfullyScan(_ scannedValue: NSString) {
        let validQr = "prey?api_key=" as NSString
        let checkQr: NSString = (scannedValue.length > validQr.length) ? scannedValue.substring(to: validQr.length) as NSString : "" as NSString
        let apikeyQr: NSString = (scannedValue.length > validQr.length) ? scannedValue.substring(from: validQr.length) as NSString : "" as NSString

        stopScanning()

        dismiss(animated: true, completion: { () in
            if checkQr.isEqual(to: validQr as String) {
                PreyDeployment.sharedInstance.addDeviceWith(apikeyQr as String, fromQRCode: true)
            } else {
                displayErrorAlert("The scanned QR code is invalid".localized,
                                  titleMessage: "Couldn't add your device".localized)
            }
        })
    }

    func startScanning() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }

    func stopScanning() {
        session.stopRunning()
    }

    func isCameraAvailable() -> Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        return !discoverySession.devices.isEmpty
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    /// CaptureOutput
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        for current in metadataObjects {
            if current is AVMetadataMachineReadableCodeObject {
                if let scannedValue = (current as! AVMetadataMachineReadableCodeObject).stringValue {
                    successfullyScan(scannedValue as NSString)
                }
            }
        }
    }
}
