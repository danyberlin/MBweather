//
//  AppDelegate.swift
//  MBweather
//
//  Created by Daniel Goldgamer on 10.06.20.
//  Copyright © 2020 Daniel Goldgamer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var weatherTimer : Timer?
    var currentWeather = -99.9
    let menu = NSMenu()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        getWeather()
        if let button = statusItem.button {
            button.title = String(currentWeather) + "℃"
        }
        constuctMenu()
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 60*30, repeats: true) { time in
            self.getWeather()
        }
    }
    
    @objc func updateWeather(_ sender: Any?) {
        getWeather()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func getWeather(){
        let url = URL(string:     "https://api.openweathermap.org/data/2.5/weather?id=2950157&APPID=386371523446a5a1ef1272512c75f28b")
        guard let requestUrl = url else { fatalError() }
        // Create URL Request
        var request = URLRequest(url: requestUrl)
        // Specify HTTP Method to use
        request.httpMethod = "GET"
        // Send HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check if Error took place
            if let error = error {
                print("Error took place \(error)")
                return
            }
            // Read HTTP Response Status code
            if let response = response as? HTTPURLResponse {
                print("Response HTTP Status code: \(response.statusCode)")
            }
            // Convert HTTP Response Data to JSON
            struct Response: Decodable { // or Decodable
                let main : Main
                let weather : [Weather]
                let base: String
                let cod: Int
                let coord: Coord
                let sys: Sys
                let clouds: Clouds

            }
            struct Clouds: Decodable {
                let all: Int
            }
            struct Coord: Decodable {
                let lat: Double
                let lon: Double
            }
            struct Weather: Decodable {
//                let id: Int
//                let main: String
                let description: String
                let icon: String
            }
            struct Sys: Decodable {
                let country: String
                let id: Int
                let sunrise: UInt64
                let sunset: UInt64
                let type: Int
            }
            struct Main: Decodable {
//                let humidity: Int
//                let pressure: Int
                let temp: Double
//                let tempMax: Int
//                let tempMin: Int
//                private enum CodingKeys: String, CodingKey {
//                    case humidity, pressure, temp, tempMax = "temp_max", tempMin = "temp_min"
//                }
            }
            if let data = data {
                do {
                    
                    let res = try JSONDecoder().decode(Response.self, from: data)
                    self.currentWeather = res.main.temp
                    print("Main: \(res.main)")
                    print("Weather: \(res.weather[0])")
                    print("Base: \(res.base)")
                    print("Cod: \(res.cod)")
                    print("Coord: \(res.coord)")
                    print("Sys: \(res.sys)")
                    print("Clouds: \(res.clouds)")

                    DispatchQueue.main.async {
                        self.statusItem.button?.title = String(format: " %.1f",(self.currentWeather - 273.15)) + "℃"
                    }
                } catch let error {
                    print("Error! : \(error)")
                }
            }
            let date = Date()
            let dateFormater = DateFormatter()
            dateFormater.dateFormat = "HH:mm"
            self.menu.item(at: 0)?.title = "Refresh (Last: " + dateFormater.string(from: date) + ")"
        }
        task.resume()
    }
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "MBweather")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    func constuctMenu() {
        
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(AppDelegate.updateWeather(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MBweather", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        statusItem.menu = menu
    }
}

