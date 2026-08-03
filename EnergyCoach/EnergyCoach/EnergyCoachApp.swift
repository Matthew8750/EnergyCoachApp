//
//  EnergyCoachApp.swift
//  EnergyCoach
//
//  Created by helen robinson on 11/07/2026.
//

import SwiftUI
import UIKit
import UserNotifications

extension Notification.Name {
    static let openEnergyCheckIn = Notification.Name("openEnergyCheckIn")
}

final class EnergyCoachAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "energyCoach.dailyReminder" {
            UserDefaults.standard.set(true, forKey: "openDailyCheckInOnLaunch")
            NotificationCenter.default.post(name: .openEnergyCheckIn, object: nil)
        }
        completionHandler()
    }
}

@main
struct EnergyCoachApp: App {
    @UIApplicationDelegateAdaptor(EnergyCoachAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
