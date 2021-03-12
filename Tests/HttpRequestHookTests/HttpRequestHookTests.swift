import XCTest
@testable import HttpRequestHook

class MockHttpClient: HttpClient {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    var delay: UInt32?

    func makeRequest(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        if let delay = delay {
            sleep(delay)
        }

        completionHandler(data, response, error)
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
        mockHttpClient.response = HTTPURLResponse(
            url: URL(string: "www.test123.se")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)
        let hook = HttpRequestHook(session: mockHttpClient)

        // Execute
        let request = HttpRequest(url: "www.test123.se")
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
        mockHttpClient.response = HTTPURLResponse(
            url: URL(string: "www.test123.se")!,
            statusCode: 199,
            httpVersion: nil,
            headerFields: nil)
        let hook = HttpRequestHook(session: mockHttpClient)

        // Execute
        let request = HttpRequest(url: "www.test123.se")
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
        mockHttpClient.response = HTTPURLResponse(
            url: URL(string: "www.test123.se")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)
        let hook = HttpRequestHook(session: mockHttpClient)

        // Execute
        let request = HttpRequestWithBody(url: "www.test123.se", body: TestStruct(name: "pst", age: 29))
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

    static var allTests = [
        ("test_Get_Successfully_Returns_Response", test_Get_Successfully_Returns_Response),
        ("test_Get_Handles_Failure_Status_Code", test_Get_Handles_Failure_Status_Code),
        ("test_Post_Successfully_Returns_Response", test_Post_Successfully_Returns_Response)
    ]
}
