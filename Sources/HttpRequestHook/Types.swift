import Foundation

public class HttpRequest {
    var url: String
    var headers: [String: String]?
    var timeout: Double?
    var cachePolicy: NSURLRequest.CachePolicy?

    public init(
        url: String,
        headers: [String: String]? = nil,
        timeout: Double? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.url = url
        self.headers = headers
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }

    public init(url: String, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.url = url
        self.cachePolicy = cachePolicy
    }
}

public class HttpRequestWithBody<TBody>: HttpRequest {
    var body: TBody?
    
    public init(url: String, body: TBody, headers: [String : String]?, timeout: Double?) {
        super.init(url: url, headers: headers, timeout: timeout)
        self.body = body
    }
    
    public init(url: String, body: TBody) {
        super.init(url: url)
        self.body = body
    }
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
