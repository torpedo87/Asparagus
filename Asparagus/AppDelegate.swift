//
//  AppDelegate.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import SnapKit
import UserNotifications
import RxSwift
import RxCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let testing = NSClassFromString("XCTest") != nil

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    if !testing {
      Reachability.shared.startMonitor("github.com")
      let sceneCoordinator = SceneCoordinator()
      self.window = sceneCoordinator.window
      let issueService = IssueService()
      let localTaskService = LocalTaskService()
      let authService = AuthService()
      let syncService = SyncService(issueService: issueService, localTaskService: localTaskService)
      
      let repositoryViewModel = RepositoryViewModel(authService: authService,
                                        syncService: syncService,
                                        issueService: issueService,
                                        coordinator: sceneCoordinator,
                                        localTaskService: localTaskService)
      let menuScene = Scene.repository(repositoryViewModel)
      
      sceneCoordinator.transition(to: menuScene, type: .root)
      
      let navigationBarAppearace = UINavigationBar.appearance()
      navigationBarAppearace.tintColor = UIColor(hex: "7DC062")
      navigationBarAppearace.barTintColor = UIColor.white
      navigationBarAppearace.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(hex: "283A45")]
      
      UNUserNotificationCenter.current().requestAuthorization(options: .badge) { (granted, error) in
        if error != nil {
          print("reject noti")
        } else {
          print("accep noti")
        }
      }
    }
    return true
  }
}

