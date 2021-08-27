//
//  main.swift
//  SE-0311-task-local-storage
//
//  Created by Mars on 2021/8/8.
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

@main
struct MyApp {
  static func main() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        syncPrintWorkID(tag: "T1")          // no-work-id

        await Work.$workID.withValue("BX11") {
          syncPrintWorkID(tag: "T1")        // BX11
          await asyncPrintWorkID(tag: "T1") // BX11
        }

        await asyncPrintWorkID(tag: "T1")   // no-work-id
      }

      group.addTask {
        syncPrintWorkID(tag: "T2")          // no-work-id

        await Work.$workID.withValue("BX10") {
          syncPrintWorkID(tag: "T2")        // BX10
          await asyncPrintWorkID(tag: "T2") // BX10
        }

        await asyncPrintWorkID(tag: "T2")   // no-work-id
      }
    }
  }
}

//@main
//struct MyApp {
//  static func main() async {
//    await withTaskGroup(of: Void.self) { group in
//      group.addTask {
//        syncPrintWorkID(tag: "T1")        // no-work-id
//        await asyncPrintWorkID(tag: "T1") // no-work-id
//      }
//
//      group.addTask {
//        syncPrintWorkID(tag: "T2")        // no-work-id
//        await asyncPrintWorkID(tag: "T2") // no-work-id
//      }
//    }
//  }
//}

