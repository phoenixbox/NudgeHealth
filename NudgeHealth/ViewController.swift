//
//  ViewController.swift
//  NudgeHealth
//
//  Created by Shane Rogers on 10/15/15.
//  Copyright © 2015 Shane Rogers. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let heightQuantity = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
    let weightQuantity = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
    let heartRateQuantity = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    
    lazy var healthStore = HKHealthStore()
    
    // Not to be written to the health store - share === written
    lazy var typesToShare: NSSet = {
        return NSSet(objects: self.heightQuantity!, self.weightQuantity!)
    }()
    
    // Data to read
    lazy var typesToRead: NSSet = {
        return NSSet(objects: self.heightQuantity!, self.weightQuantity!, self.heartRateQuantity!)
    }()
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorizationToShareTypes(typesToShare as? Set<HKSampleType>,
                readTypes: typesToRead as? Set<HKObjectType>,
                completion: {(succeeded: Bool, error: NSError?) -> Void in
                    if succeeded && error == nil {
                        print("Auth successful")
                    } else {
                        if let theError = error {
                            print("Error occurred = \(theError)")
                        }
                    }
                }
            )
        } else {
            print("Health data is not available")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

