//
//  LocationManagerHelper.swift
//  animation
//
//  Created on 11/15/25.
//
//  ⚠️  REUSABLE HELPER, NOT A STANDALONE DEMO. Consumed by
//      [[LocationPermissionFullSheetView]] for live authorization
//      status. Drop-in for any view that needs to read or request
//      "When in Use" location permission.
//
//  Learning point
//  ──────────────
//  Minimal `@Observable @MainActor` wrapper around `CLLocationManager`
//  that exposes ONE published property — `status` — so SwiftUI
//  views can drive UI directly off `CLAuthorizationStatus` changes
//  without setting up `CLLocationManagerDelegate` themselves.
//
//  Three deliberate choices in such a small file:
//    1. **`@Observable` (iOS 17+)** instead of `ObservableObject` —
//       fewer recompilations, smaller diff per change, and reads
//       inside views are tracked at the property level (not the
//       whole class). The modern default.
//    2. **`@MainActor`** on the class — `CLLocationManagerDelegate`
//       callbacks run on whatever queue `CLLocationManager` uses
//       (effectively main here), and SwiftUI requires main-thread
//       state mutations. Marking the class up-front avoids
//       per-method `@MainActor` annotations.
//    3. **`NSObject` superclass** — required because
//       `CLLocationManagerDelegate` is an Objective-C protocol;
//       Swift class delegates must inherit from `NSObject`.
//
//  This is "request when-in-use only" by design. Add another
//  method (e.g. `requestAlwaysAccess`) and mirror the
//  `manager.requestAlwaysAuthorization()` call if you need
//  background location.
//
//  Key APIs
//  ────────
//  • `@Observable` — iOS 17+ macro; replaces `ObservableObject`.
//  • `CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)`
//    — fires once at delegate-set time AND on every status change.
//    Replaces the deprecated didChangeAuthorization variant.
//  • `manager.requestWhenInUseAuthorization()` — fires the system
//    permission alert (only if `.notDetermined`; otherwise no-op).
//
//  How to apply
//  ────────────
//  Drop into any feature that conditionally needs location.
//  The shape is small enough to fork and rename per-app (e.g.
//  `OrderTrackingLocationManager`) if the app needs per-feature
//  isolation; or reuse as-is if the project only has one location
//  consumer.
//
//  See also
//  ────────
//  • View/Map/View/LocationPermissionFullSheetView.swift — the
//    primary consumer; permission prompt UI driven by `status`.
//  • Helpers/CoreLocation/LocationPickerManager.swift — separate
//    location helper for the picker flow (defines its OWN
//    `LocationManager`; not consolidated with this one).
//
import MapKit

@Observable
@MainActor class MapLocationManager: NSObject, CLLocationManagerDelegate {
    var status: CLAuthorizationStatus = .notDetermined
    private var manager: CLLocationManager
    override init() {
        manager = .init()
        super.init()
        manager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }

    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
    }
}
