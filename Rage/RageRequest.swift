import Foundation
import Result

open class RageRequest: Call {

    var httpMethod: HttpMethod
    var baseUrl: String
    var methodPath: String?
    var queryParameters: [String:String] = [:]
    var pathParameters: [String:String] = [:]
    var headers: [String:String] = [:]

    var authenticator: Authenticator?
    var errorHandlers: [ErrorHandler] = []
    var plugins: [RagePlugin] = []

    var timeoutMillis: Int = 60 * 1000

    var stubData: StubData?

    init(httpMethod: HttpMethod, baseUrl: String) {
        self.httpMethod = httpMethod
        self.baseUrl = baseUrl
    }

    init(requestDescription: RequestDescription,
         plugins: [RagePlugin]) {
        self.httpMethod = requestDescription.httpMethod
        self.baseUrl = requestDescription.baseUrl
        self.methodPath = requestDescription.path
        self.headers = requestDescription.headers
        self.headers["Content-Type"] = requestDescription.contentType.stringValue()

        self.errorHandlers = requestDescription.errorHandlers
        self.authenticator = requestDescription.authenticator

        self.timeoutMillis = requestDescription.timeoutMillis
        self.plugins = plugins
    }

    // MARK: Parameters

    open func url(_ url: String) -> RageRequest {
        self.baseUrl = url
        return self
    }

    open func query<T>(_ key: String, _ value: T?) -> RageRequest {
        guard let safeValue = value else {
            queryParameters.removeValue(forKey: key)
            return self
        }
        queryParameters[key] = String(describing: safeValue)
        return self
    }

    open func queryDictionary<T>(_ dictionary: [String:T?]) -> RageRequest {
        for (key, value) in dictionary {
            if let safeValue = value {
                queryParameters[key] = String(describing: safeValue)
            }
        }
        return self
    }

    open func path<T>(_ key: String, _ value: T) -> RageRequest {
        pathParameters[key] = String(describing: value)
        return self
    }

    open func header(_ key: String, _ value: String?) -> RageRequest {
        guard let safeValue = value else {
            headers.removeValue(forKey: key)
            return self
        }
        headers[key] = safeValue
        return self
    }

    open func headerDictionary(_ dictionary: [String:String?]) -> RageRequest {
        for (key, value) in dictionary {
            if let safeValue = value {
                headers[key] = safeValue
            } else {
                headers.removeValue(forKey: key)
            }
        }
        return self
    }

    open func contentType(_ contentType: ContentType) -> RageRequest {
        self.headers["Content-Type"] = contentType.stringValue()
        return self
    }

    open func authorized(_ authenticator: Authenticator) -> RageRequest {
        self.authenticator = authenticator
        return authorized()
    }

    open func authorized() -> RageRequest {
        if let safeAuthenticator = authenticator {
            return safeAuthenticator.authorizeRequest(self)
        } else {
            preconditionFailure("Can't create authorized request without Authenticator provided")
        }
    }

    open func stub(_ data: Data, mode: StubMode = .immediate) -> RageRequest {
        self.stubData = StubData(data: data, mode: mode)
        return self
    }

    open func stub(_ string: String, mode: StubMode = .immediate) -> RageRequest {
        guard let data = string.data(using: String.Encoding.utf8) else {
            return self
        }
        return self.stub(data, mode: mode)
    }

    open func withErrorHandlers(_ handlers: [ErrorHandler]) -> RageRequest {
        self.errorHandlers = handlers
        return self
    }

    // MARK: Configurations

    open func withTimeoutMillis(_ timeoutMillis: Int) -> RageRequest {
        self.timeoutMillis = timeoutMillis
        return self
    }

    // MARK: Requests

    func createSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        let timeoutSeconds = Double(timeoutMillis) / 1000.0
        configuration.timeoutIntervalForRequest = timeoutSeconds
        configuration.timeoutIntervalForResource = timeoutSeconds

        return URLSession(configuration: configuration)
    }

    func createErrorFromResponse(_ rageResponse: RageResponse) -> RageError {
        if rageResponse.error == nil && rageResponse.data?.count ?? 0 == 0 {
            return RageError(type: .emptyNetworkResponse)
        }
        if rageResponse.error == nil {
            return RageError(type: .http, rageResponse: rageResponse)
        }

        return RageError(type: .raw, rageResponse: rageResponse)
    }

    // MARK: Complex request abstractions

    open func withBody() -> BodyRageRequest {
        return BodyRageRequest(from: self)
    }

    open func multipart() -> MultipartRageRequest {
        return MultipartRageRequest(from: self)
    }

    open func formUrlEncoded() -> FormUrlEncodedRequest {
        return FormUrlEncodedRequest(from: self)
    }

    // MARK: Executing

    open func execute() -> Result<RageResponse, RageError> {
        sendPluginsWillSendRequest()

        let request = rawRequest()

        sendPluginsDidSendRequest(request)

        if let s = getStubData() {
            let rageResponse = RageResponse(request: self, data: s, response: nil, error: nil)
            sendPluginsDidReceiveResponse(rageResponse, rawRequest: request)
            return .success(rageResponse)
        }

        let session = createSession()
        let (data, response, error) = session.syncTask(request)
        let rageResponse = RageResponse(request: self, data: data, response: response, error: error)

        sendPluginsDidReceiveResponse(rageResponse, rawRequest: request)

        if rageResponse.isSuccess() {
            return .success(rageResponse)
        }
        let rageError = createErrorFromResponse(rageResponse)
        var result: Result<RageResponse, RageError> = .failure(rageError)
        for handler in errorHandlers {
            if handler.enabled && handler.canHandleError(rageError) {
                result = handler.handleErrorForRequest(self, result: result)
            }
        }
        return result
    }

    open func enqueue(_ completion: (Result<RageResponse, RageError>) -> ()) {
        DispatchQueue.global(qos: .background).async(execute: {
            let result = self.execute()

            DispatchQueue.main.async(execute: {
                return _ = result
            })
        })
    }

    open func rawRequest() -> URLRequest {
        let url = URLBuilder().fromRequest(self)
        let request = NSMutableURLRequest(url: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpMethod = httpMethod.stringValue()
        return request as URLRequest
    }

    // MARK: Plugins

    fileprivate func sendPluginsWillSendRequest() {
        for plugin in plugins {
            plugin.willSendRequest(self)
        }
    }

    fileprivate func sendPluginsDidSendRequest(_ rawRequest: URLRequest) {
        for plugin in plugins {
            plugin.didSendRequest(self, rawRequest: rawRequest)
        }
    }

    fileprivate func sendPluginsDidReceiveResponse(_ rageResponse: RageResponse,
                                               rawRequest: URLRequest) {
        for plugin in plugins {
            plugin.didReceiveResponse(rageResponse, rawRequest: rawRequest)
        }
    }

    // MARK: Stub

    func isStubbed() -> Bool {
        guard let s = stubData else {
            return false
        }
        switch s.mode {
        case .never:
            return false
        default:
            return true
        }
    }

    fileprivate func getStubData() -> Data? {
        guard let s = stubData else {
            return nil
        }
        switch s.mode {
        case .never:
            return nil
        case .immediate:
            return s.data as Data
        case .delayed(let delayMillis):
            let seconds = Double(delayMillis) / 1000
            Thread.sleep(forTimeInterval: seconds)
            return s.data as Data
        }
    }

}
