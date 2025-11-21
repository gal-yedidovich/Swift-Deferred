import Testing
@testable import Deferred

@Suite("Deferred Tests")
struct DeferredTests {
  @Test("Should get value before complete")
  func shouldGetBeforeComplete() async throws {
    // Given
    let deferred = Deferred<Int>()

    // When
    async let result = deferred.value

    // Then
    deferred.complete(value: 123)
    #expect(try await result == 123)
  }

  @Test("Should get value after complete")
  func shouldGetAfterComplete() async throws {
    // Given
    let deferred = Deferred<Int>()
    deferred.complete(value: 5)

    // When
    let result = try await deferred.value

    // Then
    #expect(result == 5)
  }

  @Test("Should get multiple values after complete")
  func shouldGetMultipleAfterComplete() async throws {
    // Given
    let deferred = Deferred<Int>()
    deferred.complete(value: 5)

    // When
    let result1 = try await deferred.value
    let result2 = try await deferred.value
    let result3 = try await deferred.value

    // Then
    #expect(result1 == 5)
    #expect(result2 == 5)
    #expect(result3 == 5)
  }

  @Test("Should get multiple values before complete")
  func shouldGetMultipleBeforeComplete() async throws {
    // Given
    let deferred = Deferred<Int>()

    // When
    async let result1 = deferred.value
    async let result2 = deferred.value
    async let result3 = deferred.value

    // Then
    deferred.complete(value: 5)
    #expect(try await result1 == 5)
    #expect(try await result2 == 5)
    #expect(try await result3 == 5)
  }

  @Test("Should not throw on another completion")
  func shouldNotThrowOnAnotherCompletion() async throws {
    // Given
    let deferred = Deferred<Int>()
    async let result = deferred.value
    deferred.complete(value: 5)

    // When
    deferred.complete(value: 15)

    // Then
    #expect(try await result == 5)
  }

  @Test("Should get value before failure")
  func shouldGetBeforeFail() async throws {
    // Given
    let deferred = Deferred<Int>()
    let expectedError = FakeError()

    // When
    let task = Task { try await deferred.value }

    // Then
    deferred.complete(error: expectedError)
    await #expect(throws: FakeError.self) {
      try await task.value
    }
  }

  @Test("Should get value after failure")
  func shouldGetAfterFail() async throws {
    // Given
    let deferred = Deferred<Int>()
    let expectedError = FakeError()

    // When
    deferred.complete(error: expectedError)

    // Then
    await #expect(throws: FakeError.self) {
      try await deferred.value
    }
  }

  @Test("Should get multiple values after failure")
  func shouldGetMultipleAfterFailure() async throws {
    // Given
    let deferred = Deferred<Int>()
    deferred.complete(error: FakeError())

    // When
    let result1 = Task { try await deferred.value }
    let result2 = Task { try await deferred.value }
    let result3 = Task { try await deferred.value }

    // Then
    await #expect(throws: FakeError.self) { try await result1.value }
    await #expect(throws: FakeError.self) { try await result2.value }
    await #expect(throws: FakeError.self) { try await result3.value }
  }

  @Test("Should get multiple values before complete")
  func shouldGetMultipleBeforeFailure() async throws {
    // Given
    let deferred = Deferred<Int>()

    // When
    let result1 = Task { try await deferred.value }
    let result2 = Task { try await deferred.value }
    let result3 = Task { try await deferred.value }

    // Then
    deferred.complete(error: FakeError())
    await #expect(throws: FakeError.self) { try await result1.value }
    await #expect(throws: FakeError.self) { try await result2.value }
    await #expect(throws: FakeError.self) { try await result3.value }
  }

  @Test("Should not throw on another completion")
  func shouldNotThrowOnAnotherFailure() async throws {
    // Given
    let deferred = Deferred<Int>()
    deferred.complete(error: FakeError())

    // When
    deferred.complete(error: FakeError2())

    // Then
    await #expect(throws: FakeError.self) { try await deferred.value }
  }

  @Test(
    "Should ignore subsequent completions after value",
    arguments: [
      Result.success("other result"),
      Result.failure(FakeError() as Error),
    ]
  )
  func shouldIgnoreSubsequentCompletionsAfterValue(
    secondCompletion: Result<String, Error>,
  ) async throws {
    // Given
    let deferred = Deferred<String>()
    deferred.complete(value: "First value")
    deferred.complete(with: secondCompletion)

    // When
    let result = try await deferred.value

    // Then
    #expect(result == "First value")
  }

  @Test(
    "Should ignore subsequent completions after error",
    arguments: [
      Result.success("other result"),
      Result.failure(FakeError2() as Error),
    ]
  )
  func shouldIgnoreSubsequentCompletionsAfterError(
    secondCompletion: Result<String, Error>,
  ) async throws {
    // Given
    let deferred = Deferred<String>()
    deferred.complete(error: FakeError())
    deferred.complete(with: secondCompletion)

    // When
    let task = Task { try await deferred.value }

    // Then
    try await #require(throws: FakeError.self) { try await task.value }
  }

  @Test("Should ignore completion after cancellation")
  func shouldHandleTaskCancellation() async throws {
    // Given
    let deferred = Deferred<Bool>()
    let task = Task {
      try? await Task.sleep(for: .seconds(5))
      return try await deferred.value
    }
    task.cancel()

    // When
    deferred.complete(value: false)

    // Then
    await #expect(throws: CancellationError.self) {
      try await task.value
    }
  }
}

struct FakeError: Error {}
struct FakeError2: Error {}
