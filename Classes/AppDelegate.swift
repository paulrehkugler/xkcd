//
//  AppDelegate.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/24/16.
//
//

import UIKit

/// This class acts as the UIApplicationDelegate of the application.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
		Comic.synchronizeDownloadedImages()

		let listViewController = ComicListViewController(style: .plain)

        if let launchURL = launchOptions?[.url] as? NSURL {
            guard launchURL.scheme == "xkcd" else {
                return false
            }

            if
                let host = launchURL.host,
                let launchedComicNumber = Int(host),
                 launchedComicNumber > 0
            {
                listViewController.requestedLaunchComic = launchedComicNumber
            }
        }

        let navigationController = TLNavigationController(rootViewController: listViewController)

		window = UIWindow(frame: UIScreen.main.bounds)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
	
	func applicationDidBecomeActive(_ application: UIApplication) {
        Comic.synchronizeDownloadedImages()
    }
}
