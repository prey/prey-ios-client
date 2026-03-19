import XCTest

@testable import Prey

final class MockNetworkTests: XCTestCase {

    override func tearDown() {
        unsetenv("CI")
        super.tearDown()
    }

    func testMockProtocolInterceptsRequestsInCI() {
        setenv("CI", "true", 1)
        let expectation = self.expectation(description: "mock intercept")

        let url = URL(string: "https://panel.preyhq.com/api/v2/devices/abc/reports.json")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PreyMockURLProtocol.self]
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { _, response, error in
            let http = response as? HTTPURLResponse
            XCTAssertEqual(http?.statusCode, 409)
            XCTAssertNil(error)
            expectation.fulfill()
        }.resume()

        waitForExpectations(timeout: 5)
    }
}
