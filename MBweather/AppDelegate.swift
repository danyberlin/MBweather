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
//    let viewDelegate : ViewController? = NSApplication.shared.delegate as? ViewController
    let viewDelegate = ViewController()
    var weatherTimer : Timer?
    var currentWeather = -99.9
//    let menu = NSMenu()
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        getWeather()
        if let button = statusItem.button {
            button.title = String(currentWeather) + "℃"
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = ViewController.freshController()
        popover.animates = false

//        constuctMenu()
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 60*30, repeats: true) { time in
            self.getWeather()
        }
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
          if let strongSelf = self, strongSelf.popover.isShown {
            strongSelf.closePopover(sender: event)
          }
        }
    }
    @objc func togglePopover(_ sender: Any?) {
      if popover.isShown {
        closePopover(sender: sender)
      } else {
        showPopover(sender: sender)
      }
    }

    func showPopover(sender: Any?) {
      if let button = statusItem.button {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      }
        eventMonitor?.start()
    }

    func closePopover(sender: Any?) {
      popover.performClose(sender)
        eventMonitor?.stop()
    }
    @objc func updateWeather(_ sender: Any?) {
        getWeather()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    public struct Response: Decodable { // or Decodable
                    var main : Main
                    var weather : [Weather]
                    var base: String
                    var visibility : Int
                    var cod: Int
                    var coord: Coord
                    var sys: Sys
                    var clouds: Clouds
                    var name: String
        init() {
            main = Main()
            weather = [Weather()]
            base = "response_base"
            cod = 0
            coord = Coord()
            sys = Sys()
            clouds = Clouds()
            name = "response_name"
            visibility = 0
        }
                }
                struct Clouds: Decodable {
                    var all: Int
                    init() {
                        all = 0
                    }
                }
                struct Coord: Decodable {
                    var lat: Double
                    var lon: Double
                    init() {
                        lat = 0
                        lon = 0
                    }
                }
                struct Weather: Decodable {
                    var id: Int
                    var main: String
                    var description: String
                    var icon: String
                    init() {
                        id = 0
                        main = "weather_main"
                        description = "weather_description"
                        icon = "weather_icon"
                    }
                }
                struct Sys: Decodable {
                    var country: String
                    var id: Int
                    var sunrise: UInt64
                    var sunset: UInt64
                    var type: Int
                    init() {
                        country = "sys_country"
                        id = 0
                        sunrise = 0
                        sunset = 0
                        type = 0
                    }
                }
                struct Main: Decodable {
                    var humidity: Int
                    var pressure: Int
                    var temp: Double
                    var temp_max: Double
                    var temp_min: Double
                    var feels_like : Double
                    init() {
                        humidity = 0
                        pressure = 0
                        temp = 0
                        temp_max = 0
                        temp_min = 0
                        feels_like = 0
                    }
                }
    public var fullResponse = Response()
    public var date = Date()
    public func getWeather(){
        let urlPart1 = "https://api.openweathermap.org/data/2.5/weather?id="
        let urlPartCity = "2950157"
        let urlPart3 = "&APPID="
        let urlPartApiKey = "386371523446a5a1ef1272512c75f28b"
        let urlComplete = urlPart1 + urlPartCity + urlPart3 + urlPartApiKey
        let url = URL(string:     urlComplete)
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
            if let data = data {
                do {
                    self.fullResponse = try JSONDecoder().decode(Response.self, from: data)
                    print("Main: \(self.fullResponse)")

                    DispatchQueue.main.async {
                        self.statusItem.button?.title = String(format: " %.1f",(self.fullResponse.main.temp - 273.15)) + "℃"
                    }
                } catch let error {
                    print("Error! : \(error)")
                }
            }
        }
        date = Date()
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
//    func constuctMenu() {
//
//        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(AppDelegate.updateWeather(_:)), keyEquivalent: ""))
//        menu.addItem(NSMenuItem.separator())
//        menu.addItem(NSMenuItem(title: "Quit MBweather", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
//        statusItem.menu = menu
//    }
}

