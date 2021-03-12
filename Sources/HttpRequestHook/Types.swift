import Foundation

public class HttpRequest {
    var url: String
    var headers: [String: String]?
    var timeout: Double?
    var cachePolicy: NSURLRequest.CachePolicy?

    init(
        url: String,
        headers: [String: String]? = nil,
        timeout: Double? = nil,
        cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.url = url
        self.headers = headers
        self.timeout = timeout
    }

    init(url: String, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.url = url
    }
}

public class HttpRequestWithBody<TBody>: HttpRequest {
    var body: TBody?
    
    init(url: String, body: TBody, headers: [String : String]?, timeout: Double?) {
        super.init(url: url, headers: headers, timeout: timeout)
        self.body = body
    }
    
    init(url: String, body: TBody) {
        super.init(url: url)
        self.body = body
    }
}

public struct Callback<TResult> {
    var loading: Bool
    var result: TResult?
    var error: RequestError?
}

public enum RequestError: Error, Equatable {
    case noUrl
    case badUrl
    case networkError(String)
    case jsonParseFailure(String)
    case httpStatus(Int)
    case exception(String)
}
