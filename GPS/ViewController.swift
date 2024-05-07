
import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var currentSpeedLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var speedWarnning: UIView!
    @IBOutlet weak var tripStart: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var maxAccelerationLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var overSpeedDistanceLabel: UILabel!
    
    
    var perviousLocation: CLLocation?
    var distanceTotal = 0.0
    var maxAcc: Double = 0.0
    let manager = CLLocationManager()
    var speeds: [Double] = []
    var totalAcc : CLLocationSpeed = 0.0
    var isTripActive = false
    var distanceBeforeExceedingLimit = 0.0
    let speedLimit = 115.0
    
    
    @IBAction func startTripButton(_ sender: Any) {
        if checkForPermission(){
                isTripActive = true //trip start
                overSpeedDistanceLabel.text = ""
                speeds.removeAll()
                tripStart.backgroundColor = UIColor.systemGreen
                manager.startUpdatingLocation()
        } else{
            overSpeedDistanceLabel.text = "Please Enable Location Permission"
        }
    }
    
    @IBAction func stopTripButton(_ sender: Any) {
        if checkForPermission(){
            isTripActive = false
            overSpeedDistanceLabel.text = String(format: " %.2f km travel before exceeding speed limit", distanceBeforeExceedingLimit)
            manager.stopUpdatingLocation()
            speedWarnning.backgroundColor = UIColor.white
            tripStart.backgroundColor = UIColor.gray
            speeds.removeAll()
        } else{
            overSpeedDistanceLabel.text = "Please Enable Location Permission"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locationDistance = locations.last else {return}
        let location = locations[0]
        let speed = location.speed * 3.6
        print("Value",speed)
        speeds.append(speed)
        
        let span  = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)

        let regin = MKCoordinateRegion(center: myLocation, span: span)
        
        mapView.setRegion(regin, animated: true)
        
        self.mapView.showsUserLocation = true
        
        let speedKmPerHour = speed
        currentSpeedLabel.text = String(format: " %.2f km/h", speedKmPerHour)
          
        if let maxSpeed = speeds.max() {
            let maxSpeedKmPerHour = maxSpeed
            maxSpeedLabel.text = String(format: " %.2f km/h", maxSpeedKmPerHour)
             }
        
        if let perviousLocation = self.perviousLocation {
            distanceTotal += locationDistance.distance(from: perviousLocation) / 1000
            distanceLabel.text = String(format: " %.2f km", distanceTotal)
        }
        
        if !speeds.isEmpty {
              let averageSpeed = calculateAverageSpeed()
              averageSpeedLabel.text = String(format: " %.2f km/h", averageSpeed)
          } else {
              averageSpeedLabel.text = "N/A"
          }
        
        if speedKmPerHour > speedLimit {
            speedWarnning.backgroundColor = UIColor.red
        } else {
            speedWarnning.backgroundColor = UIColor.white
        }
        
        if let previousLocation = self.perviousLocation {
               let timeDifference = location.timestamp.timeIntervalSince(previousLocation.timestamp)
               let acceleration = (speed - previousLocation.speed) / timeDifference
               let tempAcc = abs(acceleration)
               
               if tempAcc > maxAcc {
                   maxAcc = tempAcc
               }
           }

        maxAccelerationLabel.text = String(format: " %.2f m/s^2", maxAcc / 3.6)
        
        if speedKmPerHour < speedLimit {
            distanceBeforeExceedingLimit += location.distance(from: perviousLocation ?? location) / 1000.0
                }
        
        self.perviousLocation = locationDistance
    }
    
    func calculateAverageSpeed() -> Double {
        guard speeds.count > 0 else {
            return 0.0
        }
        let sumSpeeds = speeds.reduce(0, +)
        let averageSpeed = sumSpeeds / Double(speeds.count)
        return averageSpeed
    }
    
    func checkForPermission() -> Bool {
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
                    case .authorizedAlways, .authorizedWhenInUse:
                        // Location permissions are granted
                        return true
                    case .notDetermined, .restricted, .denied:
                	        // Location permissions are not granted
                        return false
                    @unknown default:
                        return false
            }
        }else {
            return false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
}

