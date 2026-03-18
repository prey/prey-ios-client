//
//  ReplyIdTests.swift
//  PreyTests
//

import XCTest
@testable import Prey

final class ReplyIdTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - PreyAction.getParamsTo

    func testGetParamsIncludesReplyIdWhenValid() {
        let action = PreyAction(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)
        action.messageId = "abc123"

        let params = action.getParamsTo(kAction.location.rawValue, command: kCommand.get.rawValue, status: kStatus.started.rawValue)

        XCTAssertEqual(params["reply_id"] as? String, "abc123")
    }

    func testGetParamsOmitsReplyIdWhenInvalid() {
        let action = PreyAction(withTarget: kAction.location, withCommand: kCommand.get, withOptions: nil)

        action.messageId = nil
        var params = action.getParamsTo(kAction.location.rawValue, command: kCommand.get.rawValue, status: kStatus.started.rawValue)
        XCTAssertNil(params["reply_id"])

        action.messageId = "   "
        params = action.getParamsTo(kAction.location.rawValue, command: kCommand.get.rawValue, status: kStatus.started.rawValue)
        XCTAssertNil(params["reply_id"])

        action.messageId = "undefined"
        params = action.getParamsTo(kAction.location.rawValue, command: kCommand.get.rawValue, status: kStatus.started.rawValue)
        XCTAssertNil(params["reply_id"])
    }

    // MARK: - PreyHTTPClient headers

    func testApplyHeadersAddsCorrelationIdOnlyWhenValid() {
        let validExpectation = expectation(description: "Valid messageId adds correlation header")
        MockURLProtocol.requestHandler = { request in
            let header = request.value(forHTTPHeaderField: "X-Prey-Correlation-Id")
            XCTAssertEqual(header, "abc123")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            "user",
            password: "x",
            params: nil,
            messageId: "abc123",
            httpMethod: Method.GET.rawValue,
            endPoint: actionsDeviceEndpoint
        ) { _, _, _ in
            validExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)

        let invalidExpectation = expectation(description: "Invalid messageId omits correlation header")
        MockURLProtocol.requestHandler = { request in
            let header = request.value(forHTTPHeaderField: "X-Prey-Correlation-Id")
            XCTAssertNil(header)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        PreyHTTPClient.sharedInstance.sendDataToPrey(
            "user",
            password: "x",
            params: nil,
            messageId: "undefined",
            httpMethod: Method.GET.rawValue,
            endPoint: actionsDeviceEndpoint
        ) { _, _, _ in
            invalidExpectation.fulfill()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    // MARK: - PreyModule.parseActionsFromPanel

    func testParseActionsFromPanelSetsMessageIdWhenValid() {
        let module = PreyModule.sharedInstance
        module.actionArray.removeAll()
        module.skipRunActionForTests = true
        defer {
            module.actionArray.removeAll()
            module.skipRunActionForTests = false
        }

        let json = """
        [
          {"target":"\(kAction.list_permissions.rawValue)","command":"\(kCommand.get.rawValue)","options":{"\(kOptions.messageID.rawValue)":"abc123"}}
        ]
        """

        module.parseActionsFromPanel(json)

        guard let action = module.actionArray.first else {
            XCTFail("Expected an action to be parsed")
            return
        }
        XCTAssertEqual(action.messageId, "abc123")
    }

    func testParseActionsFromPanelOmitsMessageIdWhenInvalid() {
        let module = PreyModule.sharedInstance
        module.actionArray.removeAll()
        module.skipRunActionForTests = true
        defer {
            module.actionArray.removeAll()
            module.skipRunActionForTests = false
        }

        let json = """
        [
          {"target":"\(kAction.list_permissions.rawValue)","command":"\(kCommand.get.rawValue)","options":{"\(kOptions.messageID.rawValue)":"   "}}
        ]
        """

        module.parseActionsFromPanel(json)

        guard let action = module.actionArray.first else {
            XCTFail("Expected an action to be parsed")
            return
        }
        XCTAssertNil(action.messageId)
    }
}

// MARK: - URLProtocol Mock

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
