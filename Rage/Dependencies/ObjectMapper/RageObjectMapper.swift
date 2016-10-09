import Foundation
import ObjectMapper
import Result

extension BodyRageRequest {

    static let wrongHttpMethodForBodyErrorMessage = "Can't add body to request with such HttpMethod"

    public func bodyJson(_ value: Mappable) -> BodyRageRequest {
        if !httpMethod.hasBody() {
            preconditionFailure(BodyRageRequest.wrongHttpMethodForBodyErrorMessage)
        }

        guard let json = value.toJSONString() else {
            return self
        }
        _ = contentType(.json)
        return bodyString(json)
    }

}

extension RageRequest {

    static let jsonParsingErrorMessage = "Couldn't parse object from JSON"

    public func stub(_ value: Mappable, mode: StubMode = .immediate) -> RageRequest {
        guard let json = value.toJSONString() else {
            return self
        }
        return self.stub(json, mode: mode)
    }

    open func executeObject<T: Mappable>() -> Result<T, RageError> {
        let result = self.execute()

        switch result {
        case .success(let response):
            let parsedObject: T? = response.data?.parseJson()
            if let resultObject = parsedObject {
                return .success(resultObject)
            } else {
                return .failure(RageError(type: .configuration,
                                          message: RageRequest.jsonParsingErrorMessage))
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    open func executeObject<T: Mappable>() -> Result<[T], RageError> {
        let result = self.execute()

        switch result {
        case .success(let response):
            let parsedObject: [T]? = response.data?.parseJsonArray()
            if let resultObject = parsedObject {
                return .success(resultObject)
            } else {
                return .failure(RageError(type: .configuration,
                                          message: RageRequest.jsonParsingErrorMessage))
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    open func enqueueObject<T: Mappable>(_ completion: @escaping (Result<T, RageError>) -> ()) {
        DispatchQueue.global(qos: .background).async(execute: {
            let result: Result<T, RageError> = self.executeObject()

            DispatchQueue.main.async(execute: {
                completion(result)
            })
        })
    }

    open func enqueueObject<T: Mappable>(_ completion: @escaping (Result<[T], RageError>) -> ()) {
        DispatchQueue.global(qos: .background).async(execute: {
            let result: Result<[T], RageError> = self.executeObject()

            DispatchQueue.main.async(execute: {
                completion(result)
            })
        })
    }


}

extension Data {

    func parseJson<T: Mappable>() -> T? {
        let resultString = String(data: self, encoding: String.Encoding.utf8)!
        guard let b = Mapper<T>().map(JSONString: resultString) else {
            return nil
        }
        return b
    }

    func parseJsonArray<T: Mappable>() -> [T]? {
        let resultString = String(data: self, encoding: String.Encoding.utf8)!
        guard let b = Mapper<T>().mapArray(JSONString: resultString) else {
            return nil
        }
        return b
    }

}

extension Mappable {

    func typedObject() -> TypedObject? {
        guard let json = toJSONString() else {
            return nil
        }
        guard let data = json.data(using: String.Encoding.utf8) else {
            return nil
        }
        return TypedObject(data, mimeType: "application/json")
    }

}
