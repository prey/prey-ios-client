# CI Network Mock Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure CI never makes real outbound network calls by routing all `PreyHTTPClient` traffic through a mock `URLProtocol` when `CI=true`.

**Architecture:** Introduce a `URLProtocol`-based mock and a session-creation hook in `PreyHTTPClient` that injects the mock when the CI environment flag is set. The mock returns deterministic stub responses for known endpoints and a controlled error for unknown endpoints.

**Tech Stack:** Swift, URLSession, URLProtocol, XCTest, GitHub Actions (CI env var).

### Task 1: Add mock URLProtocol

**Files:**
- Create: `Prey/Classes/Mock/PreyMockURLProtocol.swift`

**Step 1: Write the failing test**

Create a test that verifies requests are intercepted when `CI=true` (it should fail before the mock exists).

```swift
func testMockProtocolInterceptsRequestsInCI() {
    setenv("CI", "true", 1)
    let expectation = self.expectation(description: "mock intercept")

    let url = URL(string: "https://panel.preyhq.com/api/v2/devices/abc/reports.json")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"

    PreyHTTPClient.sharedInstance.performRequest(req) { data, response, error in
        let http = response as? HTTPURLResponse
        XCTAssertEqual(http?.statusCode, 409)
        XCTAssertNil(error)
        expectation.fulfill()
    }

    waitForExpectations(timeout: 5)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace Prey.xcworkspace -scheme Prey-CI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test`
Expected: FAIL because no mock protocol is installed.

**Step 3: Write minimal implementation**

Create `PreyMockURLProtocol`:
- `canInit(with:)` returns true for all requests in CI mode.
- `startLoading()` returns:
  - 409 for `*/reports.json`
  - 200 for `*/response`
  - error for all others (e.g. `NSURLErrorDomain`)
- Provide an empty body or a small JSON payload.

**Step 4: Run test to verify it passes**

Run the same `xcodebuild` command.
Expected: PASS.

**Step 5: Commit**

```bash
git add Prey/Classes/Mock/PreyMockURLProtocol.swift PreyTests/<testfile>.swift
git commit -m "Add mock URLProtocol for CI"
```

### Task 2: Inject mock protocol into PreyHTTPClient sessions

**Files:**
- Modify: `Prey/Classes/PreyHTTPClient.swift`

**Step 1: Write the failing test**

Test that `PreyHTTPClient` uses a session configured with `PreyMockURLProtocol` when `CI=true`.

```swift
func testHTTPClientUsesMockSessionInCI() {
    setenv("CI", "true", 1)
    let session = PreyHTTPClient.sharedInstance.debugSessionForTests()
    let classes = session.configuration.protocolClasses ?? []
    XCTAssertTrue(classes.contains { $0 == PreyMockURLProtocol.self })
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace Prey.xcworkspace -scheme Prey-CI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test`
Expected: FAIL because session is not yet configured.

**Step 3: Write minimal implementation**

Add a factory method to `PreyHTTPClient`:
- `makeSession(configuration:)` that injects protocolClasses when `CI=true`.
- Use it for both `sharedSession` and `backgroundSession`.
- Add `debugSessionForTests()` only in `DEBUG` builds for inspection.

**Step 4: Run test to verify it passes**

Run the same `xcodebuild` command.
Expected: PASS.

**Step 5: Commit**

```bash
git add Prey/Classes/PreyHTTPClient.swift PreyTests/<testfile>.swift

git commit -m "Inject mock URLProtocol in CI sessions"
```

### Task 3: Remove CI-only network skip from tests

**Files:**
- Modify: `PreyTests/PreyRestTests.swift`

**Step 1: Write the failing test**

Remove `XCTSkipIf(CI)` from `testRest11SendReport` and ensure it passes with mock responses.

**Step 2: Run test to verify it passes**

Run: `xcodebuild -workspace Prey.xcworkspace -scheme Prey-CI -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test`
Expected: PASS using mock response for `reports.json`.

**Step 3: Commit**

```bash
git add PreyTests/PreyRestTests.swift

git commit -m "Run report test against CI mock"
```

### Task 4: CI config validation

**Files:**
- Verify: `.github/workflows/ci.yml`

**Step 1: Set CI env explicitly**

Add `CI: "true"` under job `env` to guarantee the flag exists.

```yaml
env:
  CI: "true"
```

**Step 2: Run CI**

Push and confirm no outbound calls in logs.

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml

git commit -m "Set CI env for network mocks"
```
