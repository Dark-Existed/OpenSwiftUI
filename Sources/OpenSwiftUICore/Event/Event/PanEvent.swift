//
//  PanEvent.swift
//  OpenSwiftUICore
//
//  Audited for 6.5.4
//  Status: Complete

package import Foundation

// MARK: - PanEventType

package protocol PanEventType: EventType, TouchTypeProviding {
    var globalTranslation: CGSize { get }
    var translation: CGSize { get }
}

// MARK: - PanEvent

package struct PanEvent: PanEventType, HitTestableEventType, SpatialEventType, Equatable {
    package var location: CGPoint
    package var globalLocation: CGPoint
    package var phase: EventPhase
    package var timestamp: Time
    package var binding: EventBinding?
    package var translation: CGSize
    package var globalTranslation: CGSize
    package var touchType: TouchType

    package init(
        globalLocation: CGPoint,
        phase: EventPhase,
        timestamp: Time,
        globalTranslation: CGSize,
        touchType: TouchType
    ) {
        self.location = globalLocation
        self.globalLocation = globalLocation
        self.phase = phase
        self.timestamp = timestamp
        self.binding = nil
        self.translation = globalTranslation
        self.globalTranslation = globalTranslation
        self.touchType = touchType
    }

    package init(_ event: any PanEventType) {
        self.location = .init(event.translation)
        self.globalLocation = .init(event.globalTranslation)
        self.phase = event.phase
        self.timestamp = event.timestamp
        self.binding = event.binding
        self.translation = event.translation
        self.globalTranslation = event.globalTranslation
        self.touchType = event.touchType
    }

    package init?(_ event: any EventType) {
        guard let event = event as? any PanEventType else {
            return nil
        }
        self.init(event)
    }

    package var radius: CGFloat { .zero }

    package var kind: SpatialEvent.Kind? { .pan }
}
