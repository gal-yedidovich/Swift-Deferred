//
//  WithTimeout.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 29/11/2025.
//

import Foundation

public func withTimeout<T: Sendable>(
  _ timeout: TimeInterval,
  operation: @escaping @Sendable () async throws -> T
) async throws -> T {
  return try await withThrowingTaskGroup { group in
    group.addTask(name: "Operation", operation: operation)
    group.addTask(name: "Timeout") {
      try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
      throw TimeoutError(timeout: timeout)
    }

    defer { group.cancelAll() }
    return try await group.next()!
  }
}

public struct TimeoutError: LocalizedError, Equatable {
  let timeout: TimeInterval

  public init(timeout: TimeInterval) {
    self.timeout = timeout
  }
}
