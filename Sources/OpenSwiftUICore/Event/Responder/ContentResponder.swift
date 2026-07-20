//
//  ContentResponder.swift
//  OpenSwiftUI
//
//  Audited for 6.0.87
//  Status: Complete

package import Foundation
import OpenSwiftUI_SPI

package protocol ContentResponder {
    func contains(points: [PlatformPoint], size: CGSize) -> BitVector64
    func contentPath(size: CGSize) -> Path
    func contentPath(size: CGSize, kind: ContentShapeKinds) -> Path
}

extension ContentResponder {
    package func contains(points: [CGPoint], size: CGSize) -> BitVector64 {
        guard !points.isEmpty else { return BitVector64() }
        let rect = CGRect(origin: .zero, size: size)
        return points.mapBool { rect.contains($0) }
    }
    
    package func contentPath(size: CGSize) -> Path {
        Path(CGRect(origin: .zero, size: size))
    }
    
    package func contentPath(size: CGSize, kind: ContentShapeKinds) -> Path {
        if kind == .interaction {
            return contentPath(size: size)
        } else {            
            let shouldReturnEmptyPath = _SemanticFeature_v3.isEnabled
            if shouldReturnEmptyPath {
                return Path()
            } else {
                return contentPath(size: size)
            }
        }
    }
}

package struct ContentResponderHelper<Data: ContentResponder> {
    var size: CGSize
    var data: Data?
    var transform: ViewTransform
    var observers: ContentPathObservers
    var cache: ViewResponder.ContainsPointsCache

    package init() {
        self.size = .zero
        self.data = nil
        self.transform = .init()
        self.observers = .init()
        self.cache = .init()
    }

    package var bounds: CGRect {
        CGRect(origin: globalPosition, size: size)
    }

    package var globalPosition: CGPoint {
        transform.convert(.localToSpace(.global), point: .zero)
    }

    package mutating func update(
        data: (value: Data, changed: Bool),
        size: (value: ViewSize, changed: Bool),
        position: (value: CGPoint, changed: Bool),
        transform: (value: ViewTransform, changed: Bool),
        parent: ViewResponder
    ) {
        var changes: ContentPathChanges = []
        let oldTransform = self.transform
        if transform.changed || position.changed {
            self.transform = transform.value.withPosition(position.value)
            changes.insert(.transform)
        }
        if size.changed {
            self.size = size.value.value
            changes.insert(.size)
        }
        if data.changed || self.data == nil {
            self.data = data.value
            changes.insert(.data)
        }
        guard !changes.isEmpty else {
            return
        }
        observers.notifyPathChanged(
            for: parent,
            changes: changes,
            transform: (old: oldTransform, new: self.transform)
        )
    }

    package mutating func addContentPath(
        to path: inout Path,
        kind: ContentShapeKinds,
        in space: CoordinateSpace,
        observer: ContentPathObserver?
    ) {
        if let observer {
            observers.addObserver(observer)
        }
        guard var contentPath = data?.contentPath(size: size, kind: kind) else {
            return
        }
        guard !contentPath.isEmpty else {
            return
        }
        contentPath.convert(to: space, transform: transform)
        path.formTrivialUnion(contentPath)
    }

    package mutating func containsGlobalPoints(
        _ points: [CGPoint],
        cacheKey: UInt32?,
        options: ViewResponder.ContainsPointsOptions,
        children: [ViewResponder]
    ) -> ViewResponder.ContainsPointsResult {
        guard let data else {
            return .init(mask: [], priority: 0, children: children)
        }
        return cache.fetch(key: cacheKey) {
            guard !points.isEmpty else {
                return .init(mask: [], priority: 0, children: children)
            }
            var localPoints = points
            localPoints.convert(from: .global, transform: transform)
            return .init(
                mask: data.contains(points: localPoints, size: size),
                priority: 0,
                children: children
            )
        }
    }
}
