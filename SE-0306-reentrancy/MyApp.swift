//
//  main.swift
//  SE-0306-reentrancy
//
//  Created by Mars on 2021/7/27.
//

import Foundation

class Bank {
  func requestToClose(_ accountNumber: Int) async {
    print("Closing account: \(accountNumber).")
  }
}

actor BankAccount {
  
  let number: Int
  var balance: Double
  var isOpen: Bool = true
  
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
    case alreadyClosed
  }
  
  func transfer(amount: Double, to other: BankAccount) async throws {
    if amount > balance {
      throw BankError.insufficientFunds
    }
    
    print("Transfering \(amount) from \(number) to \(other.number)")
    
    balance -= amount
    _ = await other.deposit(amount: amount)
  }
}

extension BankAccount {
  func close() async throws -> Void {
    if isOpen {
      await Bank().requestToClose(self.number)
      
      if isOpen {
        isOpen = false
      }
      else {
        throw BankError.alreadyClosed
      }
    }
    else {
      throw BankError.alreadyClosed
    }
  }
}

@main
struct MyApp {
  static func main() async {
    let account11 = BankAccount(number: 11, balance: 100)
    try? await account11.close()
    
    print("Account\(account11.number) balance: \(await account11.balance)")
  }
}



