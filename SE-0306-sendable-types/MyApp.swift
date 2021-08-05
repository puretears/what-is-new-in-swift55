//
//  main.swift
//  SE-0306-sendable-types
//
//  Created by Mars on 2021/7/23.
//

import Foundation

/// A `Sendable` class:
///
/// ```swift
/// final class Person : Sendable {
///   let name: String
///
///   init(name: String) {
///     self.name = name
///   }
/// }
/// ```
///
/// A `Sendable` struct:
///
/// ```swift
/// struct Person {
///   let name: String
///
///   init(name: String) {
///     self.name = name
///   }
/// }
/// ```

class Person {
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

class Bank {
  func requestToClose(_ accountNumber: Int) async {
    print("Closing account: \(accountNumber).")
  }
}

actor BankAccount {
  
  let number: Int
  var balance: Double
  var owners: [Person]
  var isOpen: Bool = true
  
  init(number: Int, balance: Double, owners: [Person]) {
    self.number = number
    self.balance = balance
    self.owners = owners
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

extension BankAccount {
  func primaryOwner() -> Person {
    return owners[0]
  }
}

func primaryOwner(of account: BankAccount) async -> Person {
  return await account.primaryOwner()
}

@main
struct MyApp {
  static func main() async {
    let boxueAccount = BankAccount(
      number: 1110, balance: 100,
      owners: [
        Person(name: "10"),
        Person(name: "11")
      ])
    
    Task.detached {
      let account = await boxueAccount.primaryOwner()
      account.name = "bx10";
    }
    
    Task.detached {
      /// If `Person` is not a `Sendable` type, here
      /// should be a compile time error:
      /// "Call to actor-isolated method `primaryOwner`
      /// renturns non-Sendable `Person`."
      let account = await boxueAccount.primaryOwner()
      account.name = "BX10";
    }
    
    for account in await boxueAccount.owners {
      print(account.name)
    }
  }
}
