//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//

@testable @_spi(ForToolsIntegrationOnly) import Testing

@Suite("TypeInfo Tests")
struct TypeInfoTests {
  @Test(arguments: [
    (
      String.self,
      TypeInfo(qualifiedName: "Swift.String", unqualifiedName: "String")
    ),
    (
      [String].self,
      TypeInfo(qualifiedName: "Swift.Array<Swift.String>", unqualifiedName: "Array<String>")
    ),
    (
      [Test].self,
      TypeInfo(qualifiedName: "Swift.Array<Testing.Test>", unqualifiedName: "Array<Test>")
    ),
    (
      (key: String, value: Int).self,
      TypeInfo(qualifiedName: "(key: Swift.String, value: Swift.Int)", unqualifiedName: "(key: String, value: Int)")
    ),
    (
      (() -> String).self,
      TypeInfo(qualifiedName: "() -> Swift.String", unqualifiedName: "() -> String")
    ),
  ] as [(Any.Type, TypeInfo)])
  func initWithType(type: Any.Type, expectedTypeInfo: TypeInfo) {
    let typeInfo = TypeInfo(describing: type)
    #expect(typeInfo == expectedTypeInfo)
  }
}
