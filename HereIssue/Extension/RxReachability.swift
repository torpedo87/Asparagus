//
//  RxReachability.swift
//  HereIssue
//
//  Created by junwoo on 2018. 2. 27..
//  Copyright © 2018년 samchon. All rights reserved.
//

import Foundation
import RxSwift
import SystemConfiguration

class Reachability: NSObject {
  static let shared = Reachability()
  fileprivate override init() {}
  
  enum Status {
    case offline
    case online
    case unknown
    
    init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
      let connectionRequired = flags.contains(.connectionRequired)
      let isReachable = flags.contains(.reachable)
      
      if !connectionRequired && isReachable {
        self = .online
      } else {
        self = .offline
      }
    }
  }
  
  private var reachability: SCNetworkReachability?
  fileprivate static var _status = BehaviorSubject<Reachability.Status>(value: .unknown)
  
  func startMonitor(_ host: String) {
    var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    
    if let reachability = SCNetworkReachabilityCreateWithName(nil, host) {
      SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
        let status = Status(reachabilityFlags: flags)
        Reachability._status.onNext(status)
      }, &context)
      
      SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
      self.reachability = reachability
    }
  }
  
  func stopMonitor() {
    if let _reachability = reachability {
      SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
      reachability = nil
    }
  }
}

extension Reactive where Base: Reachability {
  static var status: Observable<Reachability.Status> {
    return Reachability._status.asObservable()
      .distinctUntilChanged()
  }
}
