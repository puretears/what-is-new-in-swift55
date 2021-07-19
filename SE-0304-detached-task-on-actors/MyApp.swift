//
//  main.swift
//  SE-0304-detached-task-on-actors
//
//  Created by Mars on 2021/7/13.
//

import Foundation

actor AtomicIncrementor {
  private var value: Int = 0
  
  func current() -> Int {
    return value
  }
  
  func increment() {
    /// Cannot compile:
    /// Task.detached {
    ///   self.value += 1
    /// }
    
    Task {
      value += 1
    }
  }
}

@main
struct MyApp {
  static func main() async {
    let incrementor = AtomicIncrementor()
    print("Current value: \(await incrementor.current())")
    
    await incrementor.increment()
    print("Current value: \(await incrementor.current())")
  }
}

