import AsyncHTTPClient
import Foundation
import Vapor

extension Auth0 {
    public struct Management {
        let auth0: Auth0
        let clientId: String
        let clientSecret: String

        public func getToken() async throws -> String {
            var request = HTTPClientRequest(url: "\(auth0.issuer)oauth/token")
            request.method = .POST
            request.headers.contentType = .json
            request.body = try .bytes(
                JSONEncoder().encodeAsByteBuffer(
                    [
                        "grant_type": "client_credentials",
                        "client_id": clientId,
                        "client_secret": clientSecret,
                        "audience": auth0.issuer + "api/v2/",
                    ],
                    allocator: auth0.allocator
                )
            )
            let response = try await auth0.client.execute(request, timeout: .seconds(15))
            try await response.assertSuccessful()

            return try await response.decode(as: Auth0TokenResponse.self).accessToken
        }

        public func deleteUser(byId id: String) async throws {
            let token = try await getToken()
            var request = HTTPClientRequest(
                url:
                    "\(auth0.issuer)api/v2/users/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)"
            )
            request.method = .DELETE
            request.headers.bearerAuthorization = .init(token: token)

            let response = try await auth0.client.execute(request, timeout: .seconds(15))
            try await response.assertSuccessful()
        }

        public func createRole(named name: String, description: String) async throws -> Auth0Role {
            let response = try await send(
                .POST,
                to: "roles",
                body: [
                    "name": name,
                    "description": description,
                ]
            )

            return try await response.decode(as: Auth0Role.self)
        }

        public func getRoles() async throws -> [Auth0Role] {
            let token = try await getToken()
            var request = HTTPClientRequest(url: "\(auth0.issuer)api/v2/roles")
            request.method = .GET
            request.headers.bearerAuthorization = .init(token: token)
            let response = try await auth0.client.execute(request, timeout: .seconds(15))
            try await response.assertSuccessful()

            do {
                return try await response.decode(as: [Auth0Role].self)
            } catch {
                return try await response.decode(as: Roles.self).roles
            }
        }

        public func addScopes(_ scopes: [Scope], toAPI id: String) async throws {
            try await send(
                .PATCH,
                to: "resource-servers/\(id)",
                body: [
                    "scopes": scopes
                ]
            )
        }

        public func addPermissions(
            _ permissions: [Permission],
            toRole roleId: String
        ) async throws {
            try await send(
                .POST,
                to: "roles/\(roleId)/permissions",
                body: [
                    "permissions": permissions
                ]
            )
        }

        @discardableResult
        private func send<E: Encodable>(
            _ method: HTTPMethod,
            to path: String,
            body: E
        ) async throws -> HTTPClientResponse {
            let token = try await getToken()
            var request = HTTPClientRequest(url: "\(auth0.issuer)api/v2/\(path)")
            request.method = method
            request.headers.bearerAuthorization = .init(token: token)
            request.headers.contentType = .json
            request.body = .bytes(
                try JSONEncoder.custom(keys: .convertToSnakeCase).encodeAsByteBuffer(
                    body,
                    allocator: auth0.allocator
                )
            )

            let response = try await auth0.client.execute(request, timeout: .seconds(15))
            try await response.assertSuccessful()
            return response
        }
    }

    public func management(clientId: String, clientSecret: String) -> Management {
        return Management(auth0: self, clientId: clientId, clientSecret: clientSecret)
    }
}

public struct Scope: Codable {
    public let value: String
    public let description: String

    public init(value: String, description: String) {
        self.value = value
        self.description = description
    }
}

public struct Permission: Codable {
    public var resourceServerIdentifier: String
    public var permissionName: String

    public init(resourceServerIdentifier: String, permissionName: String) {
        self.resourceServerIdentifier = resourceServerIdentifier
        self.permissionName = permissionName
    }
}

struct Auth0TokenResponse: Codable {
    let accessToken: String
}

public struct Auth0Role: Codable {
    public let id: String
    public let name: String
    public let description: String
}

struct Roles: Codable {
    let roles: [Auth0Role]
}