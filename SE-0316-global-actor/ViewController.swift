//
//  ViewController.swift
//  SE-0316-global-actor
//
//  Created by Mars on 2021/8/6.
//

import UIKit

@globalActor
struct GlobalActor {
  actor MyActor {
    
  }
  
  static let shared = MyActor()
}

struct DataError: Error {}

struct Todo: Codable {
  let id: Int
  let userId: Int
  let title: String
  let body: String
}

extension Todo {
  static func load(id: Int) async throws -> Todo {
    try await withUnsafeThrowingContinuation { continuation in
      var request = URLRequest(
        url: URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)")!)
      request.httpMethod = "GET"
      
      URLSession.shared.dataTask(with: request) {
        (data, response, error) in
        guard let data = data else {
          return
        }
        
        if let todo = try? JSONDecoder().decode(Todo.self, from: data) {
          continuation.resume(returning: todo)
        }
        else {
          continuation.resume(throwing: DataError())
        }
        
      }.resume()
    }
  }
}

@MainActor
class ViewController: UIViewController {
  @IBOutlet var titleLabel: UILabel? = UILabel()
  
  func loadTodo(id: Int) {
    print(Thread.current)
    
    Task {
      print(Thread.current)
      do {
        let todo = try await Todo.load(id: id)
        titleLabel?.text = todo.title
      }
      catch {
        print("Cannot load todo item of id\(id)")
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    /// DispatchQueue.global().async {
    ///   Property 'text' isolated to global actor 'MainActor'
    ///   can not be mutated from a non-isolated context
    ///   self.titleLabel?.text = "Hello"
    /// }
    
    Task.detached {
      await self.loadTodo(id: 1)
    }
  }
}
