ObjectMapper
=============================
Install ObjectMapper using CocoaPods.
```ruby
pod 'ObjectMapper', '~> 2.0.0'
```

Then you can use Rage ObjectMapper features. Basically all the same methods you can expect but using `Mappable` objects provided.

## Assuming we have Mappable object `GithubUser` ##
let user = GithubUser(name: "PavelKorolev")

## Request Body ##
```swift
request.withBody()
    .bodyJson(user) // Adds body data to request as JSON string
```

## Stub ##
```swift
request.stub(user) // Adds stub data as JSON string
```

## Execution ##
### Sync ###
```swift
let userResult: Result<GithubUser, RageError> = request.executeObject() // Parse response from JSON string to GithubUser model
let usersResult: Result<[GithubUser], RageError> = request.executeObject() // Works for arrays too
```

### Async ###
Same for async request using `enqueue(_:)` functions
```swift
request.enqueueObject {
    (userResult: Result<GithubUser, RageError>) in
    // Handle result in main thread
}

request.enqueueObject {
    (usersResult: Result<[GithubUser], RageError>) in
    // Handle result in main thread
}
```

### Create Multipart TypedObjects JSON data ###
TypedObject can be created from any Mappable object using `Mappable.typedObject()` function
```swift
let typedObject = user.typedObject() // Creates typed object with mimeType application/json and Data of JSON string serialized with ObjectMapper
```