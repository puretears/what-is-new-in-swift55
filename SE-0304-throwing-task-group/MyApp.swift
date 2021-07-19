//
//  main.swift
//  SE-0304-imporved-throwing-task-group
//
//  Created by Mars on 2021/7/10.
//

import Foundation

enum Food {
  case vegetable(String)
  case meat
}

enum Preparation {
  case ingredient(Food)
  case device
}

struct Meal {}

struct Oven {
  func preheatOven() async -> Preparation {
    print("Preheat oven.")
    return .device
  }

  func cook(_ foods: [Food], seconds: Int) -> Meal {
    print("Cook \(seconds) seconds.")
    return Meal()
  }
}

struct Dinner {
  enum Accident: Error {
    case knifeError
  }
  
  func chop(names: [String]) async throws -> [Food] {
    var veggies: [Food] = []
    
    try await withThrowingTaskGroup(of: Preparation.self) { group in
      for name in names {
        group.async {
          try await chopVegetable(name: name)
        }
      }
      
      while let prep = try await group.next(),
        case .ingredient(let veggie) = prep {
        if veggies.count >= 3 {
          group.cancelAll()
          /**
           The result of the following task will be discarded
           ```swift
           group.async {
             return .vegetable("cabbage")
           }
           ```
           */
          break
        }
        else {
          veggies.append(veggie)
        }
      }
    }
    
    return veggies
  }
  
  func chopVegetable(name: String) async throws -> Preparation {
    if name == "rock" {
      throw Accident.knifeError
    }
    
    print("Chopping vegetables")
    return .ingredient(.vegetable(name))
  }

  func marinateMeat() async -> Preparation {
    print("Marinate meat")
    return .ingredient(.meat)
  }
}

func makeDinnerWithThrowingTaskGroup() async throws -> Meal {
  var foods: [Food] = []
  let oven = Oven()

  try await withThrowingTaskGroup(of: Preparation.self) {
    group in
    let dinner = Dinner()
    
    group.async {
      try await dinner.chopVegetable(name: "rock")
    }
    
    group.async {
      try Task.checkCancellation()
      return await dinner.marinateMeat()
    }

    group.async {
      await oven.preheatOven()
    }
    
    while let prep = try await group.next(),
      case Preparation.ingredient(let food) = prep {
      foods.append(food)
    }
  }

  return oven.cook(foods, seconds: 300)
}

@main
struct MyApp {
  static func main() async {
//    do {
//      _ = try await makeDinnerWithThrowingTaskGroup()
//    }
//    catch {
//      print(error.localizedDescription)
//    }
    
    let veggies = try? await Dinner().chop(
      names: ["tomato", "cucumber", "celery", "cabbage"])
    
    print(veggies ?? [])
  }
}


