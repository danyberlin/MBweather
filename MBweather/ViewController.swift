//
//  ViewController.swift
//  MBweather
//
//  Created by Daniel Goldgamer on 11.06.20.
//  Copyright © 2020 Daniel Goldgamer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBAction func quitWeather(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    @IBAction func refresh(_ sender: Any) {
        appDelegate?.getWeather()
        sleep(1)
        updateAll()
    }
    @IBOutlet weak var lastRefresh: NSTextField!
    @IBOutlet weak var cityName: NSTextField!
    @IBOutlet weak var weatherIcon: NSImageView!
    @IBOutlet weak var weather_feelsLike: NSTextField!
    @IBOutlet weak var sys_sunset: NSTextField!
    @IBOutlet weak var sys_sunrise: NSTextField!
    @IBOutlet weak var weather_current: NSTextField!

    @IBOutlet weak var weather_description: NSTextField!
    @IBOutlet weak var weather_tempMin: NSTextField!
    @IBOutlet weak var weather_tempMax: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        updateAll()
    }
    let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
    
    func updateAll(){
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "HH:mm"
        lastRefresh.stringValue = "Last: " + dateFormater.string(from: (appDelegate?.date)!)
        cityName.stringValue = String(appDelegate!.fullResponse.name)
        let sunset = NSDate(timeIntervalSince1970: TimeInterval((appDelegate?.fullResponse.sys.sunset)!))
        let sunrise = NSDate(timeIntervalSince1970: TimeInterval((appDelegate?.fullResponse.sys.sunrise)!))
        sys_sunset.stringValue = dateFormater.string(from: sunset as Date)
        sys_sunrise.stringValue = dateFormater.string(from: sunrise as Date)
        weather_current.stringValue = String(format: " %.1f",(appDelegate!.fullResponse.main.temp) - 273.15) + "℃"
        weather_feelsLike.stringValue = String(format: "%.1f",(appDelegate!.fullResponse.main.feels_like) - 273.15) + "℃"
        weather_tempMin.stringValue = String(format: "%.1f",(appDelegate!.fullResponse.main.temp_min) - 273.15) + "℃"
        weather_tempMax.stringValue = String(format: "%.1f",(appDelegate!.fullResponse.main.temp_max) - 273.15) + "℃"
        weather_description.stringValue = String((appDelegate?.fullResponse.weather[0].description)!)
        let img = NSImage(named: appDelegate!.fullResponse.weather[0].icon )
        weatherIcon.image = img
//        weatherIcon.image = NSImage(named: "03n" )
    }
    
}
extension ViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> ViewController {
    //1.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    //2.
    let identifier = NSStoryboard.SceneIdentifier("ViewController")
    //3.
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
      fatalError("Why cant i find QuotesViewController? - Check Main.storyboard")
    }
    return viewcontroller
  }
}
