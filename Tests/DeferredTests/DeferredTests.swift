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
}
