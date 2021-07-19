//
//  main.swift
//  SE-0304-task-group
//
//  Created by Mars on 2021/7/10.
//

import Foundation

enum Food {
  case vegetable
  case meat
}

struct Meal {}

struct Oven {
  func preheatOven() async {
    print("Preheat oven.")
  }

  func cook(_ foods: [Food], seconds: Int) -> Meal {
    print("Cook \(seconds) seconds.")
    return Meal()
  }
}

struct Dinner {
  func chopVegetable() async -> Food {
    print("Chopping vegetables")
    return .vegetable
  }

  func marinateMeat() async -> Food {
    print("Marinate meat")
    return .meat
  }
}

func makeDinner() async -> Meal {
  let dinner = Dinner()
  let veggies = await dinner.chopVegetable()
  let meat = await dinner.marinateMeat()
  
  let oven = Oven()
  await oven.preheatOven()
  let meal = Oven().cook([veggies, meat], seconds: 300)
  
  return meal
}

func makeDinnerWithTaskGroup() async -> Meal {
  var foods: [Food] = []
  let oven = Oven()
  
  await withTaskGroup(of: Food.self) { group in
    let dinner = Dinner()
    
    group.async {
      await dinner.chopVegetable()
    }

    group.async {
      await dinner.marinateMeat()
    }

    for await food in group {
      foods.append(food)
    }
  }

  await oven.preheatOven()

  return oven.cook(foods, seconds: 300)
}

func makeDinnerWithTaskSubGroup() async -> Meal {
  var foods: [Food] = []
  let oven = Oven()
  
  await withTaskGroup(of: Void.self) {
    
    await withTaskGroup(of: Food.self) { group in
      let dinner = Dinner()

      group.async {
        await dinner.chopVegetable()
      }

      group.async {
        await dinner.marinateMeat()
      }

      for await food in group {
        foods.append(food)
      }
    }
    
    $0.async {
      await oven.preheatOven()
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

