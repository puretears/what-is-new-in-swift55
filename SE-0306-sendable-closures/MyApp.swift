//
//  main.swift
//  SE-0306-sendable-closures
//
//  Created by Mars on 2021/7/24.
//

import Foundation

struct Person {
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

class Bank {
  var accounts: [BankAccount]
  init(accounts: [BankAccount] = []) {
    self.accounts = accounts
  }
  
  func requestToClose(_ accountNumber: Int) async {
    print("Closing account: \(accountNumber).")
  }
  
  func filterAccount(
    _ criteria: @Sendable (BankAccount) -> Bool) -> [BankAccount] {
    return accounts.filter(criteria)
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

  ///
  ///
  /// Cannot access `owners` in a non-isolated context.
  /// ```swift
  /// func secondaryOwners() async -> [Person] {
  ///   return await Task.detached {
  ///     await self.owners.filter {
  ///       $0.name != self.owners[0].name
  ///     }
  ///   }.value
  /// }
  /// ```
  
  func secondaryOwners() -> [Person] {
    let primaryName = owners[0].name
    return owners.filter { $0.name != primaryName }
  }
}

func primaryOwner(of account: BankAccount) async -> Person {
  return await account.primaryOwner()
}

extension Array {
  func parallelForEach(_ fn: @escaping @Sendable (Element) -> Void) async {
    await withTaskGroup(of: Void.self) { group in
      for element in self {
        group.addTask {
          fn(element)
        }
      }
    }
  }
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
    
    let bank = Bank()
    
    /// <1>: ✅ No captures
    _ = bank.filterAccount { $0.number != 11 }
    
    /// <2>: ✅ `boxueAccount` is a constant and @Sendable object,
    /// it is captured by value implicitly.
    /// But if we change `boxueAccount` to a `var`, we have to call
    /// `filterAccount` like this:
    ///
    /// ```swift
    /// _ = bank.filterAccount {
    ///   [boxueAccount] in
    ///   $0.number == boxueAccount.number
    /// }
    /// ```
    _ = bank.filterAccount {
      $0.number == boxueAccount.number
    }
    
    /// <3>: ❌ `value` must be caputured explicitly.
    /// var value = 11
    /// _ = bank.filterAccount {
    ///   $0.number == value /// Compile Time Error
    /// }
  
    let arr = [1, 2, 3, 4, 5, 6, 7]
    
    var counter = 10
    
    await arr.parallelForEach { [counter] in
      print("\(counter + $0)")
    }
    
    
    func mutateLocalState1(value: Int) {
      counter += value
    }
    
//    await arr.parallelForEach(mutateLocalState1)
    
    @Sendable
    func mutateLocalState2(value: Int) {
      // Error: 'state' is captured as a let because of @Sendable
//      counter += value
      print(value)
    }

    // Ok, mutateLocalState2 is @Sendable.
    await arr.parallelForEach(mutateLocalState2)
  }
}

