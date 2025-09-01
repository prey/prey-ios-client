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
        
        // Locate prey.log file and prepare inline payload (no uploadID)
        let logURL = getPreyLogFileURL()
        guard let fullData = try? Data(contentsOf: logURL) else {
            PreyLogger("logretrieval: unable to read prey.log at \(logURL.path)")
            stop()
            return
        }
        let maxBytes = 512 * 1024 // 512KB tail to limit payload size
        let isTruncated = fullData.count > maxBytes
        let dataToSend = isTruncated ? fullData.suffix(maxBytes) : fullData
        let b64 = dataToSend.base64EncodedString()

        let payload: [String: Any] = [
            "name": "prey.log",
            "mimetype": "text/plain",
            "size": fullData.count,
            "encoding": "base64",
            "truncated": isTruncated,
            "data": b64
        ]
        let params: [String: Any] = [ kAction.logretrieval.rawValue: payload ]
        sendData(params, toEndpoint: logRetrievalEndpoint)
        stop()
    }

    override func stop() {
        let stopParams = getParamsTo(kAction.logretrieval.rawValue,
                                     command: kCommand.stop.rawValue,
                                     status: kStatus.stopped.rawValue)
        sendData(stopParams, toEndpoint: responseDeviceEndpoint)
        isActive = false
    }

    // MARK: Helpers
    private func upload(data: Data, to endpoint: String) { /* not used in this action */ }
}
