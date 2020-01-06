import Foundation
import CoreLocation
typealias JSONDictionary = [String: Any]

/// Indicates that an error occurred in GoongGeocoder.
public let GoongGeocoderErrorDomain = "GoongGeocoderErrorDomain"

/// The Goong API KEY specified in the main application bundle’s Info.plist.
let defaultAccessToken = Bundle.main.infoDictionary?["GoongAccessToken"] as? String

/// The user agent string for any HTTP requests performed directly within this library.
let userAgent: String = {
    var components: [String] = []

    if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        components.append("\(appName)/\(version)")
    }

    let libraryBundle: Bundle? = Bundle(for: Geocoder.self)

    if let libraryName = libraryBundle?.infoDictionary?["CFBundleName"] as? String, let version = libraryBundle?.infoDictionary?["CFBundleShortVersionString"] as? String {
        components.append("\(libraryName)/\(version)")
    }

    let system: String
    #if os(OSX)
        system = "macOS"
    #elseif os(iOS)
        system = "iOS"
    #elseif os(watchOS)
        system = "watchOS"
    #elseif os(tvOS)
        system = "tvOS"
    #elseif os(Linux)
        system = "Linux"
    #endif
    let systemVersion = ProcessInfo().operatingSystemVersion
    components.append("\(system)/\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")

    let chip: String
    #if arch(x86_64)
        chip = "x86_64"
    #elseif arch(arm)
        chip = "arm"
    #elseif arch(arm64)
        chip = "arm64"
    #elseif arch(i386)
        chip = "i386"
    #elseif os(watchOS) // Workaround for incorrect arch in machine.h for watch simulator  gen 4
        chip = "i386"
    #else
        chip = "unknown"
    #endif
    components.append("(\(chip))")

    return components.joined(separator: " ")
}()

extension CharacterSet {
    /**
     Returns the character set including the characters allowed in the “geocoding query” (file name) part of a Geocoding API URL request.
     */
    internal static func geocodingQueryAllowedCharacterSet() -> CharacterSet {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "/;")
        return characterSet
    }
}

extension CLLocationCoordinate2D {
    /**
     Initializes a coordinate pair based on the given dictionary
     */
    internal init(json: [String : [String : Double ]]) {
        if let location = json["location"], let lat = location["lat"], let lng = location["lng"]{
            self.init(latitude: lat, longitude: lng)
        } else {
            self.init(latitude: 0, longitude: 0)
        }        
    }
}

extension CLLocation {
    /**
     Initializes a CLLocation object with the given coordinate pair.
     */
    internal convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

/**
 A geocoder object that allows you to query the [Goong Geocoding API](https://docs.goong.io/rest/guide/#geocode) and [Goong Autocomplete  API](https://docs.goong.io/rest/guide/#place) for known places corresponding to a given location. The query may take the form of a geographic coordinate or a human-readable string.

 The geocoder object allows you to perform both forward and reverse geocoding. _Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. _Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location.

 Each result produced by the geocoder object is stored in a `Placemark` object. Depending on your query and the available data, the placemark object may contain a variety of information, such as the name, address, region, or contact information for a place, or some combination thereof.
 */
@objc(GoongGeocoder)
open class Geocoder: NSObject {
    /**
     A closure (block) to be called when a geocoding request is complete.

     - parameter result: `GeocodeResult` objects. For reverse geocoding requests, this object represents a hierarchy of places, beginning with the most local place, such as an address, and ending with the broadest possible place, which is usually a country. By contrast, forward geocoding requests may return multiple placemark objects in situations where the specified address matched more than one location.

        If the request was canceled or there was an error obtaining the placemarks, this parameter is `nil`. This is not to be confused with the situation in which no results were found, in which case the array is present but empty.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias CompletionHandler = (_ result: GeocodeResult?, _ error: NSError?) -> Void
    /**
     A closure (block) to be called when a `fetchPlace` request is complete.
     - parameter result: `PlaceDetailResult` objects.
     - parameter error: The error that occurred, or `nil` if the placemarks were obtained successfully.
     */
    public typealias PlaceDetailCompletionHandler = (_ result: PlaceDetailResult?, _ error: NSError?) -> Void
    /**
     The shared geocoder object.

     To use this object, a [Goong API KEY](https://account.goong.io/) should be specified in the `GoongAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc(sharedGeocoder)
    public static let shared = Geocoder(accessToken: nil)

    /// The API endpoint to request the geocodes from.
    internal var apiEndpoint: URL

    /// The Goong API KEY to associate the request with.
    internal let accessToken: String

    /**
     Initializes a newly created geocoder object with an optional access token and host.

     - parameter accessToken: A Goong [access token](https://account.goong.io/). If an access token is not specified when initializing the geocoder object, it should be specified in the `GoongAccessToken` key in the main application bundle’s Info.plist.
     - parameter host: An optional hostname to the server API. The Goong Geocoding API endpoint is used by default.
     */
    @objc public init(accessToken: String?, host: String?) {
        let accessToken = accessToken ?? defaultAccessToken
        assert(accessToken != nil && !accessToken!.isEmpty, "A Goong API KEY is required. Go to <https://account.goong.io>. In Info.plist, set the GoongAccessToken key to your access token, or use the Geocoder(accessToken:host:) initializer.")

        self.accessToken = accessToken!

        var baseURLComponents = URLComponents()
        baseURLComponents.scheme = "https"
        baseURLComponents.host = host ?? "rsapi.goong.io"
        self.apiEndpoint = baseURLComponents.url!
    }

    /**
     Initializes a newly created geocoder object with an optional access token.

     The geocoder object sends requests to the Goong Geocoding API endpoint.

     - parameter accessToken: A Goong API KEY. If an access token is not specified when initializing the geocoder object, it should be specified in the `GoongAccessToken` key in the main application bundle’s Info.plist.
     */
    @objc public convenience init(accessToken: String?) {
        self.init(accessToken: accessToken, host: nil)
    }

    // MARK: Geocoding a Location

    /**
     Submits a geocoding request to search for placemarks and delivers the results to the given closure.

     This method retrieves the placemarks asynchronously over a network connection. If a connection error or server error occurs, details about the error are passed into the given completion handler in lieu of the placemarks.

     - parameter options: A `ForwardGeocodeOptions` or `ReverseGeocodeOptions` object indicating what to search for.
     - parameter completionHandler: The closure (block) to call with the resulting placemarks. This closure is executed on the application’s main thread.
     - returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to execute, you no longer want the resulting placemarks, cancel this task.
     */

    @discardableResult
    @objc(geocodeWithOptions:completionHandler:)
    open func geocode(_ options: GeocodeOptions, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        let url = urlForGeocoding(options)
        let task = dataTaskWithURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(GeocodeResult.self, from: data)
                // Check if geocoding query failed
                if let message = result.status, message != "OK" {
                    let apiError = NSError(domain: GoongGeocoderErrorDomain, code: -1, userInfo: ["message" : message])
                    DispatchQueue.main.async {
                        completionHandler(nil, apiError)
                    }
                    return
                }
                completionHandler(result, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
    }
    /**
     Submits a place detail request to fetch place detail
     - parameter placeID: the identifier of place
     - parameter completionHandler: The clousre to call with the resulting `PlaceDetailResult` object, contains a `Placemark` object
     */
    @discardableResult
    @objc(fetchPlace:completionHandler:)
    open func fetchPlace(from placeID: String, completionHandler: @escaping PlaceDetailCompletionHandler) -> URLSessionDataTask {
         let params =  [URLQueryItem(name: "api_key", value: accessToken),
                        URLQueryItem(name: "placeid", value: placeID)]
        
        let unparameterizedURL: URL!
        unparameterizedURL = URL(string: "/Place/Detail", relativeTo: apiEndpoint)!
        
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        let url = components.url!
        let task = dataTaskWithURL(url, completionHandler: { (data) in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(PlaceDetailResult.self, from: data)
                // Check if geocoding query failed
                if let message = result.status, message != "OK" {
                    let apiError = NSError(domain: GoongGeocoderErrorDomain, code: -1, userInfo: ["message" : message])
                    DispatchQueue.main.async {
                        completionHandler(nil, apiError)
                    }
                    return
                }
                completionHandler(result, nil)
            } catch {
                completionHandler(nil, error as NSError)
            }
        }) { (error) in
            completionHandler(nil, error)
        }
        task.resume()
        return task
        
    }
    /**
     Returns a URL session task for the given URL that will run the given blocks on completion or error.

     - parameter url: The URL to request.
     - parameter completionHandler: The closure to call with the parsed JSON response dictionary.
     - parameter errorHandler: The closure to call when there is an error.
     - returns: The data task for the URL.
     - postcondition: The caller must resume the returned task.
     */
    fileprivate func dataTaskWithURL(_ url: URL, completionHandler: @escaping (_ data: Data?) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) -> URLSessionDataTask {
        var request = URLRequest(url: url)

        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return URLSession.shared.dataTask(with: request) { (data, response, error) in

            guard let data = data else {
                DispatchQueue.main.async {
                    if let e = error as NSError? {
                        errorHandler(e)
                    } else {
                        let unexpectedError = NSError(domain: GoongGeocoderErrorDomain, code: -1024, userInfo: [NSLocalizedDescriptionKey : "unexpected error", NSDebugDescriptionErrorKey : "this error happens when data task return nil data and nil error, which typically is not possible"])
                        errorHandler(unexpectedError)
                    }
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(data)
            }
            
            
        }
    }

    internal struct GeocodeAPIResult: Codable {
        let status: String?
    }

    /**
     The HTTP URL used to fetch the geocodes from the API.
     */
    @objc open func urlForGeocoding(_ options: GeocodeOptions) -> URL {
        let params = options.params + [
            URLQueryItem(name: "api_key", value: accessToken),
        ]
        
        let unparameterizedURL: URL!
        unparameterizedURL = URL(string: options.queryPath, relativeTo: apiEndpoint)!
        
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }

    /**
     Returns an error that supplements the given underlying error with additional information from the an HTTP response’s body or headers.
     */
    static func descriptiveError(_ json: JSONDictionary, response: URLResponse?, underlyingError error: NSError?) -> NSError {
        var userInfo = error?.userInfo ?? [:]
        if let response = response as? HTTPURLResponse {
            var failureReason: String? = nil
            var recoverySuggestion: String? = nil
            switch response.statusCode {
            case 429:
                if let timeInterval = response.rateLimitInterval, let maximumCountOfRequests = response.rateLimit {
                    let intervalFormatter = DateComponentsFormatter()
                    intervalFormatter.unitsStyle = .full
                    let formattedInterval = intervalFormatter.string(from: timeInterval) ?? "\(timeInterval) seconds"
                    let formattedCount = NumberFormatter.localizedString(from: maximumCountOfRequests as NSNumber, number: .decimal)
                    failureReason = "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
                }
                if let rolloverTime = response.rateLimitResetTime {
                    let formattedDate = DateFormatter.localizedString(from: rolloverTime, dateStyle: .long, timeStyle: .long)
                    recoverySuggestion = "Wait until \(formattedDate) before retrying."
                }
            default:
                failureReason = json["message"] as? String
            }
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason ?? userInfo[NSLocalizedFailureReasonErrorKey] ?? HTTPURLResponse.localizedString(forStatusCode: error?.code ?? -1)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion ?? userInfo[NSLocalizedRecoverySuggestionErrorKey]
        }
        if let error = error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        return NSError(domain: error?.domain ?? GoongGeocoderErrorDomain, code: error?.code ?? -1, userInfo: userInfo)
    }
}

extension HTTPURLResponse {
    var rateLimit: UInt? {
        guard let limit = allHeaderFields["X-Rate-Limit-Limit"] as? String else {
            return nil
        }
        return UInt(limit)
    }

    var rateLimitInterval: TimeInterval? {
        guard let interval = allHeaderFields["X-Rate-Limit-Interval"] as? String else {
            return nil
        }
        return TimeInterval(interval)
    }

    var rateLimitResetTime: Date? {
        guard let resetTime = allHeaderFields["X-Rate-Limit-Reset"] as? String else {
            return nil
        }
        guard let resetTimeNumber = Double(resetTime) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimeNumber)
    }

}
