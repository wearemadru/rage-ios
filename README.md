Rage for iOS
=============================
Network abstraction layer for iOS applications.

## Usage ##
You can check example implementation in RageExample project.

At first you need to create RageClient using builder pattern.
```swift
let client = Rage.builder()
        .withBaseUrl("https://api.github.com")
        .withLogLevel(.Full)
        .build()
```
Then describe your API requests like these
```swift
func getOrganization() -> Observable<String> {
    return client.get("/orgs/{org}")
    .path("org", "gspd-mobi")
    .requestString()
}

func getUser() -> Observable<GithubUser> {
    return client.get("/users/{user}")
    .path("user", "PavelKorolev")
    .requestJson()
}
```
That's it. Compact but powerful.

## Installation (CocoaPods) ##
Add these dependencies to Podfile and `pod install` 
```ruby
pod 'Rage',	'~> 0.1.0'
pod 'RxSwift',	'~> 2.0'
pod 'ObjectMapper', '~>1.3'
```

## Configuration ##
### Client ###
```swift
.withBaseUrl(url: String) // Required. Url to use in all requests made with this client.
.withLogLevel(logLevel: LogLevel) // Changes log level (.None - default, .Medium, .Full).
.withTimeoutMillis(timeoutMillis: Int) // Changes timeout in milliseconds for each request made with this client.
```
### Create requests ###
```swift
// All these methods create request with corresponding HTTP Methods and path
.get(path: String?) 
.post(path: String?)
.put(path: String?)
.delete(path: String?) 
.head(path: String?)
.customMethod(method: String, path: String?) // Use this method when there is no needed method in predefined.
```
### Requests ###
```swift
.query<T>(key: String, _ value: T?) // Adds query parameter to current request.
.path<T>(key: String, _ value: T) // Adds path parameter to current request. Path parameter value replaces "{key}" substring in method path.
.bodyData(value: NSData) // Adds body in NSData format to current request.
.bodyString(value: String) // Adds body in String format to current request.
.bodyJson(value: Mappable) // Adds body in JSON format mapped from value object.
.header(key: String, _ value: String) // Adds header to current request.

.withTimeoutMillis(timeoutMillis: Int) // Used to set timeout in milliseconds for this single request.
```
License
-------
    The MIT License (MIT)

    Copyright (c) 2016 gspd.mobi

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
-------