import Vapor

public struct Auth0Middleware: AsyncMiddleware {
    let auth0: Auth0
    let requiresAuthentication: Bool

    public init(auth0: Auth0, requiresAuthentication: Bool) {
        self.auth0 = auth0
        self.requiresAuthentication = requiresAuthentication
    }

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let token = request.headers.bearerAuthorization?.token {
            let jwt = try auth0.verifyToken(token)
            request.storage[Auth0TokenStorageKey.self] = jwt
        } else if requiresAuthentication {
            throw Abort(.unauthorized, reason: "You're not authenticated.")
        }

        return try await next.respond(to: request)
    }
}

extension Request {
    public func requireToken() throws -> Auth0Token {
        guard let token = storage[Auth0TokenStorageKey.self] else {
            throw Abort(.unauthorized, reason: "You're not authenticated.")
        }

        return token
    }
}

struct Auth0TokenStorageKey: StorageKey {
    typealias Value = Auth0Token
}
