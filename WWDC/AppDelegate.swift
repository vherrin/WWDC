//
//  AppDelegate.swift
//  WWDC
//
//  Created by Guilherme Rambo on 18/04/15.
//  Copyright (c) 2015 Guilherme Rambo. All rights reserved.
//

import Cocoa
import Crashlytics
import Updater

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?
	
    private var downloadListWindowController: DownloadListWindowController?
    private var preferencesWindowController: PreferencesWindowController?
    
    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return false
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSUserDefaults.standardUserDefaults().registerDefaults(["NSApplicationCrashOnExceptions": true])
        
        // prefetch info for the about window
        About.sharedInstance.load()
        
        // start checking for live event
        LiveEventObserver.SharedObserver().start()
        
        // check for updates
        checkForUpdates(nil)
        
        // Keep a reference to the main application window
        window = NSApplication.sharedApplication().windows.last 
        
        // continue any paused downloads
        VideoStore.SharedStore().initialize()
        
        // initialize Crashlytics
        GRCrashlyticsHelper.install()
        
        // tell user about nice new things
        showCourtesyDialogs()
    }
    
    func applicationWillFinishLaunching(notification: NSNotification) {
        // register custom URL scheme handler
        URLSchemeHandler.SharedHandler().register()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
	
    private var checkForUpdatesTimer: NSTimer?
    
    @IBAction func checkForUpdates(sender: AnyObject?) {
        if WWDCDatabase.sharedDatabase.config.isWWDCWeek && checkForUpdatesTimer == nil {
            checkForUpdatesTimer = NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: #selector(checkForUpdates(_:)), userInfo: nil, repeats: true)
        }
        
        UDUpdater.sharedUpdater().updateAutomatically = true
        UDUpdater.sharedUpdater().checkForUpdatesWithCompletionHandler { newRelease in
            if newRelease != nil {
                if sender != nil && !(sender is NSTimer) {
                    let alert = NSAlert()
                    alert.messageText = "New version available"
                    alert.informativeText = "Version \(newRelease.version) is now available. It will be installed automatically the next time you launch the app."
                    alert.addButtonWithTitle("Ok")
                    alert.runModal()
                } else {
                    let notification = NSUserNotification()
                    notification.title = "New version available"
                    notification.informativeText = "A new version is available, relaunch the app to update"
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
            } else {
                if sender != nil && !(sender is NSTimer) {
                    let alert = NSAlert()
                    alert.messageText = "You're up to date!"
                    alert.informativeText = "You have the newest version"
                    alert.addButtonWithTitle("Ok")
                    alert.runModal()
                }
            }
        }
    }
    
    @IBAction func showDownloadsWindow(sender: AnyObject?) {
        if downloadListWindowController == nil {
            downloadListWindowController = DownloadListWindowController()
        }
        
        downloadListWindowController?.showWindow(self)
    }
    
    @IBAction func showPreferencesWindow(sender: AnyObject?) {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        
        preferencesWindowController?.showWindow(self)
    }
    
    // MARK: - Courtesy Dialogs
    
    private func showCourtesyDialogs() {
        NewWWDCGreeter().presentAutomaticRefreshSuggestionIfAppropriate()
    }
    
    // MARK: - About Panel
    
    private lazy var aboutWindowController: AboutWindowController = {
        var aboutWC = AboutWindowController(infoText: About.sharedInstance.infoText)
        
        About.sharedInstance.infoTextChangedCallback = { newText in
            self.aboutWindowController.infoText = newText
        }
        
        return aboutWC
    }()
    
    @IBAction func showAboutWindow(sender: AnyObject?) {
        aboutWindowController.showWindow(sender)
    }

}

