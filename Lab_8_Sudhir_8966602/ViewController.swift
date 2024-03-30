//
//  ViewController.swift
//  Lab_8_Sudhir_8966602
//
//  Created by user240106 on 3/29/24.
//

import UIKit
import CoreLocation

// Structures to represent the weather data from the API response
struct WeatherResponse: Codable {
    let name: String
    let weather: [Weather]
    let main: Main
    let wind: Wind
}

struct Weather: Codable {
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let humidity: Double
}

struct Wind: Codable {
    let speed: Double
}


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var city: UILabel!
    @IBOutlet weak var weather: UILabel!
    @IBOutlet weak var weatherLogo: UIImageView!
    @IBOutlet weak var temp: UILabel!
    @IBOutlet weak var humidity: UILabel!
    @IBOutlet weak var wind: UILabel!
    
    let locationManager = CLLocationManager()

    // API key for OpenWeatherMap API
    let apiKey = "d76f6a08bc053bfdaf58f959464f68ef"

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        startUpdatingLocation()
    }

    // MARK: - Location Manager Delegate Methods

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    // This method is called when the location manager receives new location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // Fetch weather data for the current location
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            fetchWeatherData(latitude: latitude, longitude: longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }

    // Check the current location authorization status and take necessary actions
    func checkLocationAuthorization() {
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied:
            print("Location access denied.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:

            print("Location access restricted.")
        @unknown default:
            break
        }
    }

    // Function to start updating location
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    // Function to stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // Function to fetch weather data from OpenWeatherMap API
    func fetchWeatherData(latitude: Double, longitude: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"

        guard let url = URL(string: urlString) else {
            print("Invalid API URL")
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching weather data: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            // Parse JSON response and create WeatherResponse object
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let weatherData = try decoder.decode(WeatherResponse.self, from: data)

                DispatchQueue.main.async {
                    self.updateUI(with: weatherData)
                }
            } catch {
                print("Error parsing JSON data: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Function to update the UI with weather data
    func updateUI(with weatherResponse: WeatherResponse) {
        city.text = weatherResponse.name
        if let weather = weatherResponse.weather.first {
            self.weather.text = weather.description
            let iconCode = weather.icon
            let iconURLString = "https://openweathermap.org/img/w/\(iconCode).png"
            if let iconURL = URL(string: iconURLString), let iconData = try? Data(contentsOf: iconURL) {
                weatherLogo.image = UIImage(data: iconData)
            }
        }
        let temperature = Int(weatherResponse.main.temp)
        temp.text = "\(temperature) °C"
        humidity.text = "Humidity: \(weatherResponse.main.humidity) %"
        wind.text = "Wind: \(weatherResponse.wind.speed) km/h"
    }
}
