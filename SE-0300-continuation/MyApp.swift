//
//  main.swift
//  SE-0300-continuation
//
//  Created by Mars on 2021/7/19.
//

import Foundation

struct Vegetable: Hashable {
  let name: String
}

let veggiesInStore: Set<String> = [
  "cucumber",
  "celery",
  "cauliflower",
  "eggplant",
  "cabbage"
]

enum StoreError: Error {
  case outOfStock
}

func buyVegetable(
  shoppingList: Set<String>,
  onAllAvailable: (Set<Vegetable>) -> Void,
  onOneAvailable: (Vegetable) -> Void,
  onNoMoreAvailable: () -> Void,
  onNoVegetableAtAll: (StoreError) -> Void
) {
  if shoppingList.isSubset(of: veggiesInStore) {
    onAllAvailable(
      Set<Vegetable>(shoppingList.map { Vegetable(name: $0) })
    )
  }
  else {
    let veggies = shoppingList.intersection(veggiesInStore)
    
    if veggies.isEmpty {
      onNoVegetableAtAll(StoreError.outOfStock)
    }
    else {
      shoppingList
        .subtracting(veggiesInStore)
        .map {
          Vegetable(name: $0)
        }.forEach {
          onOneAvailable($0)
        }
      onNoMoreAvailable()
    }
  }
}

func buyVegetable(shoppingList: Set<String>) async throws -> Set<Vegetable> {
  try await withUnsafeThrowingContinuation { continuation in
    var veggies: Set<Vegetable> = []
    
    buyVegetable(
      shoppingList: shoppingList,
      onAllAvailable: {
        continuation.resume(returning: $0)
      },
      onOneAvailable: {
        veggies.insert($0)
      },
      onNoMoreAvailable: {
        continuation.resume(returning: veggies)
      },
      onNoVegetableAtAll: {
        continuation.resume(throwing: $0)
      })
  }
}

@main
struct MyApp {
  static func main() async {
//    buyVegetable(
//      shoppingList: ["celery", "eggplant", "cauliflower"],
//      onAllAvailable: { veggies in
//        let nameList = veggies.map { $0.name }.joined(separator: ",")
//        print("All veggies are available.")
//        print("Bought: \(nameList)")
//      },
//      onOneAvailable: { vege in
//        print("Bought: \(vege.name)")
//      },
//      onNoMoreAvailable: {
//        print("All available vegetables in stock were bought.")
//      },
//      onNoVegetableAtAll: {
//        print($0.localizedDescription)
//      })
    
    do {
      let veggies = try await buyVegetable(
        shoppingList: ["celery", "eggplant", "cauliflower"])
      print(veggies)
    }
    catch {
      print("All vegetables are out of stock.")
    }
  }
}

