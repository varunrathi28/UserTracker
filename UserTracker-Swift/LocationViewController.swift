//
//  ViewController.swift
//  UserTracker-Swift
//
//  Created by Varun Rathi on 10/04/17.
//  Copyright © 2017 vrat28. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LocationViewController: UIViewController {

    var startLocation:CLLocationCoordinate2D?
    var endLocation:CLLocationCoordinate2D?
    var locationManager:CLLocationManager!
    @IBOutlet weak var mapView:MKMapView!
    @IBOutlet weak var btnLocation:UIButton!
    
    var distance:Double = 0.0
    var totalTime:Int = 0
    
    
    var userPath : [CLLocation] = []
    var timer:Timer!
    var isStartLocation:Bool = false
    var isEndLocation:Bool = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocationManager()
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func btnStartLocation(sender:AnyObject)
    {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        if isStartLocation == false
        {
            if mapView.overlays.count > 0
            {
            
                let overlays = self.mapView.overlays
                mapView.removeOverlays(overlays)
            }
            
          // isStartLocation = true
            startTimer()
            
        }
        else
        {
            isStartLocation = false
            showTrackOverlay()
           // resetTimer()
            
        }
        
        
    }
    
    func startTimer()
    {
       
        totalTime = 0
        distance = 0
        userPath.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            
            self.totalTime += 1
        })
    }
    
    func resetTimer()
    {
        timer.invalidate()
        totalTime = 0
        
    }
    

    // MARK: - Location manager functions
    
    func setUpLocationManager()
    {
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 10
        
        // Check location Authorization, and if not ask for Authorized when in use, as it drains less amount of battery
        
        let isAuthorized = CLLocationManager.authorizationStatus()
        
        if isAuthorized == .denied || isAuthorized == .notDetermined
        {
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }
    
    func centerMapOnLocation(for location:CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func showTrackOverlay()
    {
        let region = mapRegion()
        let polylines = polyline()
        mapView.setRegion(region, animated: true)
        mapView.add(polylines)
    }
    
    
    // MARK: - Utility Functions
    
    // To create a polyline from the array of locations to present as overlay on MKMapview
    
    func polyline() -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for location in userPath {
            coords.append(CLLocationCoordinate2D(latitude: Double(location.coordinate.latitude),
                                                 longitude: Double(location.coordinate.longitude)))
        }
        return MKPolyline(coordinates: &coords, count: userPath.count)
    }
    
    
    // For calculation of optimal map area for the user track
    // Longer the track , more should be zoomout/Span
    
    
    func mapRegion() -> MKCoordinateRegion {
        let initialLoc = userPath.first
        
        var minLat = Double((initialLoc?.coordinate.latitude)!)
        var minLng = Double((initialLoc?.coordinate.longitude)!)
        var maxLat = minLat
        var maxLng = minLng
        
        
        
        for location in userPath {
            minLat = min(minLat, Double(location.coordinate.latitude))
            minLng = min(minLng,Double(location.coordinate.longitude))
            maxLat = max(maxLat, Double(location.coordinate.latitude))
            maxLng = max(maxLng, Double(location.coordinate.longitude))
        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat)/2,
                                           longitude: (minLng + maxLng)/2),
            span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*1.1,
                                   longitudeDelta: (maxLng - minLng)*1.1))
    }
    
    
    
}

extension LocationViewController:CLLocationManagerDelegate
{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
         if let location = manager.location?.coordinate
         {
            
            if isStartLocation == false
            {
                isStartLocation = true
                startLocation = location
               
                var startAnnotation:CustomUserAnnotation?
                
                let location:CLLocation? = locations[0]
               
                if let location = location
                {
                   startAnnotation = CustomUserAnnotation(coordinate: location.coordinate, title: "Start")
                }
                mapView.addAnnotation(startAnnotation!)
                centerMapOnLocation(for: location!)
            }
            else
            {
                isEndLocation = true
                for aLocation in locations
                {
                   
                    if userPath.count > 1
                    {
                        distance += aLocation.distance(from: userPath.last!)
                    }
                    userPath.append(aLocation)
                    
                }
            
            }
        }
    }
    
}

extension LocationViewController : MKMapViewDelegate
{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView:MKAnnotationView?
         annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "user")
        return annotationView!
    }
    
    
}

