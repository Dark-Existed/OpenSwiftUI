//
//  HitTestBindingModifier.swift
//  OpenSwiftUICore
//
//  Status: Complete
//  ID: D16C83991EAE21A87411739F6DC01498 (SwiftUICore)

package import Foundation
import OpenAttributeGraphShims

package typealias PlatformHitTestableEvent = HitTestableEvent

package struct HitTestBindingModifier: ViewModifier, MultiViewModifier, PrimitiveViewModifier {
    nonisolated package static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs {
        var outputs = body(_Graph(), inputs)
        if inputs.preferences.requiresViewResponders {
            outputs.preferences.viewResponders = Attribute(
                HitTestBindingFilter(
                    children: outputs.viewResponders(),
                    responder: .init(inputs: inputs)
                )
            )
        }
        return outputs
    }
}

// MARK: - HitTestBindingResponder

private class HitTestBindingResponder: DefaultLayoutViewResponder {
    override func bindEvent(_ event: any EventType) -> (ResponderNode)? {
        if let hitTestableEvent = HitTestableEvent(event),
           let responder = hitTest(
            globalPoint: hitTestableEvent.hitTestLocation,
            radius: hitTestableEvent.hitTestRadius
        ) {
            return responder
        }
        return super.bindEvent(event)
    }
}

// MARK: - HitTestBindingFilter

private struct HitTestBindingFilter: StatefulRule { 
    @Attribute var children: [ViewResponder]
    let responder: HitTestBindingResponder

    typealias Value = [ViewResponder]

    func updateValue() {
        let (children, changed) = $children.changedValue()
        if changed {
            responder.children = children
        }
        if !hasValue {
            value = [responder]
        }
    }
}

extension ViewResponder {
    package static var hitTestKey: UInt32 = 0

    package static func nextHitTestKey() -> UInt32 {
        hitTestKey &+= 1
        return hitTestKey
    }

    package static let minOpacityForHitTest: Double = 0.001

    package func hitTest(
        globalPoint: PlatformPoint,
        radius: CGFloat,
        cacheKey: UInt32? = nil,
        options: ContainsPointsOptions = .platformDefault
    ) -> ViewResponder? {
        var key = cacheKey
        if options.contains(.uncached) {
            key = nil
        } else if key == nil {
            key = ViewResponder.nextHitTestKey()
        }
        if options.contains(.disablePointCloudHitTesting) {
            return singlePointHitTest(
                globalPoint: globalPoint,
                cacheKey: key,
                options: options
            )?.responder
        }
        let (points, weights) = hitPoints(point: globalPoint, radius: radius)
        return hitTest(
            globalPoints: points,
            weights: weights,
            mask: [],
            cacheKey: key,
            options: options
        )?.responder
    }
    
    private func singlePointHitTest(
        globalPoint: PlatformPoint,
        cacheKey: UInt32?,
        options: ViewResponder.ContainsPointsOptions
    ) -> (responder: ViewResponder, priority: Double)? {
        guard opacity >= Self.minOpacityForHitTest else {
            return nil
        }
        let result = containsGlobalPoints(
            [globalPoint],
            cacheKey: cacheKey,
            options: options
        )
        guard result.mask[0] else {
            return nil
        }
        var best: (responder: ViewResponder, priority: Double)?
        for child in result.children.reversed() {
            guard child.allowHitTesting else {
                continue
            }
            guard let childResult = child.singlePointHitTest(
                globalPoint: globalPoint,
                cacheKey: cacheKey,
                options: options
            ) else {
                continue
            }
            guard childResult.priority > (best?.priority ?? 0.0) else {
                continue
            }
            best = childResult
        }
        if let best, best.priority > 0.0 {
            return best
        }
        guard allowHitTesting else {
            return nil
        }
        return (self, result.priority)
    }

    private func hitTest(
        globalPoints: [PlatformPoint],
        weights: [Double],
        mask: BitVector64,
        cacheKey: UInt32?,
        options: ContainsPointsOptions
    ) -> (responder: ViewResponder, priority: Double, mask: BitVector64)? {
        guard opacity >= Self.minOpacityForHitTest else {
            return nil
        }
        let result = containsGlobalPoints(
            globalPoints,
            cacheKey: cacheKey,
            options: options
        )
        var childMask = mask
        var resultMask = mask
        var weight = 0.0
        for index in globalPoints.indices {
            guard index < 64 else {
                continue
            }
            if !mask[index], result.mask[index] {
                weight += weights[index]
                resultMask[index] = opacity > 0.5
            } else {
                childMask[index] = true
            }
        }
        let priority = result.priority * opacity * weight
        guard priority != 0.0 else {
            return nil
        }
        var best: (responder: ViewResponder, priority: Double)?
        var competingPriority = 0.0

        for child in result.children.reversed() {
            guard child.allowHitTesting else {
                continue
            }
            guard let childResult = child.hitTest(
                globalPoints: globalPoints,
                weights: weights,
                mask: childMask,
                cacheKey: cacheKey,
                options: options
            ) else {
                continue
            }
            childMask = childResult.mask

            if childResult.priority <= competingPriority {
                continue
            } else if childResult.priority <= (best?.priority ?? 0.0) {
                competingPriority = childResult.priority
                continue
            }
            if let best, childResult.responder !== best.responder {
                competingPriority = best.priority
            }
            best = (childResult.responder, childResult.priority)
        }
        if let best, best.priority >= max(8.0, competingPriority * 1.2) {
            return (best.responder, priority, resultMask)
        }
        guard allowHitTesting else {
            return nil
        }
        return (self, priority, resultMask)
    }
}

private func hitPoints(point: PlatformPoint, radius: CGFloat) -> ([PlatformPoint], [Double]) {
    let radius = max(1.0, abs(radius))
    let step: CGFloat = radius > 60.0 ? 10.0 : max(radius / 6.0, 4.0)
    let maxRadius = min(radius, 60.0)
    let count = min(Int(ceil(maxRadius / step)), 6)

    var points: [PlatformPoint] = [point]
    var weights: [Double] = [24.0]
    guard count > 1 else {
        return (points, weights)
    }

    var ringRadius = step
    var pointCount = 4
    for _ in 1..<count {
        let angle = 2.0 * Double.pi / Double(pointCount)
        let sinValue = sin(angle)
        let cosValue = cos(angle)
        let weight = 24.0 / Double(pointCount)

        var x = 1.0
        var y = 0.0
        for _ in 0..<pointCount {
            let newPoint = PlatformPoint(
                x: point.x + x * ringRadius,
                y: point.y + y * ringRadius
            )
            points.append(newPoint)
            weights.append(weight)
            let newX = cosValue * x - sinValue * y
            let newY = sinValue * x + cosValue * y
            x = newX
            y = newY
        }
        ringRadius += step
        pointCount += 4
    }
    return (points, weights)
}
