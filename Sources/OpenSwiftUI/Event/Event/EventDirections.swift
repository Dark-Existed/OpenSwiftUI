//
//  _EventDirections.swift
//  OpenSwiftUI
//
//  Audited for 6.5.4
//  Status: Complete

import Foundation

// MARK: - _EventDirections

package struct _EventDirections: OptionSet {
   package let rawValue: Int8

   package init(rawValue: Int8) {
       self.rawValue = rawValue
   }

   package static let left: _EventDirections = .init(rawValue: 1 << 0)

   package static let right: _EventDirections = .init(rawValue: 1 << 1)

   package static let up: _EventDirections = .init(rawValue: 1 << 2)

   package static let down: _EventDirections = .init(rawValue: 1 << 3)

   package static let horizontal: _EventDirections = [.left, .right]

   package static let vertical: _EventDirections = [.up, .down]

   package static let all: _EventDirections = [.horizontal, .vertical]
}

extension CGSize {
    package func withinRange(
        axes: _EventDirections,
        rangeCosine: CGFloat
    ) -> Bool {
        if axes == .all {
            return true
        }
        let vector = normalized()
        if axes.contains(.left), -vector.width > rangeCosine {
            return true
        }
        if axes.contains(.right), vector.width > rangeCosine {
            return true
        }
        if axes.contains(.up), -vector.height > rangeCosine {
            return true
        }
        if axes.contains(.down), vector.height > rangeCosine {
            return true
        }
        return false
    }
}