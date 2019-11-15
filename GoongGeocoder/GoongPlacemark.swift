
import CoreLocation
//MARK: - Placemark
/**
 A `Placemark` object represents a geocoder result. A placemark associates identifiers, geographic data, and contact information with a particular latitude and longitude. It is possible to explicitly create a placemark object from another placemark object; however, placemark objects are generally created for you via the `Geocoder.geocode(_:completionHandler:)` method.
 */
@objc(GoongPlacemark)
open class Placemark: NSObject, Codable {
    typealias geometryDictionary = [String : [String : CLLocationDegrees]]

    private enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case name = "name"
        case formattedAddress = "formatted_address"
        case coordinate = "geometry"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placeID = ""// try container.decode(String.self, forKey: .placeID)
        name = try container.decode(String.self, forKey: .name)
        formattedAddress = try container.decodeIfPresent(String.self, forKey: .formattedAddress)
        
        if let coordinates = try container.decodeIfPresent(geometryDictionary.self, forKey: .coordinate) {
            let coordinate = CLLocationCoordinate2D(json: coordinates)
            location = CLLocation(coordinate: coordinate)
        }
        
        
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(placeID, forKey: .placeID)
        try container.encode(name, forKey: .name)
        try container.encode(formattedAddress, forKey: .formattedAddress)
        if let location = location {
            try container.encode([location.coordinate.longitude, location.coordinate.latitude], forKey: .coordinate)
        }
    }
    
    #if swift(>=4.2)
    #else
    @objc open override var hashValue: Int {
        return placeID.hashValue
    }
    #endif
    
    @objc open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Placemark {
            return placeID == object.placeID
        }
        return false
    }
    
    // MARK: Identifying the Placemark
    
    @objc open override var description: String {
        return name
    }
    
    /**
     A string that uniquely identifies the feature.
     
     The identifier of place
     */
    fileprivate var placeID: String
    
    
    /**
     The common name of the placemark.
     
     If the placemark represents an address, the value of this property consists of only the street address, not the full address. Otherwise, if the placemark represents a point of interest or other place, the value of this property consists of only the common name, not the names of any containing administrative areas.
     */
    @objc open var name: String
    
    @objc open var formattedAddress: String?
    
    
    // MARK: Accessing Location Data
    
    /**
     The placemark’s geographic center.
     */
    @objc open var location: CLLocation?
    

}
@objcMembers public class PlaceDetailResult: NSObject, Codable {
    public let placemark: Placemark?
    public let status: String?
    enum CodingKeys: String, CodingKey {
        case placemark = "result"
        case status = "status"
    }
    public init(status: String?, placemark: Placemark?) {
          self.status = status
          self.placemark = placemark
      }
}
// MARK: - GeocodeResult
@objcMembers public class GeocodeResult: NSObject, Codable {
    public let status: String?
    public let predictions: [Prediction]?
    public let placemarks: [Placemark]?
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case predictions = "predictions"
        case placemarks = "results"
    }

    public init(status: String?, predictions: [Prediction]?, placemarks: [Placemark]?) {
        self.status = status
        self.placemarks = placemarks
        self.predictions = predictions
    }
}

// MARK: - Prediction
@objcMembers public class Prediction: NSObject, Codable {
    public let predictionDescription: String?
    public let matchedSubstrings: [JSONAny]?
    public let placeID: String?
    public let structuredFormatting: StructuredFormatting?
    public let terms: [JSONAny]?
    public let types: [String]?
    public let hasChildren: Bool?
    public let children: [Child]?

    enum CodingKeys: String, CodingKey {
        case predictionDescription = "description"
        case matchedSubstrings = "matched_substrings"
        case placeID = "place_id"
        case structuredFormatting = "structured_formatting"
        case terms = "terms"
        case types = "types"
        case hasChildren = "has_children"
        case children = "children"
    }

    public init(predictionDescription: String?, matchedSubstrings: [JSONAny]?, placeID: String?, structuredFormatting: StructuredFormatting?, terms: [JSONAny]?, types: [String]?, hasChildren: Bool?, children: [Child]?) {
        self.predictionDescription = predictionDescription
        self.matchedSubstrings = matchedSubstrings
        self.placeID = placeID
        self.structuredFormatting = structuredFormatting
        self.terms = terms
        self.types = types
        self.hasChildren = hasChildren
        self.children = children
    }
}

// MARK: - Child
@objcMembers public class Child: NSObject, Codable {
    public let pid: String?
    public let content: String?
    public let address: String?
    public let lon: Double?
    public let lat: Double?

    enum CodingKeys: String, CodingKey {
        case pid = "pid"
        case content = "content"
        case address = "address"
        case lon = "lon"
        case lat = "lat"
    }

    public init(pid: String?, content: String?, address: String?, lon: Double?, lat: Double?) {
        self.pid = pid
        self.content = content
        self.address = address
        self.lon = lon
        self.lat = lat
    }
}

// MARK: - StructuredFormatting
@objcMembers public class StructuredFormatting: NSObject, Codable {
    public let mainText: String?
    public let secondaryText: String?

    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }

    public init(mainText: String?, secondaryText: String?) {
        self.mainText = mainText
        self.secondaryText = secondaryText
    }
}

// MARK: - Encode/decode helpers

@objcMembers public class JSONNull: NSObject, Codable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    override public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

@objcMembers public class JSONAny: NSObject, Codable {

    public let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
