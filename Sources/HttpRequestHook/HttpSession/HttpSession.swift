import Foundation

public protocol HttpSession {
    func startDataTask(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: HttpSession {
    public func startDataTask(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }

        task.resume()
    }
}
