import CoreLocation
/**
 A structure that specifies the criteria for results returned by the Goong Geocoding API.
 
 You do not create instances of `GeocodeOptions` directly. Instead, you create instances of `ForwardGeocodeOptions` and `ReverseGeocodeOptions`, depending on the kind of geocoding you want to perform:
 
 - _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use a `ForwardGeocodeOptions` object.
 - _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use a `ReverseGeocodeOptions` object.
 
 Pass an instance of either class into the `Geocoder.geocode(_:completionHandler:)` method.
 */
@objc(GoongGeocodeOptions)
open class GeocodeOptions: NSObject {
    // MARK: Specifying the Search Criteria
    
    /**
     A location to use as a hint when looking up the specified address.
     
     This property prioritizes results that are close to a specific location, which is typically the user’s current location. If the value of this property is `nil` – which it is by default – no specific location is prioritized.
     */
    @objc open var focalLocation: CLLocation?
    /**
     Distance round from your location by kilometers, required if your use location params
     */
    @objc open var radius: Int = 2500
    /**
     Limit the number of results returned. For forward geocoding, the default is `5` . For reverse geocoding, the default is `1`.
     */
    @objc public var maximumResultCount: UInt

    // MARK: Specifying the Output Format
    
    fileprivate override init() {
        self.maximumResultCount = 0
        super.init()
    }
    
    /**
     An array of geocoding query strings to include in the request URL.
     */
    internal var query: String = ""
    
    /**
      
       */
    internal var queryPath: String {
        return ""
    }
    /**
     An array of URL parameters to include in the request URL.
     */
    internal var params: [URLQueryItem] {
        var params: [URLQueryItem] = []
        if let focalLocation = focalLocation {
            params.append(URLQueryItem(name: "location", value: "\(focalLocation.coordinate.latitude),\(focalLocation.coordinate.longitude)"))
            params.append(URLQueryItem(name: "radius", value: String(radius)))
        }
       
        if maximumResultCount > 0 {
            params.append(URLQueryItem(name: "limit", value: String(maximumResultCount)))
        }
        if query != "" {
            params.append(URLQueryItem(name: "input", value: query))
        }
               
        return params
    }
}

/**
 A structure that specifies the criteria for forward geocoding results. Forward geocoding takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query.
 */
@objc(GoongForwardGeocodeOptions)
open class ForwardGeocodeOptions: GeocodeOptions {
    /**
        Initializes a forward geocode options object with the given query string.
        
        - parameter query: A place name or address to search for. The query may have a maximum of 20 words or numbers; it may have up to 256 characters including spaces and punctuation.
        */
    @objc public required init(query: String) {
        super.init()
        self.query = query
        self.maximumResultCount = 5
    }
    override var queryPath: String{
        return "/Place/AutoComplete"
    }
   
}

/**
 A structure that specifies the criteria for reverse geocoding results. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.
 */
@objc(GoongReverseGeocodeOptions)
open class ReverseGeocodeOptions: GeocodeOptions {
    /**
     Initializes a reverse geocode options object with the given coordinate pair.
     
     - parameter coordinate: A coordinate pair to search for.
     */
    open var coordinate: CLLocationCoordinate2D
    override var queryPath: String{
        return "/Geocode"
    }
    @objc public required init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
        self.maximumResultCount = 1
        query = String(format: "%f,%f", coordinate.latitude, coordinate.longitude)
    }
    override var params: [URLQueryItem] {
        return [URLQueryItem(name: "latlng", value: query)]
    }
    /**
     Initializes a reverse geocode options object with the given `CLLocation` object.
     
     - parameter location: A `CLLocation` object to search for.
     */
    @objc public convenience init(location: CLLocation) {
        self.init(coordinate: location.coordinate)
    }
}
