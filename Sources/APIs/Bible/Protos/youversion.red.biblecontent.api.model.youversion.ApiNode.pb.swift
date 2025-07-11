// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: youversion.red.biblecontent.api.model.youversion.ApiNode.proto
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

struct Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var type: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNodeType = .unsupportedPlaceholder

  var attributes: Dictionary<String, String> = [:]

  var classes: [String] = []

  var children: [Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode] = []

  var text: String {
    get {return _text ?? String()}
    set {_text = newValue}
  }
  /// Returns true if `text` has been explicitly set.
  var hasText: Bool {return self._text != nil}
  /// Clears the value of `text`. Subsequent reads from it will return its default value.
  mutating func clearText() {self._text = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _text: String? = nil
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "youversion.red.biblecontent.api.model.youversion"

extension Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ApiNode"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "type"),
    2: .same(proto: "attributes"),
    3: .same(proto: "classes"),
    4: .same(proto: "children"),
    5: .same(proto: "text"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.type) }()
      case 2: try { try decoder.decodeMapField(fieldType: SwiftProtobuf._ProtobufMap<SwiftProtobuf.ProtobufString,SwiftProtobuf.ProtobufString>.self, value: &self.attributes) }()
      case 3: try { try decoder.decodeRepeatedStringField(value: &self.classes) }()
      case 4: try { try decoder.decodeRepeatedMessageField(value: &self.children) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self._text) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if self.type != .unsupportedPlaceholder {
      try visitor.visitSingularEnumField(value: self.type, fieldNumber: 1)
    }
    if !self.attributes.isEmpty {
      try visitor.visitMapField(fieldType: SwiftProtobuf._ProtobufMap<SwiftProtobuf.ProtobufString,SwiftProtobuf.ProtobufString>.self, value: self.attributes, fieldNumber: 2)
    }
    if !self.classes.isEmpty {
      try visitor.visitRepeatedStringField(value: self.classes, fieldNumber: 3)
    }
    if !self.children.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.children, fieldNumber: 4)
    }
    try { if let v = self._text {
      try visitor.visitSingularStringField(value: v, fieldNumber: 5)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode, rhs: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode) -> Bool {
    if lhs.type != rhs.type {return false}
    if lhs.attributes != rhs.attributes {return false}
    if lhs.classes != rhs.classes {return false}
    if lhs.children != rhs.children {return false}
    if lhs._text != rhs._text {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
