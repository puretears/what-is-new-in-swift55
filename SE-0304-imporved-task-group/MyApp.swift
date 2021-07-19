//
//  main.swift
//  SE-0304-imporved-throwing-task-group
//
//  Created by Mars on 2021/7/10.
//

import Foundation

enum Food {
  case vegetable
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
  func chopVegetable() async -> Preparation {
    print("Chopping vegetables")
    return .ingredient(.vegetable)
  }

  func marinateMeat() async -> Preparation {
    print("Marinate meat")
    return .ingredient(.meat)
  }
}

func makeDinnerWithTaskGroup() async -> Meal {
  var foods: [Food] = []
  let oven = Oven()

  await withTaskGroup(of: Preparation.self) {
    group in
    let dinner = Dinner()
    
    group.async {
      await dinner.chopVegetable()
    }
    
    group.async {
      await dinner.marinateMeat()
    }
    
    group.async {
      await oven.preheatOven()
    }
    
    while let prep = await group.next(),
      case Preparation.ingredient(let food) = prep {
      foods.append(food)
    }
  }

  return oven.cook(foods, seconds: 300)
}

@main
struct MyApp {
  static func main() async {
    _ = await makeDinnerWithTaskGroup()
  }
}
