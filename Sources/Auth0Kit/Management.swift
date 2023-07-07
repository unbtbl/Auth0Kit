import Vapor
import Foundation
import AsyncHTTPClient

extension Auth0 {
    public struct Management {
        let auth0: Auth0
        let clientId: String
        let clientSecret: String

        public func getToken() async throws -> String {
            var request = HTTPClientRequest(url: "\(auth0.issuer)oauth/token")
            request.method = .POST
            request.headers.contentType = .json
            request.body = try .bytes(JSONEncoder().encodeAsByteBuffer([
                "grant_type": "client_credentials",
                "client_id": clientId,
                "client_secret": clientSecret,
                "audience": auth0.audience
            ], allocator: auth0.allocator))
            let response = try await auth0.client.execute(request, timeout: .seconds(15))
            try response.assertSuccessful()
            let body = try await response.body.collect(upTo: Int(UInt16.max))

            return try JSONDecoder
                .custom(keys: .convertFromSnakeCase)
                .decode(Auth0TokenResponse.self, from: body)
                .accessToken
        }
    }

    public func management(clientId: String, clientSecret: String) -> Management {
        return Management(auth0: self, clientId: clientId, clientSecret: clientSecret)
    }
}

struct Auth0TokenResponse: Codable {
    let accessToken: String
}
