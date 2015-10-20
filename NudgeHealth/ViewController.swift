//
//  ViewController.swift
//  NudgeHealth
//
//  Created by Shane Rogers on 10/15/15.
//  Copyright © 2015 Shane Rogers. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
  
    enum HeightUnits: String {
      case Millimeters = "Millimeters"
      case Centimeters = "Centimeters"
      case Meters = "Meters"
      case Inches = "Inches"
      case Feet = "Feet"
      static let allValues = [Millimeters, Centimeters, Meters, Inches, Feet]
      
      func HealthKitUnit() -> HKUnit{
        switch self {
        case .Millimeters:
          return HKUnit.meterUnitWithMetricPrefix(.Milli)
        case .Centimeters:
          return HKUnit.meterUnitWithMetricPrefix(.Centi)
        case .Meters:
          return HKUnit.meterUnit()
        case .Inches:
          return HKUnit.inchUnit()
        case .Feet:
          return HKUnit.footUnit()
        }
      }
    }

    //  Enum instance
    var heightUnit:HeightUnits = .Millimeters {
      willSet {
        readHeightInformation()
      }
    }
  
    var selectedIndexPath = NSIndexPath(forRow: 0, inSection:0)
    let heightQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    let heightSampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    lazy var types: NSSet = {
      return NSSet(object: self.heightSampleType)
    }()
    lazy var healthStore = HKHealthStore()
    struct TableViewInfo {
      static let cellIdentifier = "Cell"
    }
    //  Table Protocol Adherence
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return HeightUnits.allValues.count
    }
  

  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(TableViewInfo.cellIdentifier, forIndexPath: indexPath) as UITableViewCell
    let heightUnit = HeightUnits.allValues[indexPath.row]
    
    cell.textLabel!.text = heightUnit.rawValue
    if indexPath == selectedIndexPath {
      cell.accessoryType = .Checkmark
    } else {
      cell.accessoryType = .None
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let prevSelectedIndexPath = selectedIndexPath
    selectedIndexPath = indexPath
    
    tableView.reloadRowsAtIndexPaths([prevSelectedIndexPath, selectedIndexPath], withRowAnimation: .Automatic)
  }
  
  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    let prevSelectedIndexPath = selectedIndexPath
    selectedIndexPath = indexPath
    
    tableView.reloadRowsAtIndexPaths([prevSelectedIndexPath, selectedIndexPath], withRowAnimation: .Automatic)
  }
  

    let heartRateQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    let weightQuantityType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
  
    let textFieldRightLabel = UILabel(frame: CGRectZero)
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
  
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorizationToShareTypes((types as! Set<HKSampleType>),
                readTypes: (types as! Set<HKObjectType>),
                completion: {[weak self](succeeded: Bool, error: NSError?) -> Void in
                    let strongSelf = self!
                    if succeeded && error == nil {
                      dispatch_async(dispatch_get_main_queue(),
                        strongSelf.readHeightInformation)
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
  
    func readHeightInformation() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
            ascending: false)

        let query = HKSampleQuery(sampleType: weightQuantityType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor],
            resultsHandler: {
                (query:HKSampleQuery, results:[HKSample]?, error:NSError?) -> Void in
                
                if results?.count > 0 {
                    let sample = results![0] as! HKQuantitySample
                    let currentUnit = self.heightUnit.HealthKitUnit()
                    let heightInUnit = sample.quantity.doubleValueForUnit(currentUnit)
                  
                  dispatch_async(dispatch_get_main_queue(), {
                    let heightFormattedAsString = NSNumberFormatter.localizedStringFromNumber(NSNumber(double: heightInUnit), numberStyle: .DecimalStyle)
                    self.textField.text = heightFormattedAsString
                  })
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

    @IBAction func saveHeight(sender: AnyObject) {
      let currentlySelectedUnit = heightUnit.HealthKitUnit()
      let heightQuantity = HKQuantity(unit: currentlySelectedUnit, doubleValue:(textField.text! as NSString).doubleValue)
      let now = NSDate()
      let sample = HKQuantitySample(type: heightQuantityType,
        quantity: heightQuantity,
        startDate: now,
        endDate: now
      )
      
      healthStore.saveObject(sample) { (succeeded: Bool, error: NSError?) -> Void in
        if error == nil {
          print("Saved the users height")
        } else {
          print("Failed to save the user height")
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
  
  override func encodeRestorableStateWithCoder(coder: NSCoder) {
    super.encodeRestorableStateWithCoder(coder)
    coder.encodeObject(selectedIndexPath, forKey: "selectedIndexPath")
    coder.encodeObject(heightUnit.rawValue, forKey: "heightUnit")
  }
  
  override func decodeRestorableStateWithCoder(coder: NSCoder) {
    super.decodeRestorableStateWithCoder(coder)
    //  reassign the local var with the value related to its key
    selectedIndexPath = coder.decodeObjectForKey("selectedIndexPath") as! NSIndexPath
    
    let newUnit = HeightUnits(rawValue: coder.decodeObjectForKey("heightUnit") as! String)
    if (newUnit != nil) {
      heightUnit = newUnit!
    }
  }
}

