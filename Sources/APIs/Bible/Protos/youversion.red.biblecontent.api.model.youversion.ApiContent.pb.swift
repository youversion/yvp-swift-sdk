// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: youversion.red.biblecontent.api.model.youversion.ApiContent.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

/// Auto-Generated from OpenAPI Spec

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var id: String {
    get {return _id ?? String()}
    set {_id = newValue}
  }
  /// Returns true if `id` has been explicitly set.
  var hasID: Bool {return self._id != nil}
  /// Clears the value of `id`. Subsequent reads from it will return its default value.
  mutating func clearID() {self._id = nil}

  var languageTag: String {
    get {return _languageTag ?? String()}
    set {_languageTag = newValue}
  }
  /// Returns true if `languageTag` has been explicitly set.
  var hasLanguageTag: Bool {return self._languageTag != nil}
  /// Clears the value of `languageTag`. Subsequent reads from it will return its default value.
  mutating func clearLanguageTag() {self._languageTag = nil}

  var root: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode {
    get {return _root ?? Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode()}
    set {_root = newValue}
  }
  /// Returns true if `root` has been explicitly set.
  var hasRoot: Bool {return self._root != nil}
  /// Clears the value of `root`. Subsequent reads from it will return its default value.
  mutating func clearRoot() {self._root = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _id: String? = nil
  fileprivate var _languageTag: String? = nil
  fileprivate var _root: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode? = nil
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "youversion.red.biblecontent.api.model.youversion"

extension Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ApiContent"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "id"),
    2: .standard(proto: "language_tag"),
    3: .same(proto: "root"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self._id) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self._languageTag) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._root) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._id {
      try visitor.visitSingularStringField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._languageTag {
      try visitor.visitSingularStringField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._root {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent, rhs: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent) -> Bool {
    if lhs._id != rhs._id {return false}
    if lhs._languageTag != rhs._languageTag {return false}
    if lhs._root != rhs._root {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
