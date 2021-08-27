//
//  main.swift
//  SE-0311-task-local-storage-ii
//
//  Created by Mars on 2021/8/22.
//

import Foundation

struct Work {
  @TaskLocal
  static var workID: String?
}

func asyncPrintWorkID(tag: String) async {
  print("\(tag) \(Work.workID ?? "no-work-id")")
}

func syncPrintWorkID(tag: String) {
  print("\(tag) \(Work.workID ?? "no-work-id")")
}

func inner() -> String? {
  syncPrintWorkID(tag: "inner")
  return Work.workID
}

func middle() async -> String? {
  syncPrintWorkID(tag: "middle")
  return inner()
}

func outer() async -> String? {
  await Work.$workID.withValue("BX11") {
    syncPrintWorkID(tag: "outer")
    let ret = await middle()
    
    return ret
  }
}

//@main
//struct MyApp {
//  static func main() {
//    syncPrintWorkID(tag: "Outer") // BX11
//
//    Work.$workID.withValue("BX10") {
//      syncPrintWorkID(tag: "Inner") // BX10
//
//      Task.detached(priority: .userInitiated) {
//        syncPrintWorkID(tag: "Detached")
//      }
//    }
//
//    syncPrintWorkID(tag: "Outer") // BX11
//  }
//}


@main
struct MyApp {
  static func main() async {
    /// TLV nest
//    Task(priority: .userInitiated) {
//      Work.$workID.withValue("BX11") {
//        syncPrintWorkID(tag: "Outer") // BX11
//
//        Work.$workID.withValue("BX10") {
//          syncPrintWorkID(tag: "Inner") // BX10
//        }
//
//        syncPrintWorkID(tag: "Outer") // BX11
//      }
//    }
    
    /// TLV Scope
    await print(outer() ?? "no-work-id")
    
    Work.$workID.withValue("BX11") {
      Task(priority: .userInitiated) {
        syncPrintWorkID(tag: "SubTask")
      }
    }
    
    await Work.$workID.withValue("BX11") {
      await withTaskGroup(of: String?.self) { group -> String? in
        group.addTask {
          syncPrintWorkID(tag: "SubTask")
          return Work.workID
        }
        
        return await group.next()!
      }
    }
    
    await withTaskGroup(of: Void.self) { group in
      Work.$workID.withValue("BX11") { // Runtime Exception
        syncPrintWorkID(tag: "Do not do this")

        group.addTask {

        }
      }
    }
  }
}

