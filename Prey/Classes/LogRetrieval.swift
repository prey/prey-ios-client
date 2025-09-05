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
        // Include full prey.log (no tail)
        let preyLogData = fullData
        let zipData = ZipBuilder.build(entries: [(name: "prey.log", data: Data(preyLogData))])

        // Build absolute upload URL with deviceKey 
        var uploadURL = logRetrievalEndpoint
        if let deviceKey = PreyConfig.sharedInstance.getDeviceKey() as String? {
            let sep = uploadURL.contains("?") ? "&" : "?"
            uploadURL += "\(sep)deviceKey=\(deviceKey)"
        }

        // Send archive buffer with Basic auth (username API key, pwd "x")
        if let username = PreyConfig.sharedInstance.userApiKey {
            PreyLogger("LogRetrieval: starting upload to \(uploadURL) (zip \(zipData.count) bytes)")
            PreyHTTPClient.sharedInstance.sendFileToPrey(
                username,
                password: "x",
                file: zipData,
                messageId: nil,
                httpMethod: Method.POST.rawValue,
                endPoint: uploadURL,
                onCompletion: { data, response, error in
                    let code = (response as? HTTPURLResponse)?.statusCode
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        PreyLogger("LogRetrieval: ✅ uploaded archive (\(zipData.count) bytes)")
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
