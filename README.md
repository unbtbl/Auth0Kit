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

## Example Auth0 setup with Vapor

To use Auth0Kit, first, import the library and create an `Auth0` instance:

```swift
import Vapor
import Auth0Kit
```

Next, ensure you have the required environment variables for your Auth0 issuer, audience, and signer.
* If your Auth0 application uses HS256, set AUTH0_SECRET to your shared secret.
* If it uses RS256, set AUTH0_CERT (inline certificate) or AUTH0_CERT_PATH (certificate file).

| Variable             | Purpose                                                   | Required if                                                                                                   | Example Value                                     |
|----------------------|-----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|---------------------------------------------------|
| **AUTH0_AUDIENCE**   | Specifies the audience of the Auth0 application           | **Always** needed (both HS256 and RS256)                                                                      | `my-api-identifier`                               |
| **AUTH0_ISSUER**     | The issuer (tenant domain)                                | **Always** needed (both HS256 and RS256)                                                                      | `https://my-tenant.auth0.com/`                    |
| **AUTH0_SECRET**     | Shared secret                                             | If using **HS256**                                                                                            | `my-auth0-hs256-secret`                           |
| **AUTH0_CERT**       | Public certificate string for RS256 (PEM format)          | If using **RS256**, you can supply an **inline** PEM string here (instead of a file path)                     | `-----BEGIN PUBLIC KEY-----\n...`                 |
| **AUTH0_CERT_PATH**  | Public certificate file path for RS256 (PEM file path)    | If using **RS256**, you can supply a **file path** to your PEM certificate (instead of providing inline text) | `/path/to/my/public.cert`                         |

You can load these variables using Vapor's Environment. Here's a quick example to get started:
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
