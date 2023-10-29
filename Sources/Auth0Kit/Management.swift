import AsyncHTTPClient
import Foundation
import Vapor

extension Auth0 {
    public struct Management {
        let auth0: Auth0
        let managementApi: String
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
                        "audience": managementApi
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
                    "\(managementApi)users/\(id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id)"
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
            var request = HTTPClientRequest(url: "\(managementApi)\(path)")
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

    /// Creates a new `Management` instance, allowing you to manage users, roles, and permissions.
    /// - Parameters:
    /// - clientId: The client ID of the application you want to manage.
    /// - clientSecret: The client secret of the application you want to manage.
    /// - managementApi: The management API's url, including `/api/v2/` at the end, as found in Auth0
    public func management(clientId: String, clientSecret: String, managementApi: String) -> Management {
        return Management(
            auth0: self,
            managementApi: managementApi.last == "/" ? managementApi : managementApi.appending("/"),
            clientId: clientId,
            clientSecret: clientSecret
        )
    }

    /// Creates a new `Management` instance, allowing you to manage users, roles, and permissions.
    /// - Parameters:
    /// - clientId: The client ID of the application you want to manage.
    /// - clientSecret: The client secret of the application you want to manage.
    public func management(clientId: String, clientSecret: String) -> Management {
        let host = issuer.last == "/" ? issuer : issuer.appending("/")
        return Management(
            auth0: self,
            managementApi: host + "api/v2/",
            clientId: clientId,
            clientSecret: clientSecret
        )
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