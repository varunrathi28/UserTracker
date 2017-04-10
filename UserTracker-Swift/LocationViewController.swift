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

import TTGSnackbar

class LocationViewController: UIViewController {

     let kCurrentLocationIdentifier = "Current"
     let kUserIdentifier = "user"
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
    var isTracking :Bool = false
    var startDate:Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocationManager()
        mapView.delegate = self
        mapView.userTrackingMode = .followWithHeading
        mapView.showsUserLocation = true
        btnLocation.setImage(UIImage(named:"gps"), for: .normal)
        btnLocation.setImage(UIImage(named:"stop"), for: .selected)
    }
    
    @IBAction func btnStartLocation(sender:AnyObject)
    {
        isTracking = true
        if btnLocation.isSelected == false
        {
            btnLocation.isSelected = true
            if mapView.overlays.count > 0  // Clear out previous path
            {
                let overlays = self.mapView.overlays
                mapView.removeOverlays(overlays)
            }
            
            if mapView.annotations.count > 0 // Clear previous locations
            {
                mapView.removeAnnotations(mapView.annotations)
            }

            locationManager.startUpdatingLocation()
            locationManager.stopUpdatingHeading()
            locationManager.delegate = self
            startTimer()                // Start the timer
            
        }
        else
        {
          locationManager.stopUpdatingLocation()
          locationManager.delegate = nil
            
            btnLocation.isSelected = false
            isTracking = false
            if userPath.count > 0
            {
                let lastlocation = userPath[userPath.count - 1]
                addAnnotation(with: lastlocation.coordinate, title: "End")
                  isEndLocation = true
            }
            
           timer.invalidate()
            showSnackBar()
        }
    }
    
    // MARK: - Show Alert
    
    // Custom Bar
    func showSnackBar()
    {
        let message = getTimeInString()
        let snackbar = TTGSnackbar(message: "Shift " + message, duration: .long)
        snackbar.actionText = "Save"
        snackbar.actionTextColor = UIColor.white
        snackbar.actionBlock = { (bar) in bar.dismiss() }
        snackbar.show()
        
    }
    
    // Time calculation
    
    func getTimeInString()->String
    {
       let currentDate = Date()
        let calender:Calendar = Calendar.current
        let components: DateComponents = calender.dateComponents([.hour, .minute,.second], from: startDate!, to: currentDate)
        
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        let str = "\(hours)h :\(minutes)m :\(seconds)s"
        return str
    }
    
    
    //MARK: - Annotations
    
    func addAnnotation(with location:CLLocationCoordinate2D ,title :String)
    {
      let annotation = CustomUserAnnotation(coordinate: location, title: title)
      mapView.addAnnotation(annotation)
        
     }

    // MARK: - Timer
    
    func startTimer()
    {
        resetTimer()
        startDate = Date()
        distance = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            
            self.totalTime += 1
        })
    }
    
    func resetTimer()
    {
        totalTime = 0
        isStartLocation = false
        userPath.removeAll()
        
    }

    // MARK: - Location manager functions
    
    func setUpLocationManager()
    {
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        // Check location Authorization, and if not ask for Authorized when in use, as it drains less amount of battery
        
        let isAuthorized = CLLocationManager.authorizationStatus()
        if isAuthorized == .notDetermined
        {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }
    
    // When even a location is updated, map should be centered acc to that
    
    func centerMapOnLocation(for location:CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK: - Utility Functions
    
    // To create a polyline from the array of locations to present as overlay on MKMapview
    
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
        
        if (manager.location?.coordinate) != nil
        {
            
            if isStartLocation == false   // First time
            {
                let location:CLLocation? = locations[0]
                
                if let location = location , isTracking == true  // First time location updated , after user has pressed start tracking button
                {
                  isStartLocation = true
                  addAnnotation(with: location.coordinate, title: "Start") // Add Initation Annotation
                    startLocation = location.coordinate
                    userPath.append(location)  // Add it to the path
                }
                centerMapOnLocation(for: location!)
            }
            else if isTracking == true   // The user tracking is on progress
            {
                isEndLocation = true   // So , any more location updates would be for intermediate path and not inital location
                let location  = locations[0]
                userPath.append(location)
                
                let spanX = 0.007                   // Optimal zoom
                let spanY = 0.007
                
                let updatedRegion = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
                mapView.setRegion(updatedRegion, animated: true)
                
                
                if userPath.count > 1       // Extra check
                {
                    let previousIndex = userPath.count-2
                    let currentIndex = userPath.count-1
                    
                    // Create a line from the last element to the second last element / Most recent path
                    let coord1 = userPath[currentIndex].coordinate
                    let coord2 = userPath[previousIndex].coordinate
                    
                    var array = [coord1, coord2]
                    let polyline = MKPolyline(coordinates: &array, count: array.count)
                    mapView.add(polyline)
                }
                
            }
        }
        
    }
}

extension LocationViewController : MKMapViewDelegate
{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       
    
        if  overlay is MKPolyline               // we are only using polyline as an overlay
        {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(red: 101.0/255.0, green: 199.0/255.0, blue: 250.0/255.0, alpha: 0.8)
            renderer.lineWidth = 4.0
            return renderer
 
        }
        return MKPolygonRenderer()
}
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView:MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self)
        {
           annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier:kCurrentLocationIdentifier
            )
        }
        else
        {
            if isTracking == true || isEndLocation == true // we dont want annotation unless user starts tracking
            {
                
                let newAnnotation = MKAnnotationView(annotation: annotation
                    , reuseIdentifier: kUserIdentifier)
                annotationView = newAnnotation
                if isEndLocation == true               // destination location
                {
                    isEndLocation = false
                    annotationView?.image = UIImage(named: "current-pin")
                }
                else if   isStartLocation == true                             // source location
                {
                    annotationView?.image = UIImage(named: "start-pin")
                }
                
            }
        }
        
        return annotationView!
    }
    
    
}

