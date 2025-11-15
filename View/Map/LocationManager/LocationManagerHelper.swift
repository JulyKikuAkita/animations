//
//  LocationManagerHelper.swift
//  animation
//
//  Created on 11/15/25.

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
