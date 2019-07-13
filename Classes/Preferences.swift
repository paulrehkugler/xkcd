//
//  Preferences.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

/// This class provides a thin wrapper over `NSUserDefaults` for managing users' settings.
final class Preferences: NSObject {
    private enum AppPreference: String {
        case OpenZoomedOut = "zoomed_out"
        case AutoDownload = "autodownload"
        case OpenAfterDownload = "autoopen"
    }

    /// Whether comics open at their minimum zoom scale, or at native resolution in the single comic viewer.
    @objc var openZoomedOut: Bool {
		return boolValueOfAppPreference(appPreference: .OpenZoomedOut)
    }

    /// Whether new comics images should be automatically downloaded when the comic JSON is received.
    @objc var downloadNewComics: Bool {
		return boolValueOfAppPreference(appPreference: .AutoDownload)
    }

    /// Whether comics should be opened after their images are downloaded.
    @objc var openAfterDownload: Bool {
		return boolValueOfAppPreference(appPreference: .OpenAfterDownload, defaultValue: true)
    }

    /// The instance of `NSUserDefaults` that this object reads and writes from.
	private let userDefaults: UserDefaults

    /// Holds the singleton returned by `defaultPreferences()`.
    private static var defaultPreferenceStorage: Preferences?

    /**
     A singleton `Preferences` instance that is used across the application.

     - note: Ideally we would use dependency injection instead of obfuscating the dependency graph like this.
     On the other hand, shipping is better than perfect.

     - returns: A fully initialized `Preferences`.
     */
	@objc class var defaultPreferences: Preferences {
        if let preferences = Preferences.defaultPreferenceStorage {
            return preferences
        }
        else {
			let preferences = Preferences(userDefaults: UserDefaults.standard)
            Preferences.defaultPreferenceStorage = preferences
            return preferences
        }
    }

    /**
     Initializes a `Preferences` object.

     - parameter userDefaults: The instance of `NSUserDefaults` to read from and write to.

     - returns: A fully initialized `Preferences` object.
     */
	init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults

        super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
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
			userDefaults.set(defaultValue, forKey: appPreference.rawValue)
            return defaultValue
        }
    }
}
