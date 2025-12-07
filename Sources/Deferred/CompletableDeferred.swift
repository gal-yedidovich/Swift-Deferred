//
//  CompletableDeferred.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 23/11/2025.
//

import Foundation

public actor CompletableDeferred<Value: Sendable> {
  private var result: Result<Value, Error>? = nil
  private var continuations: [UUID: CheckedContinuation<Value, Error>] = [:]

  public init() {}

  public nonisolated func complete(value: Value) {
    complete(with: .success(value))
  }

  public nonisolated func complete(error: Error) {
    complete(with: .failure(error))
  }

  public nonisolated func complete(with result: Result<Value, Error>) {
    Task { @DeferredExecutor in
      await resolve(result)
    }
  }

  private func resolve(_ result: Result<Value, Error>) {
    if Task.isCancelled || self.result != nil { return }

    self.result = result
    let copy = continuations
    continuations.removeAll(keepingCapacity: true)

    for (_, continuation) in copy {
      continuation.resume(with: result)
    }
  }
}

extension CompletableDeferred: Deferred {
  public var value: Value {
    get async throws {
      try Task.checkCancellation()

      if let result {
        return try result.get()
      }

      let id = UUID()
      return try await withTaskCancellationHandler {
        return try await withCheckedThrowingContinuation { continuation in
          self.continuations[id] = continuation
        }
      } onCancel: {
        Task { @DeferredExecutor in await cancel(id: id) }
      }
    }
  }

  private func cancel(id: UUID) {
    guard let continuation = self.continuations.removeValue(forKey: id) else {
      return
    }

    continuation.resume(throwing: CancellationError())
  }
}

@globalActor
actor DeferredExecutor {
  static let shared = DeferredExecutor()
}
