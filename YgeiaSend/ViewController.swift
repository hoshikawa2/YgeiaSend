//
//  ViewController.swift
//  YgeiaSend
//
//  Created by Cristiano Hoshikawa on 05/11/19.
//  Copyright © 2019 Cristiano Hoshikawa. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {


    @IBOutlet weak var btnCallYgeia: UIButton!
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // /////////////////////////////////////
        // HEALTH KIT AUTHORIZATION
        let healthKitTypes: Set = [
            // access step count
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        ]
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (_, _) in
            print("authrised???")
        }
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            if let e = error {
                print("oops something went wrong during authorisation \(e.localizedDescription)")
            } else {
                print("User has completed the authorization flow")
            }
        }
        // /////////////////////////////////////

    }

    // READ HEALTH DATA FROM PHONE
    func testStatisticsCollectionQueryCumulitive() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        var interval = DateComponents()
        interval.hour = 1
        
        let calendar = Calendar.current
        let anchorDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
     
        let query = HKStatisticsCollectionQuery.init(quantityType: stepCountType,
                                                     quantitySamplePredicate: nil,
                                                     options: .cumulativeSum,
                                                     anchorDate: anchorDate!,
                                                     intervalComponents: interval)
        
        query.initialResultsHandler = {
            query, results, error in
            
            let startDate = calendar.startOfDay(for: Date())
     
            results?.enumerateStatistics(from: startDate,
                                         to: Date(), with: { (result, stop) in
                                            self.callRestYgeia(jsonString: "Time: \(result.startDate), \(result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)")
            })
        }
        healthStore.execute(query)
    }

    // CALL YGEIA BACKEND
    func callRestYgeia(jsonString: String)
    {
    let username = "oicdemouser"
    let password = "Oracle123456"
    let loginString = String(format: "%@:%@", username, password)
    let loginData = loginString.data(using: String.Encoding.utf8)!
    let base64LoginString = loginData.base64EncodedString()
    
    let params = ["steps":jsonString] as Dictionary<String, String>

    var request = URLRequest(url: URL(string: "https://OIC-DIGIDEV-ladsedigdev.integration.ocp.oraclecloud.com:443/ic/api/integration/v1/flows/rest/YGEIA_RECEIVE_HEALTH_DATA/1.0/ygeiaReceiveHealth")!)
    request.httpMethod = "POST"
    request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

    let session = URLSession.shared
    let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
        print(response!)
        do {
            let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
            print(json)
        } catch {
            print("error")
        }
    })

    task.resume()
    }
    
    @IBAction func btnCAllYgeiaService(_ sender: Any) {
        
        print(testStatisticsCollectionQueryCumulitive())
    }
    
}

