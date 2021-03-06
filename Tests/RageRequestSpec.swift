import Foundation
import Quick
import Nimble

class RageRequestSpec: QuickSpec {

    override func spec() {
        describe("rage request") {

            var baseUrl: String!
            var method: HttpMethod!
            var request: RageRequest!
            beforeEach {
                baseUrl = "http://example.com"
                method = HttpMethod.get
                request = RageRequest(httpMethod: method, baseUrl: baseUrl)
            }

            describe("customization") {
                it("can set url") {
                    _ = request.url("http://example2.com")
                    expect(request.baseUrl).to(equal("http://example2.com"))
                }

                it("can add 1 query parameter") {
                    expect(request.queryParameters.count).to(equal(0))
                    _ = request.query("name", "Paul")
                    expect(request.queryParameters.count).to(equal(1))
                    expect(request.queryParameters["name"]?.string(key: "name")).to(equal("name=Paul"))
                }

                it("can add 2 query parameters") {
                    expect(request.queryParameters.count).to(equal(0))
                    _ = request.query("name", "Paul")
                        .query("age", 24)
                    expect(request.queryParameters.count).to(equal(2))
                    expect(request.queryParameters["name"]?.string(key: "name")).to(equal("name=Paul"))
                    expect(request.queryParameters["age"]?.string(key: "age")).to(equal("age=24"))
                }

                it("can add 2 query parameters with dictionary") {
                    expect(request.queryParameters.count).to(equal(0))
                    _ = request.queryDictionary(["name": "Paul", "age": "24"])
                    expect(request.queryParameters.count).to(equal(2))
                    expect(request.queryParameters["name"]?.string(key: "name")).to(equal("name=Paul"))
                    expect(request.queryParameters["age"]?.string(key: "age")).to(equal("age=24"))
                }

                it("can add 1 path parameter") {
                    expect(request.pathParameters.count).to(equal(0))
                    _ = request.path("name", "Paul")
                    expect(request.pathParameters.count).to(equal(1))
                    expect(request.pathParameters["name"]).to(equal("Paul"))
                }

                it("can add 2 path parameters") {
                    expect(request.pathParameters.count).to(equal(0))
                    _ = request.path("name", "Paul")
                        .path("age", 24)
                    expect(request.pathParameters.count).to(equal(2))
                    expect(request.pathParameters["name"]).to(equal("Paul"))
                    expect(request.pathParameters["age"]).to(equal("24"))
                }

                it("can add 1 header") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.header("Authorization", "Basic abcd")
                    expect(request.headers.count).to(equal(1))
                    expect(request.headers["Authorization"]).to(equal("Basic abcd"))
                }

                it("can add 2 header") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.header("Authorization", "Basic abcd")
                        .header("Api-Version", 5)
                    expect(request.headers.count).to(equal(2))
                    expect(request.headers["Authorization"]).to(equal("Basic abcd"))
                    expect(request.headers["Api-Version"]).to(equal("5"))
                }

                it("can remove header") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.header("Authorization", "Basic abcd")
                        .header("Api-Version", 5)
                    expect(request.headers.count).to(equal(2))
                    expect(request.headers["Authorization"]).to(equal("Basic abcd"))
                    expect(request.headers["Api-Version"]).to(equal("5"))
                    let newVersion: Int? = nil
                    _ = request.header("Api-Version", newVersion)
                    expect(request.headers.count).to(equal(1))
                    expect(request.headers["Api-Version"]).to(beNil())
                }

                it("can add 2 headers with dictionary") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.headerDictionary(["Authorization": "Basic abcd", "Api-Version": "5"])
                    expect(request.headers.count).to(equal(2))
                    expect(request.headers["Authorization"]).to(equal("Basic abcd"))
                    expect(request.headers["Api-Version"]).to(equal("5"))
                    let newVersion: Int? = nil
                    _ = request.header("Api-Version", newVersion)
                    expect(request.headers.count).to(equal(1))
                    expect(request.headers["Api-Version"]).to(beNil())
                }

                it("can add 2 headers with dictionary and remove 1") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.headerDictionary(["Authorization": "Basic abcd", "Api-Version": "5"])
                    expect(request.headers.count).to(equal(2))
                    expect(request.headers["Authorization"]).to(equal("Basic abcd"))
                    expect(request.headers["Api-Version"]).to(equal("5"))
                    let newVersion: Int? = nil
                    _ = request.headerDictionary(["Api-Version": newVersion])
                    expect(request.headers.count).to(equal(1))
                    expect(request.headers["Api-Version"]).to(beNil())
                }

                it("can set content type") {
                    expect(request.headers.count).to(equal(0))
                    _ = request.contentType(.json)
                    expect(request.headers["Content-Type"]).to(equal("application/json"))
                    _ = request.contentType(.urlEncoded)
                    expect(request.headers["Content-Type"]).to(equal("application/x-www-form-urlencoded"))
                    _ = request.contentType(.multipartFormData)
                    expect(request.headers["Content-Type"]).to(equal("multipart/form-data"))
                    _ = request.contentType(.custom("image/png"))
                    expect(request.headers["Content-Type"]).to(equal("image/png"))
                }

                it("request is authorized when it authorized with authenticator") {
                    let auth = TestAuthenticator()
                    expect(request.isAuthorized).to(equal(false))
                    request = request.authorized(with: auth)
                    expect(request.isAuthorized).to(equal(true))
                }
            }

            describe("stub") {
                it("can be stubbed with data") {
                    expect(request.stubData).to(beNil())
                    let stubString = "{}"
                    let stubData = stubString.data(using: String.Encoding.utf8)!
                    _ = request.stub(stubData)
                    expect(request.stubData).toNot(beNil())
                    expect(String(data: request.stubData!.data, encoding: String.Encoding.utf8)).to(equal("{}"))
                    expect(request.stubData!.mode).to(equal(StubMode.immediate))
                }

                it("can be stubbed with string") {
                    expect(request.stubData).to(beNil())
                    let stubString = "{}"
                    _ = request.stub(stubString)
                    expect(request.stubData).toNot(beNil())
                    expect(String(data: request.stubData!.data, encoding: String.Encoding.utf8)).to(equal("{}"))
                    expect(request.stubData!.mode).to(equal(StubMode.immediate))
                }

                it("can be stubbed with never stub mode") {
                    expect(request.stubData).to(beNil())
                    let stubString = "{}"
                    _ = request.stub(stubString, mode: .never)
                    expect(request.stubData).toNot(beNil())
                    expect(String(data: request.stubData!.data, encoding: String.Encoding.utf8)).to(equal("{}"))
                    expect(request.stubData!.mode).to(equal(StubMode.never))
                }

                it("can be stubbed with delayed stub mode") {
                    expect(request.stubData).to(beNil())
                    let stubString = "{}"
                    _ = request.stub(stubString, mode: .delayed(2014))
                    expect(request.stubData).toNot(beNil())
                    expect(String(data: request.stubData!.data, encoding: String.Encoding.utf8)).to(equal("{}"))
                    expect(request.stubData!.mode).to(equal(StubMode.delayed(2014)))
                    expect(request.stubData!.mode).toNot(equal(StubMode.delayed(1000)))
                }
                it("can get is stubbed") {
                    expect(request.stubData).to(beNil())
                    expect(request.isStubbed()).to(equal(false))
                    _ = request.stub("{}", mode: .never)
                    expect(request.isStubbed()).to(equal(false))
                    _ = request.stub("{}", mode: .delayed(0))
                    expect(request.isStubbed()).to(equal(true))
                    _ = request.stub("{}", mode: .immediate)
                    expect(request.isStubbed()).to(equal(true))
                }
                it("can get stub data") {
                    expect(request.stubData).to(beNil())
                    expect(request.getStubData()).to(beNil())
                    _ = request.stub("{}", mode: .never)
                    expect(request.getStubData()).to(beNil())
                    _ = request.stub("{}", mode: .delayed(0))
                    expect(request.getStubData()).to(equal("{}".utf8Data()))
                    _ = request.stub("{}", mode: .immediate)
                    expect(request.getStubData()).to(equal("{}".utf8Data()))
                }
            }

            describe("execute") {
                it("can be done sync for stub") {
                    _ = request.stub("{}".utf8Data()!)
                    let result = request.execute()
                    switch result {
                    case .success(let response):
                        let parsedObject: String? = response.data?.utf8String()
                        expect(parsedObject).to(equal("{}"))
                    default:
                        break
                    }
                }

                it("can be done async for stub") {
                    _ = request.stub("{}".utf8Data()!)
                    var parsedObject: String?
                    request.enqueue { result in
                        switch result {
                        case .success(let response):
                            parsedObject = response.data?.utf8String()
                        default:
                            break
                        }
                    }
                    expect(parsedObject).toEventually(equal("{}"))
                }

            }

            describe("plugins") {
                let url = URL(string: "http://example.com")!
                let urlRequest = URLRequest(url: url)
                it("send plugins did send request called") {
                    let plugin1 = TestIncrementPlugin()
                    let plugin2 = TestIncrementPlugin()
                    request.plugins = [plugin1, plugin2]
                    expect(plugin1.didSendRequestCounter).to(equal(0))
                    expect(plugin2.didSendRequestCounter).to(equal(0))
                    request.sendPluginsDidSendRequest(urlRequest)
                    expect(plugin1.didSendRequestCounter).to(equal(1))
                    expect(plugin2.didSendRequestCounter).to(equal(1))
                }
                it("send plugins did receive response called") {
                    let plugin1 = TestIncrementPlugin()
                    let plugin2 = TestIncrementPlugin()
                    request.plugins = [plugin1, plugin2]
                    let response = RageResponse(request: request, data: nil, response: nil, error: nil)
                    expect(plugin1.didReceiveResponseCounter).to(equal(0))
                    expect(plugin2.didReceiveResponseCounter).to(equal(0))
                    request.sendPluginsDidReceiveResponse(response, rawRequest: urlRequest)
                    expect(plugin1.didReceiveResponseCounter).to(equal(1))
                    expect(plugin2.didReceiveResponseCounter).to(equal(1))
                }
                it("send plugins will send request") {
                    let plugin1 = TestIncrementPlugin()
                    let plugin2 = TestIncrementPlugin()
                    request.plugins = [plugin1, plugin2]
                    expect(plugin1.willSendRequestCounter).to(equal(0))
                    expect(plugin2.willSendRequestCounter).to(equal(0))
                    request.sendPluginsWillSendRequest()
                    expect(plugin1.willSendRequestCounter).to(equal(1))
                    expect(plugin2.willSendRequestCounter).to(equal(1))
                }
            }
        }
    }
}
