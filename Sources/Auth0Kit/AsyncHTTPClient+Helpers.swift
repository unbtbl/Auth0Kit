import NIOHTTP1
import AsyncHTTPClient

struct HTTPError: Error {
    let code: HTTPResponseStatus
}

extension HTTPClientResponse {
    func assertSuccessful() throws {
        guard status.code >= 200 && status.code < 300 else {
            throw HTTPError(code: status)
        }
    }
}
