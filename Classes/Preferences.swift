//
//  Preferences.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

final class Preferences: NSObject {
    private enum AppPreference: String {
        case OpenZoomedOut = "zoomed_out"
        case AutoDownload = "autodownload"
        case OpenAfterDownload = "autoopen"
    }

    private let userDefaults: NSUserDefaults

    private static var defaultPreferenceStorage: Preferences?

    class func defaultPreferences() -> Preferences {
        if let preferences = Preferences.defaultPreferenceStorage {
            return preferences
        }
        else {
            let preferences = Preferences(userDefaults: NSUserDefaults.standardUserDefaults())
            Preferences.defaultPreferenceStorage = preferences
            return preferences
        }
    }

    init(userDefaults: NSUserDefaults) {
        self.userDefaults = userDefaults

        super.init()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationWillTerminate:"), name: UIApplicationWillTerminateNotification, object: nil)
    }

    // MARK: - NSUserDefaults Access

    func openZoomedOut() -> Bool {
        return boolValueOfAppPreference(.OpenZoomedOut)
    }

    func downloadNewComics() -> Bool {
        return boolValueOfAppPreference(.AutoDownload)
    }

    func openAfterDownload() -> Bool {
        return boolValueOfAppPreference(.OpenAfterDownload)
    }

    // MARK: - Notifications

    @objc func applicationWillTerminate(notification: NSNotification?) {
        userDefaults.synchronize()
    }

    // MARK: - Private

    private func boolValueOfAppPreference(appPreference: AppPreference, defaultValue: Bool = false) -> Bool {
        if let value = userDefaults.dictionaryRepresentation()[appPreference.rawValue] as? Bool {
            return value
        }
        else {
            userDefaults.setBool(defaultValue, forKey: appPreference.rawValue)
            return defaultValue
        }
    }
}
