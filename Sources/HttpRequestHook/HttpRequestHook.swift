import Foundation
import OSLog

private enum HttpRequestType: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
}

public protocol HttpClient {
    func makeRequest(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: HttpClient {
    public func makeRequest(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }

        task.resume()
    }
}

public struct HttpRequestHook {
    private let session: HttpClient
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let logger: Logger?

    public init(session: HttpClient = URLSession.shared, logger: Logger? = nil) {
        self.session = session
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
        self.logger = logger
    }

    public func get<TResult: Decodable>(
        request: HttpRequest,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithoutBody(request: request, type: .get, callback: callback)
    }

    public func post<TBody: Encodable, TResult: Decodable>(
        request: HttpRequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithBody(request: request, type: .post, callback: callback)
    }

    public func post<TResult: Decodable>(
        request: HttpRequest,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithoutBody(request: request, type: .post, callback: callback)
    }

    public func put<TBody: Encodable, TResult: Decodable>(
        request: HttpRequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithBody(request: request, type: .put, callback: callback)
    }

    public func put<TResult: Decodable>(
        request: HttpRequest,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithoutBody(request: request, type: .put, callback: callback)
    }

    public func delete<TBody: Encodable, TResult: Decodable>(
        request: HttpRequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithBody(request: request, type: .delete, callback: callback)
    }

    public func delete<TResult: Decodable>(
        request: HttpRequest,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        requestWithoutBody(request: request, type: .delete, callback: callback)
    }

    private func requestWithoutBody<TResult: Decodable>(
        request: HttpRequest,
        type: HttpRequestType,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        logger?.info("\(type.rawValue.uppercased()) Request to: \(request.url)")
        callback(Callback(loading: true))

        do {
            doNetworkRequest(request: try buildURLRequest(request: request, type: type)) { (result: TResult?, error) in
                callback(Callback(loading: false, result: result, error: error))
            }
        } catch let error {
            logger?.error("\(error.localizedDescription)")
            callback(Callback(loading: false, error: .exception(error.localizedDescription)))
        }
    }

    private func requestWithBody<TBody: Encodable, TResult: Decodable>(
        request: HttpRequestWithBody<TBody>,
        type: HttpRequestType,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        logger?.info("\(type.rawValue.uppercased()) Request to: \(request.url)")
        callback(Callback(loading: true))

        do {
            var urlRequest = try buildURLRequest(request: request, type: type)
            if let body = request.body {
                urlRequest.httpBody = try jsonEncoder.encode(body)
            }

            doNetworkRequest(request: urlRequest) { (result: TResult?, error) in
                callback(Callback(loading: false, result: result, error: error))
            }
        } catch let error {
            logger?.error("\(error.localizedDescription)")
            callback(Callback(loading: false, error: .exception(error.localizedDescription)))
        }
    }

    private func buildURLRequest(request: HttpRequest, type: HttpRequestType) throws -> URLRequest {
        if request.url.isEmpty {
            logger?.error("URL is empty")
            throw RequestError.noUrl
        }

        guard let urlObject = URL(string: request.url) else {
            logger?.error("Invalid URL")
            throw RequestError.badUrl
        }

        var urlRequest = URLRequest(
            url: urlObject,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: request.timeout ?? 20)

        urlRequest.httpMethod = type.rawValue

        if let headers = request.headers {
            for (headerName, headerValue) in headers {
                urlRequest.addValue(headerValue, forHTTPHeaderField: headerName)
            }
        }

        return urlRequest
    }

    private func doNetworkRequest<TResult: Decodable>(
        request: URLRequest,
        completionHandler: @escaping (_ result: TResult?, _ error: RequestError?) -> Void) {
        session.makeRequest(request: request) { (data, response, error) in
            if let error = error {
                logger?.error("\(error.localizedDescription)")
                completionHandler(nil, RequestError.networkError(error.localizedDescription))
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                logger?.error("HttpResponse could not be created")
                completionHandler(nil, RequestError.exception("HttpResponse could not be created"))
                return
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                guard let dataObj = data else {
                    logger?.error("Response Data object is empty")
                    completionHandler(nil, RequestError.exception("Response Data object is empty"))
                    return
                }

                do {
                    completionHandler(try jsonDecoder.decode(TResult.self, from: dataObj), nil)
                } catch {
                    completionHandler(nil, RequestError.jsonParseFailure(error.localizedDescription))
                }
            } else {
                logger?.error("HTTP Response status code: \(httpResponse.statusCode)")
                completionHandler(nil, RequestError.httpStatus(httpResponse.statusCode))
            }
        }
    }
}
