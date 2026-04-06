import XCTest
import Foundation

class GeoIPServiceTests: XCTestCase {

    var sut: GeoIPService!
    var mockConfig: URLSessionConfiguration!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        mockConfig = URLSessionConfiguration.ephemeral
        mockConfig.protocolClasses = [MockURLProtocol.self]
        sut = GeoIPService(userAgent: "Prey/Test (iOS 18.0.0)", sessionConfiguration: mockConfig)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Successful Response

    func testParsesValidGeoIPResponse() {
        let done = expectation(description: "Completed")

        let responseJSON = """
        {"ip":"190.0.0.1","city":"Santiago","region":"RM","country":"CL","loc":"-33.4489,-70.6693","org":"AS12345","timezone":"America/Santiago"}
        """.data(using: .utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        var result: GeoIPService.GeoIPLocation?

        sut.fetchLocation { location in
            result = location
            done.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.lat ?? 0, -33.4489, accuracy: 0.0001)
        XCTAssertEqual(result?.lng ?? 0, -70.6693, accuracy: 0.0001)
    }

    // MARK: - Malformed Responses

    func testReturnsNilForMissingLocField() {
        let done = expectation(description: "Completed")

        let responseJSON = """
        {"ip":"190.0.0.1","city":"Santiago"}
        """.data(using: .utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        var result: GeoIPService.GeoIPLocation?

        sut.fetchLocation { location in
            result = location
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNil(result, "Should return nil when 'loc' field is missing")
    }

    func testReturnsNilForInvalidLocFormat() {
        let done = expectation(description: "Completed")

        let responseJSON = """
        {"loc":"not-a-coordinate"}
        """.data(using: .utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        var result: GeoIPService.GeoIPLocation?

        sut.fetchLocation { location in
            result = location
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNil(result, "Should return nil for malformed 'loc' field")
    }

    func testReturnsNilForInvalidJSON() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8))
        }

        var result: GeoIPService.GeoIPLocation?

        sut.fetchLocation { location in
            result = location
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNil(result, "Should return nil for invalid JSON")
    }

    // MARK: - Network Errors

    func testReturnsNilOnNetworkError() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { _ in
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        }

        var result: GeoIPService.GeoIPLocation?

        sut.fetchLocation { location in
            result = location
            done.fulfill()
        }

        waitForExpectations(timeout: 10)
        XCTAssertNil(result, "Should return nil on network error")
    }

    // MARK: - Request Format

    func testRequestContainsUserAgent() {
        let done = expectation(description: "Completed")

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{}".data(using: .utf8))
        }

        sut.fetchLocation { _ in done.fulfill() }

        waitForExpectations(timeout: 10)

        let request = MockURLProtocol.capturedRequests.first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), "Prey/Test (iOS 18.0.0)")
    }
}
