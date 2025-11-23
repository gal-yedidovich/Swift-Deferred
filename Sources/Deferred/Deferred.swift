//
//  Deferred.swift
//  Swift-Deferred
//
//  Created by Gal Yedidovich on 23/11/2025.
//

import Foundation

public protocol Deferred {
  associatedtype Value: Sendable

  var value: Value { get async throws }
}
