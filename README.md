# GoongGeocoder


<p align="center">
    <img src="https://i.imgur.com/8uyn9m5.png" width="500">
</p>


GoongGeocoder makes it easy to connect your iOS application to the [Goong Geocoding API](https://docs.goong.io/rest/guide/#geocode) and [Goong Autocomplete API](https://docs.goong.io/rest/guide/#place)


## Getting started

Specify the following dependency in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'GoongGeocoder'
```

Then `import GoongGeocoder` or `@import GoongGeocoder;`.

For Objective-C targets, it may be necessary to enable the `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` build setting.

This repository includes example applications written in both Swift and Objective-C showing use of the framework (as well as a comparison of writing apps in either language). More examples and detailed documentation are available in the [Goong API Documentation](https://docs.goong.io).

## Usage

You will need a [Goong API KEY](https://account.goong.io) in order to use the API. If you’re already using the [Goong Maps SDK for iOS](https://docs.goong.io/ios/guide/), GoongGeocoder.swift automatically recognizes your access token, as long as you’ve placed it in the `GoongAccessToken` key of your application’s Info.plist file.

### Autocomplete UI

To use `GoongAutocompleteViewController`, simply present it: 
```swift
let vc = GoongAutocompleteViewController()
let nav = UINavigationController(rootViewController: vc)
vc.delegate = self
self.navigationController?.present(nav, animated: true, completion: nil)
```
```objc
GoongAutocompleteViewController *vc = [[GoongAutocompleteViewController alloc] init];
UINavigationController *nav = [UINavigationController alloc] initWithRootViewController:vc];
vc.delegate = self;
[self.navigationController presentViewController:nav animated:YES completion:nil];
```

Implement `GoongAutocompleteDelegate`, this delegate method called when user tap on a place in tableView:

```swift
public func viewController(_ viewController: GoongAutocompleteViewController, didAutocompleteWith place: Placemark?) {
   print(place?.name)
   print(place?.location)
}
```
Handle error:
```swift
public func viewController(_ viewController: GoongAutocompleteViewController, didFailAutocompleteWithError error: Error?) {
   print(error?.localizedDescription)
}
```


### Basics

The main geocoder class is Geocoder in Swift or GoongGeocoder in Objective-C. Create a geocoder object using your access token:

```swift
// main.swift
import GoongGeocoder

let geocoder = Geocoder(accessToken: "<#your access token#>")
```

```objc
// main.m
@import GoongGeocoder;

GoongGeocoder *geocoder = [[GoongGeocoder alloc] initWithAccessToken:@"<#your access token#>"];
```

Alternatively, you can place your access token in the `GoongAccessToken` key of your application’s Info.plist file, then use the shared geocoder object:

```swift
// main.swift
let geocoder = Geocoder.shared
```

```objc
// main.m
GoongGeocoder *geocoder = [GoongGeocoder sharedGeocoder];
```

With the geocoder in hand, construct a geocode options object and pass it into the `Geocoder.geocode(_:completionHandler:)` method.

### Autocomplete or Forward geocoding

_Forward geocoding_ takes a human-readable query, such as a place name or address, and produces any number of geographic coordinates that correspond to that query. To perform forward geocoding, use ForwardGeocodeOptions in Swift or GoongForwardGeocodeOptions in Objective-C.

```swift
// main.swift

let options = ForwardGeocodeOptions(query: "san bay noi bai")
options.focalLocation = CLLocation(latitude: 21, longitude: 105)
let task = geocoder.geocode(options) { (result, error) in
    guard let result = result else {
        return
    }
    print(result.predictions)
    // GeocodeResult provide predictions if you use ForwardGeocodeOptions
}
```

```objc
// main.m

GoongForwardGeocodeOptions *options = [[GoongForwardGeocodeOptions alloc] initWithQuery:@"san bay noi bai"];
options.focalLocation = [[CLLocation alloc] initWithLatitude:21 longitude:105];


NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(GeocodeResult * _Nullable result,                                                            
                                                            NSError * _Nullable error) {
   // GeocodeResult provide predictions if you use GoongForwardGeocodeOptions
}];
```

### Reverse geocoding

_Reverse geocoding_ takes a geographic coordinate and produces a hierarchy of places, often beginning with an address, that describes the coordinate’s location. To perform reverse geocoding, use ReverseGeocodeOptions in Swift or GoongReverseGeocodeOptions in Objective-C.

```swift
// main.swift
let options = ReverseGeocodeOptions(coordinate: CLLocationCoordinate2D(latitude: 21.21760917728946, longitude: 105.7922871444448))
// Or perhaps: ReverseGeocodeOptions(location: locationManager.location)

let task = geocoder.geocode(options) { (result, error) in
    guard let result = result else {
        return
    }
    // GeocodeResult provide placemarks if you use ReverseGeocodeOptions
    print(result.placemarks.first)        
}
```

```objc
// main.m
GoongReverseGeocodeOptions *options = [[GoongReverseGeocodeOptions alloc] initWithCoordinate: CLLocationCoordinate2DMake(21.21760917728946, 105.7922871444448)];


NSURLSessionDataTask *task = [geocoder geocodeWithOptions:options
                                        completionHandler:^(GeocodeResult * _Nullable result,                                                            
                                                            NSError * _Nullable error) {
  
}];
```

### Place Detail
_Place Detail_ allows you to fetch detail of a place from it's id
```swift
geocoder.fetchPlace(from: <#Place ID#>) { (<#PlaceDetailResult?#>, <#NSError?#>) in
    <#code#>
}
```
```objc
[geocoder fetchPlace:@"" completionHandler:^(PlaceDetailResult * _Nullable result, NSError * _Nullable err) {
    <#code#>
}]
```
