//
//  ViewController.swift
//  EventKitDemo
//
//  Created by Vikash Kumar on 02/06/17.
//  Copyright © 2017 Vikash Kumar. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

class ViewController: UIViewController {

    @IBOutlet var eventsTable: UITableView!
    
    let eventStore = EKEventStore()
    var events = [EKEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkCalanderAuthorizationStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func checkCalanderAuthorizationStatus() {
       let status =  EKEventStore.authorizationStatus(for: EKEntityType.event)
        switch status {
        case .notDetermined:
            self.requestCalanderEventPermission()
        case .authorized:
            self.loadEvents()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPermissionView()
            }
        }
    }
    
    //request for calander events
    func requestCalanderEventPermission() {
        eventStore.requestAccess(to: .event) { (isGranted, error) in
            if isGranted {
                //do your task here
            } else {
                if let err = error {
                    print(err.localizedDescription)
                }

            }
            
        }
    }
    
    func showPermissionView() {
        let alert = UIAlertController(title: "EventKit", message: "We need access your calander in order to help you track events.", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let setting = UIAlertAction(title: "Settings", style: .destructive) { (alert) in
            let settingUrl = URL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.shared.open(settingUrl, options: [:], completionHandler: nil)
        }
        alert.addAction(cancel)
        alert.addAction(setting)
        self.present(alert, animated: true, completion: nil)
    }

    func loadEvents() {
       let startDate = Date()
        let endDate = Date.distantFuture
        
        let localCalenders = eventStore.calendars(for: .event).filter { $0.type == EKCalendarType.local}
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: localCalenders)

        events = eventStore.events(matching: predicate)
        eventsTable.reloadData()
    }
}


extension ViewController: UITableViewDataSource, UITableViewDelegate  {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        let event = events[indexPath.row]
        cell.lblTitle.text = event.title
        cell.lblSubTitle.text  = event.location ?? "Location not available."
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = events[indexPath.row]
        let eventVC = EKEventEditViewController()
        eventVC.event = event
        eventVC.eventStore = eventStore
        //let navi = UINavigationController(rootViewController: eventVC)
        eventVC.editViewDelegate = self
        self.present(eventVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, iPath) in
           let event =  self.events.remove(at: iPath.row)
            self.eventsTable.reloadData()
           try! self.eventStore.remove(event, span: .futureEvents)
        }
        return [deleteAction]
    }
}

extension ViewController : EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        //try! eventStore.save(controller.event!, span: .futureEvents)
        eventsTable.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }
}

extension ViewController {
    @IBAction func addEvent_clicked(sender: UIButton) {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Vikash's event"
        event.location = "Azure Hotel, Ahmedabad"
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(450000)
        event.calendar = eventStore.defaultCalendarForNewEvents
        let alarm = EKAlarm(relativeOffset: Date().timeIntervalSinceNow + 3600)
       event.addAlarm(alarm)
        try! eventStore.save(event, span: .futureEvents)
        events.append(event)
        eventsTable.reloadData()
    }
}

class TableViewCell: UITableViewCell {
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblSubTitle: UILabel!
    
}



