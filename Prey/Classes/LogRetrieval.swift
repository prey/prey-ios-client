//
//  LogRetrieval.swift
//  Prey
//
//  Created by Codex on 2025-09-01.
//

import Foundation

class LogRetrieval: PreyAction, @unchecked Sendable {

    // MARK: Commands

    // Some panels may send `get`; treat it like `start`
    override func get() {
        start()
    }

    override func start() {
        PreyLogger("Start logretrieval")
        isActive = true

        // Notify start
        let startParams = getParamsTo(kAction.logretrieval.rawValue,
                                      command: kCommand.start.rawValue,
                                      status: kStatus.started.rawValue)
        sendData(startParams, toEndpoint: responseDeviceEndpoint)
        
        // Locate prey.log file
        let logURL = getPreyLogFileURL()
        guard let fullData = try? Data(contentsOf: logURL) else {
            PreyLogger("logretrieval: unable to read prey.log at \(logURL.path)")
            stop()
            return
        }
        let maxBytes = 5 * 1024 * 1024 // 5MB tail to limit payload size
        let dataToSend = fullData.count > maxBytes ? fullData.suffix(maxBytes) : fullData

        // Build absolute upload URL with deviceKey 
        var uploadURL = logRetrievalEndpoint
        if let deviceKey = PreyConfig.sharedInstance.getDeviceKey() as String? {
            let sep = uploadURL.contains("?") ? "&" : "?"
            uploadURL += "\(sep)deviceKey=\(deviceKey)"
        }

        // Send raw octet-stream buffer with Basic auth (username API key, pwd "x")
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("LogRetrieval: starting upload to \(uploadURL) (\(dataToSend.count) bytes)")
            PreyHTTPClient.sharedInstance.sendFileToPrey(
                username,
                password: "x",
                file: Data(dataToSend),
                messageId: nil,
                httpMethod: Method.POST.rawValue,
                endPoint: uploadURL,
                onCompletion: { data, response, error in
                    let code = (response as? HTTPURLResponse)?.statusCode
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        PreyLogger("LogRetrieval: ✅ uploaded prey.log tail (\(dataToSend.count) bytes)")
                    } else {
                        PreyLogger("LogRetrieval: ❌ upload failed (HTTP=\(String(describing: code)) err=\(error?.localizedDescription ?? "nil"))")
                    }
                }
            )
        } else {
            PreyLogger("LogRetrieval: missing API key; cannot upload log buffer")
        }

        stop()
    }

    override func stop() {
        let stopParams = getParamsTo(kAction.logretrieval.rawValue,
                                     command: kCommand.stop.rawValue,
                                     status: kStatus.stopped.rawValue)
        sendData(stopParams, toEndpoint: responseDeviceEndpoint)
        isActive = false
        // Ensure the action is cleaned up from the queue even if the network path differs
        PreyModule.sharedInstance.checkStatus(self)
    }
}
