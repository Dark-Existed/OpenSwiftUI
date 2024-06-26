//
//  AsyncAttribute.swift
//  OpenSwiftUI
//
//  Audited for RELEASE_2021
//  Status: WIP

internal import OpenGraphShims

protocol AsyncAttribute: _AttributeBody {}

extension AsyncAttribute {
    static var flags: OGAttributeTypeFlags { [] }
}

extension Attribute {
    func syncMainIfReferences<V>(do body: (Value) -> V) -> V {
        fatalError("TODO")
    }
}
