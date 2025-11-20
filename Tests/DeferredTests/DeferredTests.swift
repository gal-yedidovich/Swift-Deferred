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

  @Test("Should get multiple values after complete")
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

  /*
   Should not throw on another completion
   Should get multiple values before complete
   */
}
