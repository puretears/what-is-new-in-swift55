//
//  main.swift
//  SE-0306-actors
//
//  Created by Mars on 2021/7/22.
//
//
//  main.swift
//  SE-0306-unsafe-class-state
//
//  Created by Mars on 2021/7/26.
//

import Foundation

actor BankAccount {
  let number: Int
  var balance: Double
  
  init(number: Int, balance: Double) {
    self.number = number
    self.balance = balance
  }
}

extension BankAccount {
  func deposit(amount: Double) -> Double {
    balance += amount
    sleep(1)
    return balance
  }
}

@main
struct MyApp {
  static func main() async {
    let account11 = BankAccount(number: 11, balance: 100)
    
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        print(await account11.deposit(amount: 100))
      }
      
      group.addTask {
        print(await account11.deposit(amount: 100))
      }
    }
  }
}


