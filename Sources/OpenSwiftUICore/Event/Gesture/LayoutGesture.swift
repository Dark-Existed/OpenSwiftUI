//
//  LayoutGesture.swift
//  OpenSwiftUICore
//
//  Status: WIP

// MARK: - LayoutGesture [6.5.4] [WIP]

package protocol LayoutGesture: PrimitiveDebuggableGesture, PrimitiveGesture where Value == () {
    var responder: MultiViewResponder { get }

    func updateEventBindings(
        _ events: inout [EventID : any EventType],
        proxy: LayoutGestureChildProxy
    )
}

extension LayoutGesture {
    package static func _makeGesture(
        gesture: _GraphValue<Self>,
        inputs: _GestureInputs
    ) -> _GestureOutputs<Void> {
        _openSwiftUIUnimplementedFailure()
    }

    package func updateEventBindings(
        _ events: inout [EventID : any EventType],
        proxy: LayoutGestureChildProxy
    ) {
        _openSwiftUIEmptyStub()
    }
}

// MARK: - DefaultLayoutGesture [6.5.4] [WIP]

package struct DefaultLayoutGesture: LayoutGesture {
    package var responder: MultiViewResponder

    package typealias Body = Never
    package typealias Value = ()
}

// MARK: - LayoutGestureChildProxy [6.5.4] [WIP]

package struct LayoutGestureChildProxy: RandomAccessCollection {
    package struct Child {
        package func binds(_ binding: EventBinding) -> Bool {
            _openSwiftUIUnimplementedFailure()
        }

        package func containsGlobalLocation(_ p: PlatformPoint) -> Bool {
            _openSwiftUIUnimplementedFailure()
        }
    }

    package var startIndex: Int {
        get { _openSwiftUIUnimplementedFailure() }
    }

    package var endIndex: Int {
        get { _openSwiftUIUnimplementedFailure() }
    }

    package subscript(index: Int) -> LayoutGestureChildProxy.Child {
        get { _openSwiftUIUnimplementedFailure() }
    }

    package func bindChild(
        index: Int,
        event: any EventType,
        id: EventID
    ) -> (from: EventBinding?, to: EventBinding?)? {
        _openSwiftUIUnimplementedFailure()
    }
}
