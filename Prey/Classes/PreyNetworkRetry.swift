//
//  PreyNetworkRetry.swift
//  Prey
//
//  Created by Pato Jofre on 28/08/2025.
//  Copyright © 2025 Prey, Inc. All rights reserved.
//

import Foundation

// Centralized helper to send requests with exponential backoff and rich error logging.
class PreyNetworkRetry {
    // Simple unauthenticated JSON POST/PUT with retry and backoff
    static func sendJSONNoAuth(
        urlString: String,
        payload: [String: Any],
        httpMethod: String = "POST",
        tag: String = "NETWORK",
        maxAttempts: Int = 5,
        nonRetryStatusCodes: Set<Int> = Set(400...499),
        onCompletion: @escaping (Bool) -> Void
    ) {
        func delayForAttempt(_ attempt: Int) -> TimeInterval {
            let base = pow(2.0, Double(min(attempt - 1, 5)))
            let jitter = Double.random(in: 0...1)
            return min(60.0, base + jitter)
        }

        func buildRequest() -> URLRequest? {
            guard let url = URL(string: urlString), let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return nil }
            var req = URLRequest(url: url)
            req.httpMethod = httpMethod
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(PreyHTTPClient.sharedInstance.userAgent, forHTTPHeaderField: "User-Agent")
            req.httpBody = body
            req.timeoutInterval = 30
            return req
        }

        func attemptSend(_ attempt: Int) {
            guard let req = buildRequest() else { onCompletion(false); return }
            PreyHTTPClient.sharedInstance.performRequest(req) { data, response, error in
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    PreyLogger("\(tag): ✅ Success (HTTP \(http.statusCode))")
                    onCompletion(true)
                    return
                }

                if let error = error as NSError? {
                    PreyLogger("\(tag): ❌ Error (attempt \(attempt)/\(maxAttempts)): domain=\(error.domain) code=\(error.code) desc=\(error.localizedDescription)")
                }
                if let http = response as? HTTPURLResponse {
                    if !(200...299).contains(http.statusCode) {
                        let localized = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                        PreyLogger("\(tag): ❌ HTTP \(http.statusCode) \(localized) (attempt \(attempt)/\(maxAttempts))")
                        if nonRetryStatusCodes.contains(http.statusCode) {
                            PreyLogger("\(tag): 🚫 Not retrying due to non-retryable status \(http.statusCode)")
                            onCompletion(false)
                            return
                        }
                    }
                } else {
                    PreyLogger("\(tag): ❌ Unknown response (attempt \(attempt)/\(maxAttempts))")
                }

                if attempt < maxAttempts {
                    let delay = delayForAttempt(attempt + 1)
                    PreyLogger("\(tag): 🔁 Retrying in \(String(format: "%.1f", delay))s (attempt \(attempt + 1)/\(maxAttempts))")
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                        attemptSend(attempt + 1)
                    }
                } else {
                    PreyLogger("\(tag): ❌ Exhausted retries; giving up")
                    onCompletion(false)
                }
            }
        }

        attemptSend(1)
    }

    static func sendDataWithBackoff(
        username: String,
        password: String = "x",
        params: [String: Any]?,
        messageId: String? = nil,
        httpMethod: String,
        endPoint: String,
        tag: String = "NETWORK",
        maxAttempts: Int = 5,
        nonRetryStatusCodes: Set<Int> = [401],
        onCompletion: @escaping (Bool) -> Void
    ) {
        func delayForAttempt(_ attempt: Int) -> TimeInterval {
            let base = pow(2.0, Double(min(attempt - 1, 5)))
            let jitter = Double.random(in: 0...1)
            return min(60.0, base + jitter)
        }

        func paramsPreview(_ params: [String: Any]?) -> String? {
            guard let p = params, let d = try? JSONSerialization.data(withJSONObject: p, options: []), var s = String(data: d, encoding: .utf8) else { return nil }
            if s.count > 500 { s = String(s.prefix(500)) + "…" }
            return s
        }

        func bodySnippet(_ data: Data?) -> String {
            guard let data = data, !data.isEmpty else { return "" }
            let str = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            return str.count > 500 ? String(str.prefix(500)) + "…" : str
        }

        func attemptSend(_ attempt: Int) {
            PreyHTTPClient.sharedInstance.sendDataToPrey(
                username,
                password: password,
                params: params,
                messageId: messageId,
                httpMethod: httpMethod,
                endPoint: endPoint,
                onCompletion: { data, response, error in
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        PreyLogger("\(tag): ✅ Success (HTTP \(http.statusCode))")
                        onCompletion(true)
                        return
                    }

                    if let error = error as NSError? {
                        PreyLogger("\(tag): ❌ Error (attempt \(attempt)/\(maxAttempts)): domain=\(error.domain) code=\(error.code) desc=\(error.localizedDescription)")
                    }
                    if let http = response as? HTTPURLResponse {
                        if !(200...299).contains(http.statusCode) {
                            let localized = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                            PreyLogger("\(tag): ❌ HTTP \(http.statusCode) \(localized) (attempt \(attempt)/\(maxAttempts)). Body: \(bodySnippet(data))")
                            if nonRetryStatusCodes.contains(http.statusCode) {
                                PreyLogger("\(tag): 🚫 Not retrying due to non-retryable status \(http.statusCode)")
                                onCompletion(false)
                                return
                            }
                        }
                    } else {
                        PreyLogger("📣 \(tag): ❌ Unknown response state (attempt \(attempt)/\(maxAttempts))")
                    }

                    if attempt < maxAttempts {
                        let delay = delayForAttempt(attempt + 1)
                        PreyLogger("\(tag): 🔁 Retrying in \(String(format: "%.1f", delay))s (attempt \(attempt + 1)/\(maxAttempts))")
                        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                            attemptSend(attempt + 1)
                        }
                    } else {
                        PreyLogger("\(tag): ❌ Exhausted retries; giving up")
                        onCompletion(false)
                    }
                }
            )
        }

        attemptSend(1)
    }
}

