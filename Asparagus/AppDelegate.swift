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
      let syncService = SyncService(issueService: issueService, localTaskService: localTaskService)
      let leftViewModel = LeftViewModel(authService: AuthService(), coordinator: sceneCoordinator)
      let taskViewModel = TaskViewModel(issueService: issueService,
                                        coordinator: sceneCoordinator,
                                        localTaskService: localTaskService,
                                        syncService: syncService)
      let sideBarScene = Scene.sidebar(leftViewModel, taskViewModel)
      sceneCoordinator.transition(to: sideBarScene, type: .root)
      
      let navigationBarAppearace = UINavigationBar.appearance()
      navigationBarAppearace.tintColor = UIColor(hex: "2E3136")
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

