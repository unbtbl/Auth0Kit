import JWT

public struct Auth0Token: JWTPayload {
    public let iss: IssuerClaim
    public let sub: SubjectClaim
    public let aud: AudienceClaim
    public let iat: IssuedAtClaim
    public let exp: ExpirationClaim

    public func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
