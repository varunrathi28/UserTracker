//
//  CustomUserAnnotation.swift
//  UserTracker-Swift
//
//  Created by Varun Rathi on 10/04/17.
//  Copyright © 2017 vrat28. All rights reserved.
//

import UIKit
import MapKit

class CustomUserAnnotation: NSObject, MKAnnotation {

    var coordinate = CLLocationCoordinate2D()
    var title:String?
    
    
    init(coordinate:CLLocationCoordinate2D , title:String) {
        
        self.coordinate = coordinate
        self.title = title
    }
    
}
