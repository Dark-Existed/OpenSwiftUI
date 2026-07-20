//
//  LeafViewResponder.swift
//  OpenSwiftUICore
//
//  Audited for 6.5.4
//  Status: Complete
//  ID: A7CB304DFEF7D87240811B051B15E2CD (SwiftUICore)

package class LeafViewResponder<Responder>: ViewResponder where Responder: ContentResponder {
    package var helper: ContentResponderHelper<Responder>

    override init() {
        helper = .init()
        super.init()
    }

    override package func containsGlobalPoints(
        _ points: [PlatformPoint],
        cacheKey key: UInt32?,
        options: ContainsPointsOptions
    ) -> ContainsPointsResult {
        helper.containsGlobalPoints(
            points,
            cacheKey: key,
            options: options,
            children: children
        )
    }

    override package func addContentPath(
        to path: inout Path,
        kind: ContentShapeKinds,
        in space: CoordinateSpace,
        observer: (any ContentPathObserver)?
    ) {
        helper.addContentPath(to: &path, kind: kind, in: space, observer: observer)
    }

    override package var descriptionName: String {
        return "LeafViewResponder<\(Responder.self)> (\(helper.size.width), \(helper.size.height))"
    }

    override package func extendPrintTree(string: inout String) {
        let position = helper.globalPosition
        string.append("[\(helper.size.width), \(helper.size.height)] @\((position.x, position.y))")
    }
}

struct ContentPathObservers {
    private struct Observer {
        weak var value: (any ContentPathObserver)?
    }

    private var observers: [Observer] = []

    @inline(__always)
    mutating func addObserver(_ observer: any ContentPathObserver) {
        guard !observers.contains(where: { $0.value === observer }) else { return }
        observers.append(Observer(value: observer))
    }

    @inline(__always)
    mutating func notifyDidChange(for parent: ViewResponder) {
        let oldObservers = observers
        observers = []
        for observer in oldObservers {
            guard let value = observer.value else { continue }
            value.respondersDidChange(for: parent)
        }
    }

    mutating func notifyPathChanged(for parent: ViewResponder, changes: ContentPathChanges, transform: (old: ViewTransform, new: ViewTransform)) {
        let oldObservers = observers
        observers = []
        var failedObservers: [Observer] = []
        for observer in oldObservers {
            var result = true
            guard let value = observer.value else { continue }
            value.contentPathDidChange(for: parent, changes: changes, transform: transform, finished: &result)
            guard !result else { continue }
            failedObservers.append(observer)
        }
    }
}
