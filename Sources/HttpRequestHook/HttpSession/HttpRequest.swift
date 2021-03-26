import Foundation

public protocol HttpRequest {
    var url: String { get }

    func toURLRequest(type: HttpRequestType) throws -> URLRequest
}

public class RequestWithoutBody: HttpRequest {
    public var url: String

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

    public func toURLRequest(type: HttpRequestType) throws -> URLRequest {
        if self.url.isEmpty {
            throw RequestError.noUrl
        }

        guard let urlObject = URL(string: self.url) else {
            throw RequestError.badUrl
        }

        var urlRequest = URLRequest(
            url: urlObject,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: self.timeout ?? 20)

        urlRequest.httpMethod = type.rawValue

        if let headers = self.headers {
            for (headerName, headerValue) in headers {
                urlRequest.addValue(headerValue, forHTTPHeaderField: headerName)
            }
        }

        return urlRequest
    }
}

public class RequestWithBody<TBody: Encodable>: RequestWithoutBody {
    private let jsonEncoder: JSONEncoder
    private var body: TBody?

    public init(url: String, body: TBody, headers: [String: String]?, timeout: Double?) {
        self.jsonEncoder = JSONEncoder()
        self.body = body
        super.init(url: url, headers: headers, timeout: timeout)
    }

    public init(url: String, body: TBody) {
        self.jsonEncoder = JSONEncoder()
        self.body = body
        super.init(url: url)
    }

    override public func toURLRequest(type: HttpRequestType) throws -> URLRequest {
        var urlRequest = try super.toURLRequest(type: type)

        if let body = self.body {
            urlRequest.httpBody = try jsonEncoder.encode(body)
        }

        return urlRequest
    }
}
