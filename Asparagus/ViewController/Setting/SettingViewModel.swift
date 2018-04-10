//
//  SettingViewModel.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 10..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action

struct SettingViewModel {
  let authService: AuthServiceRepresentable
  let sceneCoordinator: SceneCoordinatorType
  
  init(authService: AuthServiceRepresentable,
       sceneCoordinator: SceneCoordinatorType) {
    self.authService = authService
    self.sceneCoordinator = sceneCoordinator
  }
  
  var sectionedItems: Observable<[SettingSection]> {
    return authService.isLoggedIn.asObservable()
      .map({ bool in
        var connectModel: SettingModel
        if bool {
          connectModel = SettingModel.text("DisConnect with GitHub")
        } else {
          connectModel = SettingModel.text("Connect with GitHub")
        }
        var licenseModels = [SettingModel]()
        License.arr.forEach({ license in
          let model = SettingModel.license(license)
          licenseModels.append(model)
        })
        return [
          SettingSection(header: "Connect", items: [connectModel]),
          SettingSection(header: "License", items: licenseModels)
        ]
      })
  }
  
  func dismissView() -> CocoaAction {
    return CocoaAction {
      return self.sceneCoordinator.pop().asObservable().map{ _ in }
    }
  }
  
  func onAuthTask(isLoggedIn: Bool) -> Action<(String, String), AuthService.AccountStatus> {
    return Action { tuple in
      if isLoggedIn {
        return self.authService.removeToken(userId: tuple.0, userPassword: tuple.1)
      } else {
        return self.authService.requestToken(userId: tuple.0, userPassword: tuple.1)
      }
    }
  }
  
  func onAuth() -> Completable {
    let isLoggedIn = UserDefaults.loadToken() != nil
    let authViewModel = AuthViewModel(authService: self.authService,
                                      coordinator: self.sceneCoordinator,
                                      authAction: self.onAuthTask(isLoggedIn: isLoggedIn))
    let authScene = Scene.auth(authViewModel)
    return self.sceneCoordinator.transition(to: authScene, type: .push)
  }
  
  func goToLicenseUrl(urlString: String) {
    if let url = URL(string: urlString) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }
}
