//
//  ShapeStyledLeafView.swift
//  OpenSwiftUICore
//
//  Audited for 6.5.4
//  Status: WIP
//  ID: E1641985C375D8826E6966D4F238A1B8 (SwiftUICore)

package import Foundation
package import OpenAttributeGraphShims

package protocol ShapeStyledLeafView: ContentResponder {
    static var animatesSize: Bool { get }

    associatedtype ShapeUpdateData = Void

    mutating func mustUpdate(data: ShapeUpdateData, position: Attribute<ViewOrigin>) -> Bool

    typealias FramedShape = (shape: ShapeStyle.RenderedShape.Shape, frame: CGRect)

    func shape(in size: CGSize) -> FramedShape

    static var hasBackground: Bool { get }

    func backgroundShape(in size: CGSize) -> FramedShape

    func isClear(styles: _ShapeStyle_Pack) -> Bool
}

extension ShapeStyledLeafView {
    package static var animatesSize: Bool { true }

    package static var hasBackground: Bool { false }

    package func backgroundShape(in size: CGSize) -> FramedShape {
        (shape: .path(Path(), FillStyle()), frame: .zero)
    }

    package func isClear(styles: ShapeStyle.Pack) -> Bool {
        styles.isClear(name: .foreground) && styles.isClear(name: .background)
    }

    package func contains(points: UnsafeBufferPointer<PlatformPoint>, size: CGSize) -> BitVector64 {
        let framedShape: FramedShape
        if Self.hasBackground {
            let background = backgroundShape(in: size)
            switch background.shape {
            case .empty:
                framedShape = shape(in: size)
            default:
                framedShape = background
            }
        } else {
            framedShape = shape(in: size)
        }
        let frame = framedShape.frame
        switch framedShape.shape {
        case let .path(path, fillStyle):
            guard points.contains(where: { frame.contains($0) }) else {
                return []
            }
            return path.contains(
                points: points,
                eoFill: fillStyle.isEOFilled,
                origin: frame.origin
            )
        default:
            return points.mapBool { frame.contains($0) }
        }
    }

    package func contentPath(size: CGSize) -> Path {
        let framedShape = shape(in: size)
        let frame = framedShape.frame
        switch framedShape.shape {
        case let .path(path, _):
            guard frame.origin != .zero else {
                return path
            }
            let transform = CGAffineTransform(translationX: frame.origin.x, y: frame.origin.y)
            return path.applying(transform)
        default:
            return Path(frame)
        }
    }

    package static func makeLeafView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs,
        styles: Attribute<ShapeStyle.Pack>,
        interpolatorGroup: ShapeStyle.InterpolatorGroup? = nil,
        data: ShapeUpdateData
    ) -> _ViewOutputs {
        var outputs = _ViewOutputs()
        if inputs.preferences.requiresDisplayList {
            let identity = DisplayList.Identity()
            inputs.pushIdentity(identity)
            let displayList = Attribute(
                ShapeStyledDisplayList(
                    group: interpolatorGroup,
                    identity: identity,
                    view: view.value,
                    styles: styles,
                    size: inputs.size.cgSize,
                    animatedSize: inputs.animatedSize(),
                    position: inputs.animatedPosition(),
                    containerPosition: inputs.containerPosition,
                    transform: inputs.transform,
                    environment: inputs.environment,
                    safeAreaInsets: inputs.safeAreaInsets,
                    options: inputs.displayListOptions,
                    data: data,
                    contentSeed: .init()
                )
            )
            outputs.displayList = displayList
        }
        let responders = ShapeStyledResponderFilter(
            view: view.value,
            styles: styles,
            size: inputs.animatedSize(),
            position: inputs.animatedPosition(),
            transform: inputs.transform
        )
        if inputs.preferences.requiresViewResponders {
            outputs.preferences.viewResponders = Attribute(responders)
        }
        return outputs
    }
}

extension ShapeStyledLeafView where ShapeUpdateData == () {
    package mutating func mustUpdate(
        data: ShapeUpdateData,
        position: Attribute<ViewOrigin>
    ) -> Bool {
        false
    }

    @inlinable
    package static func makeLeafView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs,
        styles: Attribute<ShapeStyle.Pack>,
        interpolatorGroup: ShapeStyle.InterpolatorGroup? = nil
    ) -> _ViewOutputs {
        makeLeafView(
            view: view,
            inputs: inputs,
            styles: styles,
            interpolatorGroup: interpolatorGroup,
            data: ()
        )
    }
}

package struct ShapeStyledResponderData<V>: ContentResponder where V: ShapeStyledLeafView {
    var view: V
    var styles: ShapeStyle.Pack
    
    package func contains(points: UnsafeBufferPointer<PlatformPoint>, size: CGSize) -> BitVector64 {
        guard !view.isClear(styles: styles) else {
            return []
        }
        return view.contains(points: points, size: size)
    }

    package func contentPath(size: CGSize) -> Path {
        guard !view.isClear(styles: styles) else {
            return Path()
        }
        return view.contentPath(size: size)
    }
}

// MARK: - ShapeStyledResponderFilter

private struct ShapeStyledResponderFilter<View: ShapeStyledLeafView>: StatefulRule {
    @Attribute var view: View
    @Attribute var styles: ShapeStyle.Pack
    @Attribute var size: ViewSize
    @Attribute var position: ViewOrigin
    @Attribute var transform: ViewTransform
    let responder: LeafViewResponder<ShapeStyledResponderData<View>>

    typealias Value = [ViewResponder]

    init(
        view: Attribute<View>,
        styles: Attribute<ShapeStyle.Pack>,
        size: Attribute<ViewSize>,
        position: Attribute<ViewOrigin>,
        transform: Attribute<ViewTransform>
    ) {
        self._view = view
        self._styles = styles
        self._size = size
        self._position = position
        self._transform = transform
        self.responder = LeafViewResponder()
    }

    func updateValue() {
        let (view, viewChanged) = $view.changedValue()
        let (styles, styleChanged) = $styles.changedValue()
        let data = ShapeStyledResponderData(view: view, styles: styles)
        responder.helper.update(
            data: (value: data, changed: viewChanged || styleChanged),
            size: $size.changedValue(),
            position: $position.changedValue(),
            transform: $transform.changedValue(),
            parent: responder
        )
        if !hasValue {
            self.value = [responder]
        }
    }
}

// MARK: - ShapeStyledDisplayList

struct ShapeStyledDisplayList<V>: StatefulRule, AsyncAttribute where V: ShapeStyledLeafView {
    let group: ShapeStyle.InterpolatorGroup?
    let identity: DisplayList.Identity
    @Attribute var view: V
    @Attribute var styles: ShapeStyle.Pack
    @Attribute var size: CGSize
    @Attribute var animatedSize: ViewSize
    @Attribute var position: CGPoint
    @Attribute var containerPosition: CGPoint
    @Attribute var transform: ViewTransform
    @Attribute var environment: EnvironmentValues
    @OptionalAttribute var safeAreaInsets: SafeAreaInsets?
    let options: DisplayList.Options
    let data: V.ShapeUpdateData
    var contentSeed: DisplayList.Seed

    init(
        group: ShapeStyle.InterpolatorGroup?,
        identity: DisplayList.Identity,
        view: Attribute<V>,
        styles: Attribute<ShapeStyle.Pack>,
        size: Attribute<CGSize>,
        animatedSize: Attribute<ViewSize>,
        position: Attribute<CGPoint>,
        containerPosition: Attribute<CGPoint>,
        transform: Attribute<ViewTransform>,
        environment: Attribute<EnvironmentValues>,
        safeAreaInsets: OptionalAttribute<SafeAreaInsets>,
        options: DisplayList.Options,
        data: V.ShapeUpdateData,
        contentSeed: DisplayList.Seed
    ) {
        self.group = group
        self.identity = identity
        self._view = view
        self._styles = styles
        self._size = size
        self._animatedSize = animatedSize
        self._position = position
        self._containerPosition = containerPosition
        self._transform = transform
        self._environment = environment
        self._safeAreaInsets = safeAreaInsets
        self.options = options
        self.data = data
        self.contentSeed = contentSeed
    }

    typealias Value = DisplayList

    mutating func updateValue() {
        var (view, viewChanged) = $view.changedValue()

        let shouldUpdateSeed: Bool
        let version: DisplayList.Version
        let mustUpdate = view.mustUpdate(data: data, position: $position)

        if mustUpdate || viewChanged || contentSeed.value == 0 {
            shouldUpdateSeed = true
            version = .init(forUpdate: ())
        } else {
            let excluding = [$position.identifier, $containerPosition.identifier, $view.identifier]
            shouldUpdateSeed = Graph.anyInputsChanged(excluding: excluding)
            version = .init(forUpdate: ())
        }
        if shouldUpdateSeed {
            contentSeed = .init(version)
        }

        let proxy = GeometryProxy(
            owner: attribute.identifier,
            size: $animatedSize,
            environment: $environment,
            transform: $transform,
            position: $position,
            safeAreaInsets: $safeAreaInsets,
            seed: UInt32(truncatingIfNeeded: version.value)
        )
        let position = position
        let containerPosition = containerPosition
        let resultSize = V.animatesSize ? animatedSize.value : size
        let framedShape = proxy.asCurrent {
            view.shape(in: resultSize)
        }
        let offset = position - containerPosition
        var layers = ShapeStyle.RenderedLayers(group: group)
        if V.hasBackground {
            let backgroundFramedShape = proxy.asCurrent {
                view.backgroundShape(in: resultSize)
            }
            switch backgroundFramedShape.shape {
            case .empty: break
            default:
                var renderedShape = ShapeStyle.RenderedShape(
                    backgroundFramedShape.shape,
                    frame: backgroundFramedShape.frame.offset(by: offset),
                    identity: identity,
                    version: version,
                    contentSeed: contentSeed,
                    options: options,
                    environment: $environment
                )
                renderedShape.renderItem(
                    name: .background,
                    styles: $styles,
                    layers: &layers
                )
            }
        }
        var renderedShape = ShapeStyle.RenderedShape(
            framedShape.shape,
            frame: framedShape.frame.offset(by: offset),
            identity: identity,
            version: version,
            contentSeed: contentSeed,
            options: options,
            environment: $environment
        )
        renderedShape.renderItem(
            name: .foreground,
            styles: $styles,
            layers: &layers
        )
        value = layers.commit(shape: &renderedShape, options: options)
    }
}
