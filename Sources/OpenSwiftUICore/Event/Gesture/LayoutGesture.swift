//
//  LayoutGesture.swift
//  OpenSwiftUICore
//
//  Audited for 6.5.4
//  Status: Complete
//  ID: 05F3243F43C616B77CCF383885E80E96 (SwiftUICore)

import Foundation
import OpenAttributeGraphShims

// MARK: - LayoutGesture

package protocol LayoutGesture: PrimitiveDebuggableGesture, PrimitiveGesture where Value == () {
    var responder: MultiViewResponder { get }

    func updateEventBindings(
        _ events: inout [EventID : any EventType],
        proxy: LayoutGestureChildProxy
    )
}

extension LayoutGesture {
    package func updateEventBindings(
        _ events: inout [EventID : any EventType],
        proxy: LayoutGestureChildProxy
    ) {
        _openSwiftUIEmptyStub()
    }

    package static func _makeGesture(
        gesture: _GraphValue<Self>,
        inputs: _GestureInputs
    ) -> _GestureOutputs<Void> {
        let box = LayoutGestureBox(inputs: inputs)
        let boxValue = Attribute(UpdateLayoutGestureBox(
            gesture: gesture.value,
            events: inputs.events,
            resetSeed: inputs.resetSeed,
            box: box
        ))
        let phase = Attribute(LayoutPhase(
            gesture: gesture.value,
            boxValue: boxValue
        ))
        var outputs = _GestureOutputs(phase: phase)
        if inputs.options.contains(.includeDebugOutput) {
            outputs.debugData = Attribute(LayoutDebug(
                gestureType: Self.self,
                phase: phase,
                boxValue: boxValue,
                resetSeed: inputs.resetSeed,
                position: inputs.position,
                size: inputs.size,
                transform: inputs.transform
            ))
        }
        for key in inputs.preferences.keys {
            func project<K>(_ key: K.Type) where K: PreferenceKey {
                outputs[key] = Attribute(
                    LayoutGesturePreferenceCombiner<Self, K>(
                        gesture: gesture.value,
                        boxValue: boxValue
                    )
                )
            }
            project(key)
        }
        return outputs
    }
}

// MARK: - DefaultLayoutGesture

package struct DefaultLayoutGesture: LayoutGesture, PrimitiveGesture {
    package var responder: MultiViewResponder
}

extension DefaultLayoutGesture: PrimitiveDebuggableGesture {}

// MARK: - UpdateLayoutGestureBox

private struct UpdateLayoutGestureBox<Gesture>: Rule where Gesture: LayoutGesture {
    @Attribute var gesture: Gesture
    @Attribute var events: [EventID : any EventType]
    @Attribute var resetSeed: UInt32
    let box: LayoutGestureBox

    var value: LayoutGestureBox.Value {
        box.updateResetSeed(resetSeed)
        let (gesture, changed) = $gesture.changedValue()
        if changed {
            box.updateResponder(gesture.responder)
        }
        box.willSendEvents(
            events,
            gesture: gesture,
            boxValueAttribute: attribute
        )
        return LayoutGestureBox.Value(box: box, seed: box.seed)
    }
}

// MARK: - LayoutPhase

private struct LayoutPhase<Gesture>: Rule where Gesture: LayoutGesture {
    @Attribute var gesture: Gesture
    @Attribute var boxValue: LayoutGestureBox.Value

    var value: GesturePhase<Void> {
        let box = boxValue.box
        let phase = gesture.phase(box: box)
        box.resetTerminalChildren(gesture: gesture)
        return phase
    }
}

extension LayoutGesture {
    fileprivate func phase(box: LayoutGestureBox) -> GesturePhase<Void> {
        let children = box.children.filter {
            !$0.seenEventIDs.isEmpty
        }
        return children.map {
            $0.phase!.value
        }.merged()
    }
}

extension Collection where Element == GesturePhase<Void> {
    fileprivate func merged() -> GesturePhase<Void> {
        reduce(.failed) { result, phase in
            switch (result, phase) {
            case (.active, _), (_, .active):
                return .active(())
            case (.possible, .ended), (.ended, .possible):
                return .active(())
            case (.ended, _), (_, .ended):
                return .ended(())
            case let (.possible(lhs), .possible(rhs)):
                return .possible(
                    lhs != nil && rhs != nil ? () : nil
                )
            case (.possible, .failed):
                return result
            case (.failed, _):
                return phase
            }
        }
    }
}

// MARK: - LayoutDebug

private struct LayoutDebug<Gesture>: Rule where Gesture: LayoutGesture {
    var gestureType: Gesture.Type
    @Attribute var phase: GesturePhase<Void>
    @Attribute var boxValue: LayoutGestureBox.Value
    @Attribute var resetSeed: UInt32
    @Attribute var position: CGPoint
    @Attribute var size: ViewSize
    @Attribute var transform: ViewTransform

    var value: GestureDebug.Data {
        let box = boxValue.box
        let childData = box.children.compactMap { child -> GestureDebug.Data? in
            guard let debugData = child.debugData else {
                return nil
            }
            switch debugData {
            case let .reset(data):
                return data
            case let .attribute(attribute):
                return attribute.value
            }
        }
        let origin = transform.convert(
            .localToSpace(.global),
            point: position
        )
        return GestureDebug.Data(
            kind: .combiner,
            type: gestureType,
            children: GestureDebug.Data.Children(childData),
            phase: phase,
            attribute: $boxValue.identifier,
            resetSeed: resetSeed,
            frame: CGRect(origin: origin, size: size.value),
            properties: .init()
        )
    }
}

// MARK: - LayoutGesturePreferenceCombiner

private struct LayoutGesturePreferenceCombiner<Gesture, Key>: Rule where Gesture: LayoutGesture, Key: PreferenceKey {
    @Attribute var gesture: Gesture
    @Attribute var boxValue: LayoutGestureBox.Value

    var value: Key.Value {
        gesture.preferenceValue(
            key: Key.self,
            box: boxValue.box
        )
    }

    static var initialValue: Key.Value? {
        Key.defaultValue
    }
}

extension LayoutGesture {
    fileprivate func preferenceValue<Key>(
        key: Key.Type,
        box: LayoutGestureBox
    ) -> Key.Value where Key: PreferenceKey {
        var value = Key.defaultValue
        var initialValue = true
        for child in box.children {
            guard !child.seenEventIDs.isEmpty, let attribute = child.preferences?[key] else {
                continue
            }
            if initialValue {
                value = attribute.value
            } else {
                Key.reduce(value: &value) {
                    attribute.value
                }
            }
            initialValue = false
        }
        return value
    }
}

// MARK: - LayoutGestureChildProxy

package struct LayoutGestureChildProxy: RandomAccessCollection {
    package struct Child {
        fileprivate let base: LayoutGestureBox.Child

        package func binds(_ binding: EventBinding) -> Bool {
            base.binds(binding)
        }

        package func containsGlobalLocation(_ point: PlatformPoint) -> Bool {
            let result = base.responder.containsGlobalPoints(
                [point],
                cacheKey: nil,
                options: .platformDefault
            )
            return result.mask[0]
        }
    }

    fileprivate let box: LayoutGestureBox

    package var startIndex: Int { 0 }

    package var endIndex: Int {
        box.children.count
    }

    package subscript(index: Int) -> LayoutGestureChildProxy.Child {
        Child(base: box.children[index])
    }

    package func bindChild(
        index: Int,
        event: any EventType,
        id: EventID
    ) -> (from: EventBinding?, to: EventBinding?)? {
        let child = box.children[index]
        var responder = child.responder
        if let hitTestableEvent = HitTestableEvent(event),
           let hitTestResponder = child.responder.hitTest(
            globalPoint: hitTestableEvent.hitTestLocation,
            radius: hitTestableEvent.hitTestRadius
           ) {
            responder = hitTestResponder
        }
        guard let result = box.bindingManager?.rebindEvent(id, to: responder) else {
            return nil
        }
        if let from = result.from,
           let index = box.children.firstIndex(where: { $0.binds(from) }) {
            box.children[index].resetDelta &+= 1
            box.seed &+= 1
        }
        return result
    }
}

private class LayoutGestureBox {
    struct Child {
        enum DebugData {
            case reset(GestureDebug.Data)
            case attribute(Attribute<GestureDebug.Data>)
        }

        let responder: ViewResponder
        let uniqueId: UInt32
        var resetDelta: UInt32
        var subgraph: Subgraph?
        var phase: Attribute<GesturePhase<Void>>?
        var events: [EventID: EventType]
        var seenEventIDs: Set<EventID>
        var debugData: DebugData?
        var preferences: PreferencesOutputs?

        func binds(_ binding: EventBinding) -> Bool {
            binding.responder.isDescendant(of: responder)
        }
    }

    struct Value {
        let box: LayoutGestureBox
        let seed: UInt32
    }

    let inputs: _GestureInputs
    weak var bindingManager: EventBindingManager?
    let parentSubgraph: Subgraph
    var children: [LayoutGestureBox.Child]
    var nextUniqueId: UInt32
    var seed: UInt32
    var resetSeed: UInt32

    init(inputs: _GestureInputs) {
        self.inputs = inputs
        self.bindingManager = EventBindingManager.current
        self.parentSubgraph = Subgraph.current!
        self.children = []
        self.nextUniqueId = 0
        self.seed = 0
        self.resetSeed = 0
    }

    func updateResetSeed(_ resetSeed: UInt32) {
        guard self.resetSeed != resetSeed else {
            return
        }
        self.resetSeed = resetSeed
        for index in children.indices {
            resetChildGesture(index: index)
            seed &+= 1
        }
        seed &+= 1
    }

    func updateResponder(_ responder: MultiViewResponder) {
        var index = 0
        var updated = false
        for childResponder in responder.children {
            if index < children.endIndex,
               let target = children[index...].firstIndex(
                   where: { $0.responder === childResponder }
               ) {
                if target != index {
                    children.swapAt(index, target)
                    updated = true
                }
                index += 1
                continue
            }
            let child = Child(
                responder: childResponder,
                uniqueId: nextUniqueId,
                resetDelta: 0,
                subgraph: nil,
                phase: nil,
                events: [:],
                seenEventIDs: [],
                debugData: nil,
                preferences: nil
            )
            nextUniqueId &+= 1
            children.append(child)
            let target = children.index(before: children.endIndex)
            if index < target {
                children.swapAt(index, target)
            }
            updated = true
            index += 1
        }
        while children.count > responder.children.count {
            let index = children.index(before: children.endIndex)
            resetChildGesture(index: index)
            seed &+= 1
            children.removeLast()
            updated = true
        }
        if updated {
            seed &+= 1
        }
    }

    @inline(__always)
    func resetChildGesture(index: Int) {
        guard !children[index].seenEventIDs.isEmpty else {
            return
        }
        if children[index].phase != nil {
            if let debugData = children[index].debugData {
                let data = switch debugData {
                    case let .reset(value): value
                    case let .attribute(attribute): attribute.value
                }
                children[index].debugData = .reset(data)
            }
            children[index].phase = nil
            if let subgraph = children[index].subgraph {
                subgraph.willInvalidate(isInserted: true)
                subgraph.invalidate()
            }
            children[index].subgraph = nil
            children[index].responder.resetGesture()
        }
        children[index].events = [:]
        children[index].seenEventIDs = []
        children[index].resetDelta &+= 1
    }

    func resetTerminalChildren<Gesture>(gesture: Gesture) where Gesture: LayoutGesture {
        for index in children.indices {
            guard !children[index].seenEventIDs.isEmpty else {
                continue
            }
            guard children[index].phase!.value.isTerminal else {
                continue
            }
            resetChildGesture(index: index)
            seed &+= 1
        }
    }
    
    func willSendEvents<Gesture>(
        _ events: [EventID : any EventType],
        gesture: Gesture,
        boxValueAttribute: Attribute<Value>
    ) where Gesture: LayoutGesture {
        for index in children.indices {
            guard !children[index].events.isEmpty else {
                continue
            }
            children[index].events = [:]
            seed &+= 1
        }
        guard !events.isEmpty else {
            return
        }
        var events = events
        gesture.updateEventBindings(
            &events,
            proxy: LayoutGestureChildProxy(box: self)
        )
        for index in children.indices {
            let childEvents = gesture.childEvents(
                events: events,
                index: index,
                box: self
            )
            guard !childEvents.isEmpty else {
                continue
            }
            children[index].seenEventIDs.formUnion(childEvents.keys)
            children[index].events = childEvents
            seed &+= 1
            guard children[index].phase == nil else {
                continue
            }
            let outputs: _GestureOutputs<Void>
            if parentSubgraph.isValid {
                let subgraph = Subgraph(graph: parentSubgraph.graph)
                parentSubgraph.addChild(subgraph)
                outputs = subgraph.apply {
                    let child = children[index]
                    var inputs = inputs
                    inputs.copyCaches()
                    inputs.events = Attribute(
                        LayoutChildEvents<Gesture>(
                            boxValue: boxValueAttribute,
                            uniqueId: child.uniqueId
                        )
                    )
                    inputs.resetSeed = Attribute(
                        LayoutChildSeed<Gesture>(
                            boxValue: boxValueAttribute,
                            uniqueId: child.uniqueId
                        )
                    )
                    return child.responder.makeGesture(inputs: inputs)
                }
                children[index].subgraph = subgraph
            } else {
                outputs = _GestureOutputs(phase: inputs.failedPhase)
            }

            children[index].phase = outputs.phase
            children[index].debugData = outputs.debugData.map {
                .attribute($0)
            }
            children[index].preferences = outputs.preferences
        }
    }
}

extension LayoutGesture {
    fileprivate func childEvents(
        events: [EventID: any EventType],
        index: Int,
        box: LayoutGestureBox
    ) -> [EventID: any EventType] {
        let child = box.children[index]
        guard !child.seenEventIDs.isEmpty else {
            return events.optimisticFilter { element in
                guard let binding = element.value.binding else {
                    return false
                }
                return child.binds(binding)
            }
        }
        var result: [EventID: any EventType] = [:]
        for (id, event) in events {
            var event = event
            if let binding = event.binding, child.binds(binding) {
                result[id] = event
            } else if child.seenEventIDs.contains(id) {
                event.binding = nil
                result[id] = event
            }
        }
        return result
    }
}

// MARK: - LayoutChildEvents

private struct LayoutChildEvents<Gesture>: Rule where Gesture: LayoutGesture {
    @Attribute var boxValue: LayoutGestureBox.Value
    let uniqueId: UInt32

    var value: [EventID: any EventType] {
        let box = boxValue.box
        return box.children.first {
            $0.uniqueId == uniqueId
        }?.events ?? [:]
    }
}

// MARK: - LayoutChildSeed

private struct LayoutChildSeed<Gesture>: Rule where Gesture: LayoutGesture {
    @Attribute var boxValue: LayoutGestureBox.Value
    let uniqueId: UInt32

    var value: UInt32 {
        let box = boxValue.box
        let resetDelta = box.children.first {
            $0.uniqueId == uniqueId
        }?.resetDelta ?? 0x10000
        return box.resetSeed &+ resetDelta
    }
}
