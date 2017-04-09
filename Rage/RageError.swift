import Foundation

public enum RageErrorType {

    case raw
    case emptyNetworkResponse
    case configuration
    case http
    case networkError

}

open class RageError: Error {

    open let type: RageErrorType
    open var rageResponse: RageResponse?
    open var message: String?

    init(type: RageErrorType, rageResponse: RageResponse?) {
        self.rageResponse = rageResponse
        self.type = type
    }

    init(type: RageErrorType, message: String? = nil) {
        self.type = type
        self.message = message
    }

}

extension RageError {

    public func statusCode() -> Int? {
        return rageResponse?.statusCode()
    }

}

extension RageError {

    convenience init(response: RageResponse) {
        if response.error == nil {
            self.init(type: .http, rageResponse: response)
            return
        }

        self.init(type: .raw, rageResponse: response)
    }

}
