import MapKit

class IdentifiablePointAnnotation: MKPointAnnotation, Identifiable, Codable {
    let id: UUID
    
    enum CodingKeys: String, CodingKey {
            case id, coordinate, title, subtitle
        }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        super.init()
        coordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
        title = try container.decode(String?.self, forKey: .title)
        subtitle = try container.decode(String?.self, forKey: .subtitle)
    }
    
    override init() {
        self.id = UUID()
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
    }
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(CLLocationDegrees.self)
        let longitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}
