import Foundation

public struct RichPresence: Encodable {
    public var assets = Assets()
    public var details = ""
    public var instance = true
    public var party = Party()
    public var secrets = Secrets()
    public var state = ""
    public var timestamps = Timestamps()
    
    public init() {
        
    }
}

extension RichPresence {
    public struct Timestamps: Encodable {
        public var end: Date? = nil
        public var start: Date? = nil
    }
    
    public struct Assets: Encodable {
        public var largeImage: String? = nil
        public var largeText: String? = nil
        public var smallImage: String? = nil
        public var smallText: String? = nil
        
        enum CodingKeys: String, CodingKey {
            case largeImage = "large_image",
                 largeText = "large_text",
                 smallImage = "small_image",
                 smallText = "small_text"
        }
    }
    
    public struct Party: Encodable {
        public var id: String? = nil
        public var max: Int? = nil
        public var size: Int? = nil
        
        enum CodingKeys: String, CodingKey {
            case id
            case size
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(id, forKey: .id)
            
            guard let max, let size else {
                return
            }
            
            try container.encode([size, max], forKey: .size)
        }
    }
    
    public struct Secrets: Encodable {
        public var join: String? = nil
        public var match: String? = nil
        public var spectate: String? = nil
    }
}
