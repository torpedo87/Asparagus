//
//  AuthService.swift
//  Asparagus
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol AuthServiceRepresentable {
  var loginStatus: BehaviorSubject<Bool> { get }
  func requestToken(userId: String, userPassword: String) -> Observable<AuthService.AccountStatus>
  func removeToken(userId: String, userPassword: String) -> Observable<AuthService.AccountStatus>
  func getUser() -> Observable<User>
}

struct AuthService: AuthServiceRepresentable {
  var loginStatus = BehaviorSubject<Bool>(value: false)
  
  init() {
    if let _ = UserDefaults.loadToken() {
      loginStatus.onNext(true)
    } else {
      loginStatus.onNext(false)
    }
  }
  
  enum AccountError: Error {
    case requestFail
    case invalidUserInfo
  }
  
  enum AccountStatus {
    case unavailable(String)
    case authorized(Token?)
  }
  
  func requestToken(userId: String, userPassword: String) -> Observable<AccountStatus> {
    
    guard let url =
      URL(string: "https://api.github.com/authorizations") else { fatalError() }
    
    let request: Observable<URLRequest> = Observable.create{ observer in
      let request: URLRequest = {
        var request = URLRequest(url: $0)
        let userInfoString = userId + ":" + userPassword
        guard let userInfoData =
          userInfoString.data(using: String.Encoding.utf8) else { fatalError() }
        let base64EncodedCredential = userInfoData.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential)"
        request.httpMethod = "POST"
        request.addValue(authString, forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let bodyObject: [String: Any] = [
          "scopes": [
            "public_repo"
          ],
          "note": UUID().uuidString
        ]
        
        request.httpBody =
          try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        return request
      }(url)
      
      observer.onNext(request)
      observer.onCompleted()
      return Disposables.create()
    }
    
    return request.flatMap{
      URLSession.shared.rx.response(request: $0)
      }
      .map({ (response, data) -> AccountStatus in
        if 200 ..< 300 ~= response.statusCode {
          let token = try! JSONDecoder().decode(Token.self, from: data)
          UserDefaults.saveToken(token: token)
          self.loginStatus.onNext(true)
          return AccountStatus.authorized(token)
        } else if 401 == response.statusCode {
          throw AccountError.invalidUserInfo
        } else {
          throw AccountError.requestFail
        }
      })
      .catchError({ (error) -> Observable<AccountStatus> in
        if let error = error as? AccountError {
          switch error {
          case .requestFail:
            return Observable.just(AccountStatus.unavailable("requestFail"))
          case .invalidUserInfo:
            return Observable.just(AccountStatus.unavailable("invalidUserInfo"))
          }
        }
        return Observable.just(.unavailable(error.localizedDescription))
      })
    
  }
  
  func removeToken(userId: String, userPassword: String) -> Observable<AccountStatus> {
    guard let tokenId = UserDefaults.loadToken()?.id else { fatalError() }
    guard let url =
      URL(string: "https://api.github.com/authorizations/\(tokenId)") else { fatalError() }
    
    let request: Observable<URLRequest> = Observable.create { (observer) -> Disposable in
      let request: URLRequest = {
        var request = URLRequest(url: $0)
        let userInfoString = userId + ":" + userPassword
        guard let userInfoData =
          userInfoString.data(using: String.Encoding.utf8) else { fatalError() }
        let base64EncodedCredential = userInfoData.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential)"
        request.httpMethod = "DELETE"
        request.addValue(authString, forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        return request
      }(url)
      
      observer.onNext(request)
      observer.onCompleted()
      return Disposables.create()
    }
    
    return request.flatMap({
      URLSession.shared.rx.response(request: $0)
    })
      .map({ (response, data) -> AccountStatus in
        if 200..<300 ~= response.statusCode {
          UserDefaults.removeLocalToken()
          UserDefaults.removeMe()
          self.loginStatus.onNext(false)
          return .authorized(nil)
        } else if 401 == response.statusCode {
          throw AccountError.invalidUserInfo
        } else {
          throw AccountError.requestFail
        }
      })
      .catchError({ (error) -> Observable<AccountStatus> in
        if let error = error as? AccountError {
          switch error {
          case .requestFail:
            return Observable.just(.unavailable("requestFail"))
          case .invalidUserInfo:
            return Observable.just(.unavailable("invalidUserInfo"))
          }
        }
        return Observable.just(.unavailable(error.localizedDescription))
      })
  }
  
  func getUser() -> Observable<User> {
    guard let token = UserDefaults.loadToken()?.token else { fatalError() }
    guard let urlComponents = URLComponents(string: "https://api.github.com/user") else { fatalError() }
    
    let request: Observable<URLRequest> = Observable.create{ observer in
      let request: URLRequest = {
        var request = URLRequest(url: $0)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
      }(urlComponents.url!)
      
      observer.onNext(request)
      observer.onCompleted()
      return Disposables.create()
    }
    
    return request.flatMap{
      URLSession.shared.rx.response(request: $0)
      }
      .map({ (response, data) -> User in
        if 200 ..< 300 ~= response.statusCode {
          let me = try! JSONDecoder().decode(User.self, from: data)
          return me
        } else {
          throw AccountError.requestFail
        }
      })
      .catchError({ (error) -> Observable<User> in
        return Observable.empty()
      })
  }
}
