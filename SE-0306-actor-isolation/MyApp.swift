//
//  main.swift
//  SE-0306-actor-isolation
//
//  Created by Mars on 2021/7/29.
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

extension BankAccount {
  enum BankError: Error {
    case insufficientFunds
  }
  
  func transfer(amount: Double, to other: BankAccount) async throws {
    if amount > balance {
      throw BankError.insufficientFunds
    }
    
    print("Transfering \(amount) from \(number) to \(other.number)")
    
    balance -= amount
//    other.balance += amount
    _ = await other.deposit(amount: amount)
  }
}

@main
struct MyApp {
  static func main() async {
    let account10 = BankAccount(number: 10, balance: 100)
    let account11 = BankAccount(number: 11, balance: 100)
    
    await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0...4 {
        group.addTask {
          try await account10.transfer(amount: 10, to: account11)
        }
      }
    }
    
    print("Account\(account11.number) balance: \(await account11.balance)")
  }
}
