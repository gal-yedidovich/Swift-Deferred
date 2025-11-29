//
//  WithTimeoutTests.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 29/11/2025.
//

import Testing

import Deferred

@Suite("WithTimeout Tests")
struct WithTimeoutTests {

  @Test("Should complete task")
  func completeTask() async throws {
    // Given

    // When
    let result = try await withTimeout(10) { "Bubu" }

    // Then
    #expect(result == "Bubu")
  }

  @Test("Should timeout task", .timeLimit(.minutes(1)))
  func timeoutTask() async throws {
    // Given
    let expectedTimeout = 0.00001

    // When
    let task = Task {
      try await withTimeout(expectedTimeout) {
        try await Task.sleep(for: .seconds(120))
      }
    }

    // Then
    await #expect(throws: TimeoutError(timeout: expectedTimeout)) {
      try await task.value
    }
  }

  @Test("Should cancel timeout task")
  func cancelTimeoutTask() async throws {
    // Given
    let task = Task {
      try await withTimeout(5) {
        try await Task.sleep(for: .seconds(5))
      }
    }

    // When
    task.cancel()

    // Then
    await #expect(throws: CancellationError.self) {
      try await task.value
    }
  }
}
