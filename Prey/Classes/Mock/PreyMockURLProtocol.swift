import Foundation

final class PreyMockURLProtocol: URLProtocol {
    private static let handledKey = "PreyMockURLProtocolHandled"

    override class func canInit(with request: URLRequest) -> Bool {
        guard ProcessInfo.processInfo.environment["CI"] == "true" else {
            return false
        }
        if URLProtocol.property(forKey: handledKey, in: request) != nil {
            return false
        }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            let err = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        let (statusCode, body) = response(for: url)
        if statusCode <= 0 {
            let err = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "Mocked network: unhandled URL"])
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        let headers = ["Content-Type": "application/json"]
        if let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let body = body {
            client?.urlProtocol(self, didLoad: body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }

    private func response(for url: URL) -> (Int, Data?) {
        let path = url.path
        if path.hasSuffix("/reports.json") {
            let data = "{\"error\":\"device_not_missing\"}".data(using: .utf8)
            return (409, data)
        }
        if path.contains("/response") {
            let data = "{\"ok\":true}".data(using: .utf8)
            return (200, data)
        }
        return (0, nil)
    }
}
