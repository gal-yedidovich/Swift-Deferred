import Testing
@testable import Deferred

@Suite
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
    deferred.complete(value: 5)

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
    deferred.complete(error: FakeError())

    // Then
    await #expect(throws: FakeError.self) { try await deferred.value }
  }
}

fileprivate struct FakeError: Error {}
