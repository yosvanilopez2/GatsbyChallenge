//
//  MapVC.swift
//  GatsbyChallenge
//
//  Created by Yosvani Lopez on 11/30/16.
//  Copyright © 2016 Yosvani Lopez. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
class MapVC: UIViewController, MKMapViewDelegate {


    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 200
    
    let TimeSquare = "Manhattan, NY 10036"
    let NYCComedyClub = "241 E 24th St, New York, NY 10010"
    let MadisonSquareGarden = "4 Pennsylvania Plaza, New York, NY 10001"
    let StatueofLiberty = "New York, NY 10004"
    let MuseumofModernArt = "11 W 53rd St, New York, NY 10019"
    let YankeeStadium = "1 E 161st St, Bronx, NY 10451"
    var car: MKPointAnnotation!
    var carlocation = "Manhattan, NY 10036"
    var pointcount = 0
    var stopped = true
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsBuildings = false
        centerMapOnAddress(address: TimeSquare)
        car = MKPointAnnotation()
        getPlaceMarkForLocation (address: TimeSquare) { (startLocation) in
            if startLocation != nil {
                self.car.coordinate = (startLocation?.coordinate)!
            }
        }
        mapView.addAnnotation(car)
    }
    
    @IBAction func goToTimesSquare(_ sender: AnyObject) {
        if stopped {
            stopped = false
            moveCar(carlocation: carlocation, destination: TimeSquare)
            carlocation = TimeSquare
        }
    }
    @IBAction func goToMSG(_ sender: AnyObject) {
        if stopped {
            stopped = false
            moveCar(carlocation: carlocation, destination: MadisonSquareGarden)
            carlocation = MadisonSquareGarden
        }
    }
    @IBAction func goToYankeeStadium(_ sender: AnyObject) {
        if stopped {
            stopped = false
            moveCar(carlocation: carlocation, destination: YankeeStadium)
            carlocation = YankeeStadium
        }
    }
  
    @IBAction func goToNYCComedyClub(_ sender: AnyObject) {
        if stopped {
            stopped = false
            moveCar(carlocation: carlocation, destination: NYCComedyClub)
            carlocation = NYCComedyClub
        }
    }
   
    @IBAction func goToStatueofLiberty(_ sender: AnyObject) {
        if stopped {
            stopped = false
            moveCar(carlocation: carlocation, destination: StatueofLiberty)
            carlocation = StatueofLiberty
        }
    }
    
    
    func moveCar(carlocation: String, destination: String) {
        getPlaceMarkForLocation(address: carlocation, complete: { (startAddress) in
            if let start = startAddress {
                self.getPlaceMarkForLocation(address: destination, complete: { (endAddress) in
                    if let end = endAddress {
                        self.calculateSegmentDirections(source: start, destination: end, complete: { (coordinates) in
                            if coordinates != nil {
                                self.moveCarAlongPath(coordinates: coordinates!)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func moveCarAlongPath(coordinates: UnsafeMutablePointer<CLLocationCoordinate2D> ) {
        mapView.addAnnotation(car)
        for i in 0...pointcount - 1 {
          print(coordinates[i].latitude)
          print(coordinates[i].longitude)
          DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1*i), execute: {
            UIView.animate(withDuration: 2.0) {
                var loc = self.car.coordinate
                var centerloc = self.mapView.centerCoordinate
                centerloc.latitude = centerloc.latitude + 0.0005
                centerloc.longitude = centerloc.longitude + 0.001
                loc.latitude = loc.latitude + 0.0005
                loc.longitude = loc.longitude + 0.001
                self.mapView.centerCoordinate = coordinates[i]
                self.car.coordinate = coordinates[i]
            }
            if i == self.pointcount - 1 {
                self.stopped = true
            }
            })
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
        let pinImage = UIImage(named: "car")
        annotationView!.image = pinImage
        annotationView?.isDraggable = true
        return annotationView
    }
    
    func getPlaceMarkForLocation(address: String, complete: @escaping (MKPlacemark?) -> ()) {
        CLGeocoder().geocodeAddressString(address){ placeMark, error in
            if let mark = placeMark, mark.count > 0 {
                if let coordinate = mark[0].location?.coordinate {
                    let mkPlacemark = MKPlacemark(coordinate: coordinate)
                    complete(mkPlacemark)
                }
                complete(nil)
            }
            else {
                 complete(nil)
            }
        }
    }
    
    func calculateSegmentDirections(source: MKPlacemark, destination: MKPlacemark, complete: @escaping (UnsafeMutablePointer<CLLocationCoordinate2D>?) -> ())  {
        let request: MKDirectionsRequest = MKDirectionsRequest()
        request.source = MKMapItem(placemark: source)
        request.destination =  MKMapItem(placemark: destination)
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate (completionHandler: {
            (response: MKDirectionsResponse?, error: Error?) in
            if error != nil {
                print("there was an error")
                print(error.debugDescription)
            } else {
                if let routeResponse = response?.routes {
                    let shortestRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
                    let pointCount = shortestRoute.polyline.pointCount;
                  let coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount * MemoryLayout<CLLocationCoordinate2D>.size)
                  shortestRoute.polyline.getCoordinates(coordinates, range: NSMakeRange(0, pointCount))
                    self.pointcount = pointCount
                   complete(coordinates)
                } else {
                    complete(nil)
                    print("No routes found")
                }
            }
        })
    }
    func centerMapOnAddress(address: String) {
        // could make completion handler to simplify the CLGeocoding but no exactly proficient with completion handlers yet so that will be left for a potential beta version
        CLGeocoder().geocodeAddressString(address){ placeMark, error in
            if let mark = placeMark, mark.count > 0 {
                if let location = mark[0].location {
                    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, self.regionRadius, self.regionRadius)
                    self.mapView.setRegion(coordinateRegion, animated: true)
                }
            }
        }
        
    }
    
    
}
