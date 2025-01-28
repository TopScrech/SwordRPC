public struct JoinRequest: Decodable {
    public let avatar: String
    public let discriminator: String
    public let userId: String
    public let username: String
    
    enum CodingKeys: String, CodingKey {
        case avatar,
             discriminator,
             userId = "id",
             username
    }
}
