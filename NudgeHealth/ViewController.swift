//
//  ViewController.swift
//  NudgeHealth
//
//  Created by Shane Rogers on 10/15/15.
//  Copyright © 2015 Shane Rogers. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    let heightQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    let heartRateQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    let weightQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
    let textFieldRightLabel = UILabel(frame: CGRectZero)
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
  
    lazy var healthStore = HKHealthStore()
    
    lazy var types: NSSet = {
        return NSSet(object: self.weightQuantityType)
    }()
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorizationToShareTypes((types as! Set<HKSampleType>),
                readTypes: (types as! Set<HKObjectType>),
                completion: {[weak self](succeeded: Bool, error: NSError?) -> Void in
                    let strongSelf = self!
                    if succeeded && error == nil {
                      dispatch_async(dispatch_get_main_queue(),
                        strongSelf.readWeightInformation)
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
    
    func readWeightInformation() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
            ascending: false)

        let query = HKSampleQuery(sampleType: weightQuantityType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor],
            resultsHandler: {
                (query:HKSampleQuery, results:[HKSample]?, error:NSError?) -> Void in
                
                if results!.count > 0 {
                    let sample = results![0] as! HKQuantitySample
                    let weightInKilograms = sample.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
                  
                    let formatter = NSMassFormatter()
                    let kilogramSuffix = formatter.unitStringFromValue(weightInKilograms, unit: .Kilogram)
                  
                    self.setValueOnTextField(kilogramSuffix, weightInKilograms: weightInKilograms)                    
                } else {
                    print("Couldnt read the users weight")
                    print("Or there was no weight to read")
                }
            }
        )
        healthStore.executeQuery(query)
    }
  
    func setValueOnTextField(kilogramSuffix: String, weightInKilograms: Double) {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        let strongSelf = self
        
        strongSelf.textFieldRightLabel.text = kilogramSuffix
        strongSelf.textFieldRightLabel.sizeToFit()
        
        let weightFormattedAsString = NSNumberFormatter.localizedStringFromNumber(NSNumber(double: weightInKilograms), numberStyle: .NoStyle)
        print("users weight is: \(weightFormattedAsString)")
        strongSelf.textField.text = weightFormattedAsString
      })
    }
  
    @IBAction func saveWeight(sender: AnyObject) {
      let kilogramUnit = HKUnit.gramUnitWithMetricPrefix(.Kilo)
      let weightVal = (textField.text! as NSString).doubleValue
      
      let weightQuantity = HKQuantity(unit: kilogramUnit,
        doubleValue: weightVal)
      let now = NSDate()
      let sample = HKQuantitySample(
        type: weightQuantityType,
        quantity: weightQuantity,
        startDate: now,
        endDate: now
      )
      
      healthStore.saveObject(sample) { (succeeded, error) -> Void in
        if error == nil {
          print("Successfully saved the user's weight")
        } else {
          print("Failed to save the user's weight")
        }
      }
    }

  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        textField.rightView = textFieldRightLabel
        textField.rightViewMode = .Always
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

