//
//  AppDelegate.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import SnapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let testing = NSClassFromString("XCTest") != nil

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    if !testing {
      Reachability.shared.startMonitor("github.com")
      let sceneCoordinator = SceneCoordinator()
      self.window = sceneCoordinator.window
      let account = AuthService().status
      let issueService = IssueService()
      let taskService = TaskService()
      let taskViewModel = TaskViewModel(account: account,
                                        issueService: issueService,
                                        coordinator: sceneCoordinator,
                                        taskService: taskService)
      let taskScene = Scene.task(taskViewModel)
      sceneCoordinator.transition(to: taskScene, type: .root)
    }
    return true
  }

}

