import NIO
import JWT
import AsyncHTTPClient

public struct Auth0 {
    let client: HTTPClient
    let issuer: String
    let audience: String
    let signer: JWTSigner
    let allocator: ByteBufferAllocator

    public init(client: HTTPClient, issuer: String, audience: String, signer: JWTSigner, allocator: ByteBufferAllocator = .init()) {
        self.client = client
        self.issuer = issuer
        self.audience = audience
        self.signer = signer
        self.allocator = allocator
    }

    public func verifyToken(_ token: String) throws -> Auth0Token {
        let token: Auth0Token = try signer.verify(token)
        try token.aud.verifyIntendedAudience(includes: audience)
        return token
    }
}
