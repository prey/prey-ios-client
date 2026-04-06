import XCTest
import Foundation

class LocationAPIClientTests: XCTestCase {

    var sut: LocationAPIClient!
    var mockConfig: URLSessionConfiguration!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        mockConfig = URLSessionConfiguration.ephemeral
        mockConfig.protocolClasses = [MockURLProtocol.self]
        sut = LocationAPIClient(userAgent: "Prey/Test (iOS 18.0.0)", sessionConfiguration: mockConfig)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Auth

    func testBasicAuthHeaderFormat() {
        let header = sut.basicAuthHeader(user: "myApiKey", password: "x")
        let expected = "Basic " + Data("myApiKey:x".utf8).base64EncodedString()
        XCTAssertEqual(header, expected)
    }

    // MARK: - Request Format

    func testRequestContainsCorrectHeaders() {
        let done = expectation(description: "Request sent")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let body: [String: Any] = ["location": ["lat": -33.44, "lng": -70.66, "method": "native"]]

        sut.sendLocation(apiKey: "testKey", deviceKey: "dev123", body: body) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)

        let request = MockURLProtocol.capturedRequests.first
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), "Prey/Test (iOS 18.0.0)")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "X-Prey-Device-Id"), "dev123")
        XCTAssertTrue(request?.url?.path.contains("/devices/dev123/data") ?? false)

        let authHeader = request?.value(forHTTPHeaderField: "Authorization") ?? ""
        XCTAssertTrue(authHeader.hasPrefix("Basic "))
    }

    func testRequestBodyContainsLocationData() {
        let done = expectation(description: "Request sent")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        let body: [String: Any] = ["location": ["lat": -33.44, "lng": -70.66, "method": "native"]]

        sut.sendLocation(apiKey: "testKey", deviceKey: "dev123", body: body) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)

        let request = MockURLProtocol.capturedRequests.first
        XCTAssertNotNil(request?.httpBody)

        if let data = request?.httpBody,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let loc = json["location"] as? [String: Any] {
            XCTAssertEqual(loc["lat"] as? Double, -33.44)
            XCTAssertEqual(loc["lng"] as? Double, -70.66)
            XCTAssertEqual(loc["method"] as? String, "native")
        } else {
            XCTFail("Request body should contain location data")
        }
    }

    // MARK: - Success

    func testSuccessfulResponseCompletesWithoutRetry() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1, "Should not retry on 200")
    }

    // MARK: - No Retry on Auth Errors

    func testDoesNotRetryOn401() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1, "Should not retry on 401")
    }

    func testDoesNotRetryOn403() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1, "Should not retry on 403")
    }

    func testDoesNotRetryOn429() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1, "Should not retry on 429")
    }

    // MARK: - Retry on Server Errors

    func testRetriesOnServerError() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 15)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 3, "Should retry 3 times on 500")
    }

    func testRetriesOnNetworkError() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { _ in
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 15)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 3, "Should retry 3 times on network error")
    }

    // MARK: - Retry then Succeed

    func testRetrySucceedsOnSecondAttempt() {
        let done = expectation(description: "Completed")
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let code = callCount == 1 ? 500 : 200
            let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        sut.sendLocation(apiKey: "k", deviceKey: "d", body: ["location": [:]]) {
            done.fulfill()
        }

        waitForExpectations(timeout: 15)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 2, "Should succeed on second attempt")
    }
}
