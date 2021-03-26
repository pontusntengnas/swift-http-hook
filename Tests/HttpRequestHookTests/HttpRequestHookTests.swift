import XCTest
import OSLog
@testable import HttpRequestHook

class MockHttpClient: HttpClient {
    var logger: Logger?
    var data: Data?
    var error: RequestError?
    var delay: UInt32?

    func doNetworkRequest(request: URLRequest, completionHandler: @escaping (Data?, RequestError?) -> Void) {
        if let delay = delay {
            sleep(delay)
        }

        completionHandler(data, error)
    }
}

struct TestStruct: Codable, Equatable {
    let name: String
    let age: Int
}

final class HttpRequestHookTests: XCTestCase {
    let encoder = JSONEncoder()

    func test_Get_Successfully_Returns_Response() {
        // Setup
        let mockHttpClient = MockHttpClient()
        let expectedResponse = TestStruct(name: "GET_TEST", age: 99)
        mockHttpClient.data = try! encoder.encode(expectedResponse)
        let hook = HttpRequestHook(httpClient: mockHttpClient)

        // Execute
        let request = RequestWithoutBody(url: "www.test123.se")
        var callbacks: [Callback<TestStruct>] = []
        hook.get(request: request) { (callback: Callback<TestStruct>) in
            callbacks.append(callback)
        }

        // Assert
        let firstCallback = callbacks[0]
        let secondCallback = callbacks[1]

        XCTAssertEqual(2, callbacks.count)

        XCTAssertEqual(true, firstCallback.loading)
        XCTAssertNil(firstCallback.error)
        XCTAssertNil(firstCallback.result)

        XCTAssertEqual(false, secondCallback.loading)
        XCTAssertNil(secondCallback.error)
        XCTAssertEqual(expectedResponse, secondCallback.result)
    }

    func test_Get_Handles_Failure_Status_Code() {
        // Setup
        let mockHttpClient = MockHttpClient()
        mockHttpClient.error = RequestError.httpStatus(199)
        let hook = HttpRequestHook(httpClient: mockHttpClient)

        // Execute
        let request = RequestWithoutBody(url: "www.test123.se")
        var callbacks: [Callback<TestStruct>] = []
        hook.get(request: request) { (callback: Callback<TestStruct>) in
            callbacks.append(callback)
        }

        // Assert
        let firstCallback = callbacks[0]
        let secondCallback = callbacks[1]

        XCTAssertEqual(2, callbacks.count)

        XCTAssertEqual(true, firstCallback.loading)
        XCTAssertNil(firstCallback.error)
        XCTAssertNil(firstCallback.result)

        XCTAssertEqual(false, secondCallback.loading)
        XCTAssertEqual(RequestError.httpStatus(199), secondCallback.error)
        XCTAssertNil(secondCallback.result)
    }

    func test_Post_Successfully_Returns_Response() {
        // Setup
        let mockHttpClient = MockHttpClient()
        let expectedResponse = TestStruct(name: "POST_TEST", age: 99)
        mockHttpClient.data = try! encoder.encode(expectedResponse)
        let hook = HttpRequestHook(httpClient: mockHttpClient)

        // Execute
        let request = RequestWithBody(url: "www.test123.se", body: TestStruct(name: "pst", age: 29))
        var callbacks: [Callback<TestStruct>] = []
        hook.post(request: request) { (callback: Callback<TestStruct>) in
            callbacks.append(callback)
        }

        // Assert
        let firstCallback = callbacks[0]
        let secondCallback = callbacks[1]

        XCTAssertEqual(2, callbacks.count)

        XCTAssertEqual(true, firstCallback.loading)
        XCTAssertNil(firstCallback.error)
        XCTAssertNil(firstCallback.result)

        XCTAssertEqual(false, secondCallback.loading)
        XCTAssertNil(secondCallback.error)
        XCTAssertEqual(expectedResponse, secondCallback.result)
    }

    func test_Raw_Request() {
        // Setup
        let mockHttpClient = MockHttpClient()
        mockHttpClient.data = Data(base64Encoded: "aG9vay10ZXN0") // base64 = hook-test
        let hook = HttpRequestHook(httpClient: mockHttpClient)

        // Execute
        let request = RequestWithoutBody(url: "www.test123.se")
        var callbacks: [Callback<Data>] = []
        hook.rawRequest(request: request, type: .get) { (callback) in
            callbacks.append(callback)
        }

        // Assert
        let firstCallback = callbacks[0]
        let secondCallback = callbacks[1]

        XCTAssertEqual(2, callbacks.count)

        XCTAssertEqual(true, firstCallback.loading)
        XCTAssertNil(firstCallback.error)
        XCTAssertNil(firstCallback.result)

        XCTAssertEqual(false, secondCallback.loading)
        XCTAssertNil(secondCallback.error)
        XCTAssertEqual("hook-test", String(data: secondCallback.result!, encoding: .utf8))
    }

    static var allTests = [
        ("test_Get_Successfully_Returns_Response", test_Get_Successfully_Returns_Response),
        ("test_Get_Handles_Failure_Status_Code", test_Get_Handles_Failure_Status_Code),
        ("test_Post_Successfully_Returns_Response", test_Post_Successfully_Returns_Response)
    ]
}
