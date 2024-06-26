//
//  PreferenceList.swift
//  OpenSwiftUI
//
//  Audited for RELEASE_2021
//  Status: Complete
//  ID: C1C63C2F6F2B9F3EB30DD747F0605FBD

struct PreferenceList: CustomStringConvertible {
    fileprivate var first: PreferenceNode?
    
    init() {}
    
    subscript<Key: PreferenceKey>(_ keyType: Key.Type) -> Value<Key.Value> {
        get {
            guard let first,
                  let node = first.find(key: keyType) else {
                return Value(value: keyType.defaultValue, seed: .empty)
            }
            return Value(value: node.value, seed: node.seed)
        }
        set {
            if let first,
               let _ = first.find(key: keyType) {
                removeValue(for: keyType)
            }
            first = _PreferenceNode<Key>(value: newValue.value, seed: newValue.seed, next: first)
        }
    }
    
    mutating func removeValue<Key: PreferenceKey>(for keyType: Key.Type) {
        let first = first
        self.first = nil
        first?.forEach { node in
            guard node.keyType != keyType else {
                return
            }
            self.first = node.copy(next: self.first)
        }
    }

    func valueIfPresent<Key: PreferenceKey>(_ keyType: Key.Type) -> Value<Key.Value>? {
        guard let first else {
            return nil
        }
        return first.find(key: keyType).map { node in
            Value(value: node.value, seed: node.seed)
        }
    }
    
    func contains<Key: PreferenceKey>(_ keyType: Key.Type) -> Bool {
        first?.find(key: keyType) != nil
    }
    
    mutating func modifyValue<Key: PreferenceKey>(for keyType: Key.Type, transform: Value < (inout Key.Value) -> Void>) {
        var value = self[keyType]
        value.seed.merge(transform.seed)
        transform.value(&value.value)
        removeValue(for: keyType)
        first = _PreferenceNode<Key>(value: value.value, seed: value.seed, next: first)
    }
    
    var description: String {
        var description = "\((first?.mergedSeed ?? .empty).description): ["
        var currentNode = first
        var shouldAddSeparator = false
        while let node = currentNode {
            if shouldAddSeparator {
                description.append(", ")
            } else {
                shouldAddSeparator = true
            }
            description.append(node.description)
            currentNode = node.next
        }
        description.append("]")
        return description
    }
    
    @inline(__always)
    mutating func merge(_ other: PreferenceList) {
        guard let otherFirst = other.first else {
            return
        }
        guard let selfFirst = first else {
            first = otherFirst
            return
        }
        first = nil
        selfFirst.forEach { node in
            if let mergedNode = node.combine(from: otherFirst, next: first) {
                first = mergedNode
            } else {
                first = node.copy(next: first)
            }
        }
        otherFirst.forEach { node in
            guard node.find(from: selfFirst) == nil else {
                return
            }
            first = node.copy(next: first)
        }
    }
    
    @inline(__always)
    var mergedSeed: VersionSeed? { first?.mergedSeed }
}

extension PreferenceList {
    struct Value<V> {
        var value: V
        var seed: VersionSeed
        
        init(value: V, seed: VersionSeed) {
            self.value = value
            self.seed = seed
        }
    }
}

private class PreferenceNode: CustomStringConvertible {
    let keyType: Any.Type
    let seed: VersionSeed
    let mergedSeed: VersionSeed
    let next: PreferenceNode?
    
    init(keyType: Any.Type, seed: VersionSeed, next: PreferenceNode?) {
        self.keyType = keyType
        self.seed = seed
        self.mergedSeed = next?.mergedSeed.merging(seed) ?? seed
        self.next = next
    }
    
    final func forEach(_ body: (PreferenceNode) -> Void) {
        var node = self
        repeat {
            body(node)
            if let next = node.next {
                node = next
            } else {
                break
            }
        } while true
    }
    
    final func find<Key: PreferenceKey>(key: Key.Type) -> _PreferenceNode<Key>? {
        var node = self
        repeat {
            if node.keyType == key {
                return node as? _PreferenceNode<Key>
            } else {
                if let next = node.next {
                    node = next
                } else {
                    break
                }
            }
        } while true
        return nil
    }
    
    func find(from _: PreferenceNode?) -> PreferenceNode? { fatalError() }
    func combine(from _: PreferenceNode?, next _: PreferenceNode?) -> PreferenceNode? { fatalError() }
    func copy(next _: PreferenceNode?) -> PreferenceNode { fatalError() }
    var description: String { fatalError() }
}

private class _PreferenceNode<Key: PreferenceKey>: PreferenceNode {
    let value: Key.Value
    
    init(value: Key.Value, seed: VersionSeed, next: PreferenceNode?) {
        self.value = value
        super.init(keyType: Key.self, seed: seed, next: next)
    }
    
    override func find(from: PreferenceNode?) -> PreferenceNode? {
        from?.find(key: Key.self)
    }
    
    override func combine(from: PreferenceNode?, next: PreferenceNode?) -> PreferenceNode? {
        var currentNode = from
        while let node = currentNode {
            if keyType == node.keyType {
                var value = self.value
                var seed = self.seed
                Key.reduce(value: &value) {
                    seed.merge(node.seed)
                    return (node as! _PreferenceNode).value
                }
                return _PreferenceNode(value: value, seed: seed, next: next)
            } else {
                currentNode = node.next
            }
        }
        return nil
    }
    
    override func copy(next: PreferenceNode?) -> PreferenceNode {
        _PreferenceNode(value: value, seed: seed, next: next)
    }
        
    override var description: String {
        "\(Key.self) = \(value)"
    }
}
