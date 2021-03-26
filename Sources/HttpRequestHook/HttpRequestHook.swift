import Foundation
import OSLog

public struct HttpRequestHook {
    private var httpClient: HttpClient
    private let jsonDecoder: JSONDecoder
    private let logger: Logger?

    public init(httpClient: HttpClient = BaseHttpClient(session: URLSession.shared), logger: Logger? = nil) {
        self.jsonDecoder = JSONDecoder()
        self.logger = logger
        self.httpClient = httpClient
        self.httpClient.logger = logger
    }

    public func get<TResult: Decodable>(
        request: RequestWithoutBody,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .get, callback: callback)
    }

    public func post<TBody: Encodable, TResult: Decodable>(
        request: RequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .post, callback: callback)
    }

    public func post<TResult: Decodable>(
        request: RequestWithoutBody,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .post, callback: callback)
    }

    public func put<TBody: Encodable, TResult: Decodable>(
        request: RequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .put, callback: callback)
    }

    public func put<TResult: Decodable>(
        request: RequestWithoutBody,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .put, callback: callback)
    }

    public func delete<TBody: Encodable, TResult: Decodable>(
        request: RequestWithBody<TBody>,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .delete, callback: callback)
    }

    public func delete<TResult: Decodable>(
        request: RequestWithoutBody,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        doRequestWithJsonResponse(request: request, type: .delete, callback: callback)
    }

    public func rawRequest(
        request: HttpRequest,
        type: HttpRequestType,
        callback: @escaping (_ callback: Callback<Data>) -> Void) {
        doRequest(request: request, type: type, callback: callback)
    }

    private func doRequestWithJsonResponse<TResult: Decodable>(
        request: HttpRequest,
        type: HttpRequestType,
        callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        logger?.info("\(type.rawValue.uppercased()) Request to: \(request.url)")
        callback(Callback(loading: true))

        do {
            httpClient.doNetworkRequest(
                request: try request.toURLRequest(type: type)) { (result: Data?, error) in
                if let result = result {
                    decodeJsonResponse(data: result) { (result: TResult?, error) in
                        callback(Callback(loading: false, result: result, error: error))
                    }
                } else {
                    callback(Callback(loading: false, result: nil, error: error))
                }
            }
        } catch let error {
            handleError(error: error, callback: callback)
        }
    }

    private func doRequest(
        request: HttpRequest,
        type: HttpRequestType,
        callback: @escaping (_ callback: Callback<Data>) -> Void) {
        logger?.info("\(type.rawValue.uppercased()) Request to: \(request.url)")
        callback(Callback(loading: true))

        do {
            httpClient.doNetworkRequest(
                request: try request.toURLRequest(type: type)) { (result: Data?, error) in
                if let result = result {
                    callback(Callback(loading: false, result: result, error: error))
                } else {
                    callback(Callback(loading: false, result: nil, error: error))
                }
            }
        } catch let error {
            handleError(error: error, callback: callback)
        }
    }

    private func decodeJsonResponse<TResult: Decodable>(
        data: Data,
        completionHandler: @escaping (_ result: TResult?, _ error: RequestError?) -> Void) {
        do {
            completionHandler(try jsonDecoder.decode(TResult.self, from: data), nil)
        } catch {
            completionHandler(nil, RequestError.jsonParseFailure(error.localizedDescription))
        }
    }

    private func handleError<TResult>(error: Error, callback: @escaping (_ callback: Callback<TResult>) -> Void) {
        logger?.error("\(error.localizedDescription)")
        callback(Callback(loading: false, error: .exception(error.localizedDescription)))
    }
}
