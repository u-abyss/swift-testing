//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

/// A type representing the details of a skipped test.
@_spi(ExperimentalTestRunning)
public struct SkipInfo: Sendable {
  /// A user-specified comment describing this skip, if any.
  public var comment: Comment?

  /// A source context indicating where this skip occurred.
  public var sourceContext: SourceContext

  /// The location in source where this skip occurred, if available.
  public var sourceLocation: SourceLocation? {
    get {
      sourceContext.sourceLocation
    }
    set {
      sourceContext.sourceLocation = newValue
    }
  }

  /// Initialize an instance of this type with the specified details.
  ///
  /// - Parameters:
  ///   - comment: A user-specified comment describing this skip, if any.
  ///     Defaults to `nil`.
  ///   - sourceContext: A source context indicating where this skip occurred.
  ///     Defaults to a source context returned by calling
  ///     ``SourceContext/init(backtrace:sourceLocation:)`` with zero arguments.
  public init(
    comment: Comment? = nil,
    sourceContext: SourceContext = .init()
  ) {
    self.comment = comment
    self.sourceContext = sourceContext
  }
}

// This conforms to `Error` because throwing an instance of this type is how a
// custom trait can signal that the test it is attached to should be skipped.
extension SkipInfo: Error {}

// MARK: - Equatable, Hashable

extension SkipInfo: Equatable, Hashable {}

// MARK: - Codable

extension SkipInfo: Codable {}
