//
//  TouchEvent.swift
//  OpenSwiftUI
//
//  Audited for 6.5.4
//  Status: Complete

import Foundation
@_spi(ForOpenSwiftUIOnly) import OpenSwiftUICore

package struct TouchEvent: SpatialEventType, TappableEventType, PanEventType, ModifiersEventType, Equatable {
    package var timestamp: Time
    package var phase: EventPhase
    package var binding: EventBinding?

    package var location: CGPoint
    package var globalLocation: CGPoint
    package var radius: CGFloat

    package var force: Double
    package var maximumPossibleForce: Double

    package var modifiers: EventModifiers
    package var altitude: Angle
    package var azimuth: Angle
    package var touchType: TouchType
    
    package var kind: SpatialEvent.Kind? {
        .touch
    }
    
    package var translation: CGSize {
        .init(location)
    }

    package var globalTranslation: CGSize {
        .init(globalLocation)
    }
}

extension TouchEvent: HitTestableEventType {}