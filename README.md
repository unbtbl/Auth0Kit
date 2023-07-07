![Auth0Kit](Docs/Assets/Banner.png)

Auth0Kit is a Swift library for communicating with the [Auth0](https://auth0.com) API. It provides tools to help you validate Auth0 tokens, and authorize requests sent from your website or apps.

## Setup

To begin, you'll need to depend on this repository:

```swift
.package(url: "https://github.com/unbtbl/Auth0Kit.git", from: "0.1.0"),
```

Add this dependency to your target(s):

```swift
.target(
    name: "MyTarget",
    dependencies: [
        ...,
        .package(name: "Auth0Kit", package: "Auth0Kit"),
    ]
)
```

## Setting up Auth0 with Vapor

To use Auth0Kit, first, import the library and create an `Auth0` instance:

```swift
import Vapor
import Auth0Kit
```

Make sure you have the Auth0 issuer, audience and signer. You can read this using Vapor's Environment. The following snippet gets you started with Vapor quickly:

```swift
guard let auth0Audience = Environment.get("AUTH0_AUDIENCE") else {
    app.logger.critical("Missing `AUTH0_AUDIENCE` environment variable")
    exit(1)
}

guard let auth0Issuer = Environment.get("AUTH0_ISSUER") else {
    app.logger.critical("Missing `AUTH0_ISSUER` environment variable")
    exit(1)
}

let auth0: Auth0
if let auth0Secret = Environment.get("AUTH0_SECRET") {
    auth0 = Auth0(
        client: app.http.client.shared,
        issuer: auth0Issuer,
        audience: auth0Audience,
        signer: .hs256(key: auth0Secret)
    )
} else if let auth0Cert = Environment.get("AUTH0_CERT") {
    auth0 = try Auth0(
        client: app.http.client.shared,
        issuer: auth0Issuer,
        audience: auth0Audience,
        signer: .rs256(key: .certificate(pem: auth0Cert))
    )
} else if let auth0CertPath = Environment.get("AUTH0_CERT_PATH") {
    auth0 = try Auth0(
        client: app.http.client.shared,
        issuer: auth0Issuer,
        audience: auth0Audience,
        signer: .rs256(key: .certificate(pem: String(contentsOfFile: auth0CertPath)))
    )
} else {
    app.logger.critical("Missing `AUTH0_SECRET` or `AUTH0_CERT` environment variable")
    exit(1)
}
```

## Protecting Routes

Using the `Auth0Middleware`, you can validate Bearer tokens in your requests. If the token is valid, it will be stored in the Request's storage.

The middelware accepts two arguments:
- `auth0` is the Auth0 instance created in the previous setup code
- `requiresAuthentication` will require a token when set to `true`. If this is `false`, routes can be called by unauthenticated users, however any token provided will be validated.

`requiresAuthentication` should be `true` if you're unsure what to do, it ensures the user is logged in. `false` can be helpful if an API should be (partially) accessible by users without an account.

```swift
let auth0Middleware Auth0Middleware(
    auth0: auth0,
    requiresAuthentication: true
)
let authenticated = unauthenticated.grouped(auth0Middleware)
```

Once a route with this middleware installed gets a request, you can access the validated token using the following code:

```swift
authenticated.get("items") { req in
    let token = try req.requireToken()
    // TODO: grab & return items
}
``` 

## Tokens

Once you have a token, you know that this user has registered with Auth0. You can use the management APIs to access their accont, or store the information separately in your database.

The user's unique ID, as provided by Auth0, can be found in `token.sub`. The rest of properties of the token are not very interesting in general.

## Management APIs

Your auth0 instance has a `.management(..)` method to access the Management APIs. You'll need to provide additional information here to communicate with the management API.

Currently, the only supported management API is getting a machine user token using `.getToken()`. We're open to additional PRs for more features as needed!
