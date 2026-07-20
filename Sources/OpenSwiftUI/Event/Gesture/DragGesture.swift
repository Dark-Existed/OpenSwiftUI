//
//  DragGesture.swift
//  OpenSwiftUI
//
//  Audited for 6.5.4
//  Status: Complete
//  ID: 686AE3220CDF86066434C733931F13C8 (SwiftUI)

public import Foundation
@_spi(ForOpenSwiftUIOnly) public import OpenSwiftUICore
import OpenAttributeGraphShims

// MARK: - DragGesture

public struct DragGesture: PubliclyPrimitiveGesture {
    public struct Value: Equatable {
        public var time: Date
        public var location: CGPoint
        public var startLocation: CGPoint

        package var _velocity: _Velocity<CGSize>
        package var platform: Platform = .init()

        package struct Platform {}

        public var translation: CGSize {
            CGSize(
                width: location.x - startLocation.x,
                height: location.y - startLocation.y
            )
        }

        public var predictedEndLocation: CGPoint {
            CGPoint(
                x: location.x + _velocity.valuePerSecond.width * 0.25,
                y: location.y + _velocity.valuePerSecond.height * 0.25
            )
        }

        public var predictedEndTranslation: CGSize {
            CGSize(
                width: translation.width + _velocity.valuePerSecond.width * 0.25,
                height: translation.height + _velocity.valuePerSecond.height * 0.25
            )
        }

        public static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.time == rhs.time
                && lhs.location == rhs.location
                && lhs.startLocation == rhs.startLocation
                && lhs._velocity == rhs._velocity
        }
    }

    public var minimumDistance: CGFloat

    public var coordinateSpace: CoordinateSpace

    package var allowedDirections: _EventDirections

    public init(
        minimumDistance: CGFloat = 10,
        coordinateSpace: CoordinateSpace = .local
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
        self.allowedDirections = .all
    }
    
    public init(
        minimumDistance: CGFloat = 10,
        coordinateSpace: some CoordinateSpaceProtocol = .local
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace.coordinateSpace
        self.allowedDirections = .all
    }

    package init<CoordinateSpace: CoordinateSpaceProtocol>(
        minimumDistance: CGFloat,
        coordinateSpace: CoordinateSpace,
        allowedDirections: _EventDirections
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace.coordinateSpace
        self.allowedDirections = allowedDirections
    }

    package var internalBody: some Gesture<Value> {
        SpatialDragGesture(
            minimumDistance: minimumDistance,
            coordinateSpace: coordinateSpace,
            allowedDirections: allowedDirections
        )
        .category(.drag, includeChildren: false)
    }

    public static func _makeGesture(
        gesture: _GraphValue<Self>,
        inputs: _GestureInputs
    ) -> _GestureOutputs<Value> {
        Self.makeGesture(
            gesture: gesture,
            inputs: inputs
        )
    }
}

// MARK: - SpatialDragGesture

private struct SpatialDragGesture: Gesture {
    var minimumDistance: CGFloat
    var coordinateSpace: CoordinateSpace
    var allowedDirections: _EventDirections

    struct StateType: GestureStateProtocol {
        var start: TouchEvent?
        var value: DragGesture.Value?
        var sampler: VelocitySampler<AnimatablePair<CGFloat, CGFloat>> = .init()
    }

    var body: some Gesture<DragGesture.Value> {
        StateType.gesture(
            content: EventListener<TouchEvent>()
            .eventFilter(forType: MouseEvent.self) { event in
                event.button == .primary
            }
            .coordinateSpace(coordinateSpace)
        ) { state, event in
            self.phase(state: &state, event: event)
        }
        .dependency(.pausedUntilFailed)
    }

    func phase(
        state: inout StateType,
        event: GesturePhase<TouchEvent>
    ) -> GesturePhase<DragGesture.Value> {
        switch event {
        case .possible:
            guard !allowedDirections.isEmpty else {
                return .failed
            }
            return .possible(state.value)
        case let .active(touch), let .ended(touch):
            let start = state.start ?? touch
            state.start = start
            state.sampler.addSample(
                .init(touch.location.x, touch.location.y),
                time: touch.timestamp
            )
            let velocity = state.sampler.velocity.map { pair in
                CGSize(width: pair.first, height: pair.second)
            }
            let value = DragGesture.Value(
                time: Date(timeIntervalSinceReferenceDate: touch.timestamp.seconds),
                location: touch.location,
                startLocation: start.location,
                _velocity: velocity
            )
            if state.value == nil, minimumDistance > 0 {
                let translation = value.translation
                let outsideRange = translation.magnitude < minimumDistance ||
                   !translation.withinRange(axes: allowedDirections, rangeCosine: 0.5)
                if outsideRange {
                    if case .ended = event {
                        return .failed
                    } else {
                        return .possible(state.value)
                    }
                }
            }
            state.value = value
            return event.withValue(value)
        case .failed:
            return .failed
        @unknown default:
            _openSwiftUIUnreachableCode()
        }
    }
}
