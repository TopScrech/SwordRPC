public struct JoinRequest: Decodable {
    let avatar: String
    let discriminator: String
    let userId: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case avatar,
             discriminator,
             userId = "id",
             username
    }
}
