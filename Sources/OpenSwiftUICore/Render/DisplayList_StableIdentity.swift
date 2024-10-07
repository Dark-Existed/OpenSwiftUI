//
//  DisplayList_StableIdentity.swift
//  OpenSwiftUICore
//
//  Audited for RELEASE_2024
//  Status: WIP
//  ID: 6C8682BE0755616E63B02969BA08C92E

package import OpenGraphShims

package struct _DisplayList_StableIdentity: Hashable, Codable {
    package var hash: StrongHash
    package var serial: UInt32
    
    package init(hash: StrongHash, serial: UInt32) {
        self.hash = hash
        self.serial = serial
    }
}

package struct _DisplayList_StableIdentityMap {
    package var map: [_DisplayList_Identity : _DisplayList_StableIdentity] = [:]
    package init() {}
    package var isEmpty: Bool { map.isEmpty }
    package subscript(index: _DisplayList_Identity) -> _DisplayList_StableIdentity? {
        get { map[index] }
        set { map[index] = newValue }
    }
    package mutating func formUnion(_ other: _DisplayList_StableIdentityMap) {
        map.merge(other.map) { old, _ in old }
    }
}

final package class _DisplayList_StableIdentityRoot {
    var scopes: [WeakAttribute<_DisplayList_StableIdentityScope>] = []
    var map: _DisplayList_StableIdentityMap?
    
    package init() {}
    
    package final subscript(index: _DisplayList_Identity) -> _DisplayList_StableIdentity? {
        if let map {
            return map[index]
        } else {
            fatalError("TODO")
        }
    }
}

package struct _DisplayList_StableIdentityScope: ViewInput, _ViewTraitKey {
    package static let defaultValue: WeakAttribute<_DisplayList_StableIdentityScope> = WeakAttribute()
    
    package let root: _DisplayList_StableIdentityRoot
    package let hash: StrongHash
    package var map: _DisplayList_StableIdentityMap = .init()
    package var serial: UInt32 = .zero

    package init(root: _DisplayList_StableIdentityRoot) {
        self.root = root
        self.hash = StrongHash(of: "root")
    }
    
    package init<ID>(id: ID, parent: _DisplayList_StableIdentityScope) where ID: StronglyHashable {
        self.root = parent.root
        self.hash = StrongHash(of: id)
    }
    
    package mutating func makeIdentity() -> _DisplayList_StableIdentity {
        serial &+= 1
        return _DisplayList_StableIdentity(hash: hash, serial: serial)
    }
    
    package mutating func pushIdentity(_ identity: _DisplayList_Identity) {
        map[identity] = makeIdentity()
    }
}

// TODO: Blocked by ProtobufMessage
//extension _DisplayList_StableIdentity: ProtobufMessage {
//    package func encode(to encoder: inout ProtobufEncoder) throws
//    package init(from decoder: inout ProtobufDecoder) throws
//}
//extension _DisplayList_StableIdentityMap: ProtobufMessage {
//    package func encode(to encoder: inout ProtobufEncoder) throws
//    package init(from decoder: inout ProtobufDecoder) throws
//}

// TODO: Blocked by _ViewInputs
//extension _ViewInputs {
//    package mutating func configureStableIDs(root: _DisplayList_StableIdentityRoot) {
//    package func pushIdentity(_ identity: _DisplayList_Identity)
//    package func makeStableIdentity() -> _DisplayList_StableIdentity
//}

extension _GraphInputs {
    private func pushScope<ID>(id: ID) where ID: StronglyHashable {
        let stableIDScope = self[_DisplayList_StableIdentityScope.self].value!
        let newStableScope = _DisplayList_StableIdentityScope(id: id, parent: stableIDScope)
        stableIDScope.root.scopes.append(WeakAttribute(Attribute(value: newStableScope)))
    }

    package mutating func pushStableID<ID>(_ id: ID) where ID: Hashable {
        guard options.contains(.needsStableDisplayListIDs) else {
            return
        }
        if let stronglyHashable = id as? StronglyHashable {
            pushScope(id: stronglyHashable)
        } else {
            pushScope(id: makeStableIDData(from: id) ?? .random())
        }
    }
    
    package mutating func pushStableIndex(_ index: Int) {
        guard options.contains(.needsStableDisplayListIDs) else {
            return
        }
        pushScope(id: index)
    }
    
    package mutating func pushStableType(_ type: any Any.Type) {
        guard options.contains(.needsStableDisplayListIDs) else {
            return
        }
        pushScope(id: makeStableTypeData(type))
    }
    
    package var stableIDScope: WeakAttribute<_DisplayList_StableIdentityScope>? {
        guard !options.contains(.needsStableDisplayListIDs) else {
            return nil
        }
        let result = self[_DisplayList_StableIdentityScope.self]
        return result.attribute == nil ? nil : result
    }
}

package func makeStableTypeData(_ type: any Any.Type) -> StrongHash {
    // OGTypeGetSignature
    fatalError("TODO")
}

package func makeStableIDData<ID>(from id: ID) -> StrongHash? {
    guard let encodable = id as? Encodable else {
        Log.externalWarning("ID type is not Encodable: \(ID.self)")
        return nil
    }
    do {
        let hash = try StrongHash(encodable: encodable)
        return hash
    } catch {
        Log.externalWarning("ID failed to encode: \(ID.self), \(error.localizedDescription)")
        return nil
    }
}
