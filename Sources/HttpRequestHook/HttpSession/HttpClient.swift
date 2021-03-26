import Foundation
import OSLog

public protocol HttpClient {
    var logger: Logger? { get set }

    func doNetworkRequest(
        request: URLRequest,
        completionHandler: @escaping (_ result: Data?, _ error: RequestError?) -> Void)
}

public struct BaseHttpClient: HttpClient {
    public var logger: Logger?

    private let session: HttpSession

    public init(session: HttpSession = URLSession.shared, logger: Logger? = nil) {
        self.session = session
        self.logger = logger
    }

    public func doNetworkRequest(
        request: URLRequest,
        completionHandler: @escaping (_ result: Data?, _ error: RequestError?) -> Void) {
        session.startDataTask(request: request) { (data, response, error) in
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

                completionHandler(dataObj, nil)
            } else {
                logger?.error("HTTP Response status code: \(httpResponse.statusCode)")
                completionHandler(nil, RequestError.httpStatus(httpResponse.statusCode))
            }
        }
    }
}
