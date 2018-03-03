//
//  AuthService.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol AuthServiceRepresentable {
  var isLoggedIn: Driver<Bool> { get }
  var status: Driver<AuthService.AccountStatus> { get }
  func requestToken(userId: String, userPassword: String) -> Observable<AuthService.AccountStatus>
  func removeToken(userId: String, userPassword: String) -> Observable<AuthService.AccountStatus>
}

struct AuthService: AuthServiceRepresentable {
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
          //토큰저장을 여기서 하면 안될듯
          UserDefaults.saveToken(token: token)
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
  
  var status: Driver<AccountStatus> {
    return Observable.create { observer in
      if let token = UserDefaults.loadToken() {
        observer.onNext(.authorized(token))
      } else {
        observer.onNext(.unavailable("caanot load token"))
      }
      return Disposables.create()
      }
      .asDriver(onErrorJustReturn: .unavailable("unAuthorized"))
  }
  
  var isLoggedIn: Driver<Bool> {
    return Observable.create { observer in
      if let _ = UserDefaults.loadToken() {
        observer.onNext(true)
      } else {
        observer.onNext(false)
      }
      return Disposables.create()
      }
      .asDriver(onErrorJustReturn: false)
  }
}
