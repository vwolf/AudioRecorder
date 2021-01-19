//
//  ItemDetailVC.swift
//  AudioRecorder
//
//  Created by Wolf on 13.10.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import MapKit


/// Display item details.
/// Only location item details implemented, extend if more items needs details
///
class ItemDetailVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var lat: Double = 0.0
    var lon: Double = 0.0
    var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if location != nil {
            let coordinate = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
//            let pin = MKPointAnnotation()
//            pin.coordinate = coordinate
//            pin.title = "Recording Place"
//            pin.subtitle = "subtitle."
            
            
//            let placemark = MKPlacemark(coordinate: coordinate)
//            let mapItem = MKMapItem(placemark: placemark)
//            mapItem.name = "Recording Location"
            //mapItem.name = placemark.postalCode
            //print("title: \(placemark.postalCode)")
            
            //mapView.addAnnotation(placemark)
            //mapItem.openInMaps(launchOptions: nil)
            
//            pin.title = placemark.name
//            mapView.addAnnotation(pin)
            
            lookUpCurrentLocation(completionHandler: { addressObj in
//                print(addressObj?.addressDictionary?.keys)
//                print(addressObj?.addressDictionary?["Street"])
//                print(addressObj?.addressDictionary?["Thoroughfare"])
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                if addressObj?.addressDictionary!["Street"] != nil {
                    annotation.title = addressObj?.addressDictionary?["Street"] as? String
                }
                
                self.mapView.addAnnotation(annotation)
            })
        }
    }
    
    
    
    /// Reverse geocoding a coordinate
    ///
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
                    -> Void ) {
        // Use the last reported location.
        if let lastLocation = self.location {
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    completionHandler(firstLocation)
                }
                else {
                 // An error occurred during geocoding.
                    completionHandler(nil)
                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
}
