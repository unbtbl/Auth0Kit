import NIOHTTP1
import AsyncHTTPClient
import Foundation

struct HTTPError: Error {
    let code: HTTPResponseStatus
    let reason: String
}

extension HTTPClientResponse {
    func assertSuccessful() async throws {
        guard status.code >= 200 && status.code < 300 else {
            var body = try await body.collect(upTo: 1024)
            let reason = body.readString(length: body.readableBytes) ?? ""
            throw HTTPError(code: status, reason: reason)
        }
    }

    func decode<D: Decodable>(as type: D.Type = D.self) async throws -> D {
        let body = try await self.body.collect(upTo: Int(UInt16.max))
        return try JSONDecoder
            .custom(keys: .convertFromSnakeCase)
            .decode(D.self, from: body)
    }
}
