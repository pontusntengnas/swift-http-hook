import Foundation

public enum HttpRequestType: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
}

public struct Callback<TResult> {
    public var loading: Bool
    public var result: TResult?
    public var error: RequestError?
}

public enum RequestError: Error, Equatable {
    case noUrl
    case badUrl
    case networkError(String)
    case jsonParseFailure(String)
    case httpStatus(Int)
    case exception(String)
}
