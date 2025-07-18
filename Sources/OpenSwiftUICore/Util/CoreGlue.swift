//
//  CoreGlue.swift
//  OpenSwiftUICore
//
//  Audited for iOS 18.0
//  Status: WIP

public import Foundation
#if canImport(CoreText)
public import CoreText
#endif
public import OpenGraphShims
import OpenSwiftUI_SPI

// MARK: - CoreGlue

#if !canImport(Darwin)
// Assume OpenSwiftUI and OpenSwiftUICore is staticlly linked on non-Darwin platform.
// The symbol load process (_initializeCoreGlue) is somehow bugy on Linux.
// So we use it directly here on Swift.
@_spi(ForOpenSwiftUIOnly)
@_silgen_name("OpenSwiftUIGlueClass")
public func OpenSwiftUIGlueClass() -> CoreGlue.Type
#endif

@_spi(ForOpenSwiftUIOnly)
@available(OpenSwiftUI_v6_0, *)
#if canImport(ObjectiveC)
@objc(OpenSwiftUICoreGlue)
#endif
open class CoreGlue: NSObject {
    #if canImport(Darwin)
    package static var shared: CoreGlue = {
        guard let instance = _initializeCoreGlue() as? CoreGlue else {
            fatalError("Could not cast _initializeCoreGlue result to CoreGlue")
        }
        return instance
    }()
    #else
    package static var shared: CoreGlue = {
        let type = OpenSwiftUIGlueClass()
        let instance = type.init()
        return instance
    }()
    #endif

    open func maxVelocity(_ velocity: CGFloat) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func nextUpdate(nextTime: Time, interval: Double, reason: UInt32?) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func hasTestHost() -> Bool {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func isInstantiated(graph: Graph) -> Bool {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open var defaultImplicitRootType: DefaultImplicitRootTypeResult {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open var defaultSpacing: CGSize {
        _openSwiftUIBaseClassAbstractMethod()

    }
    open func makeDefaultLayoutComputer() -> MakeDefaultLayoutComputerResult {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func makeDefaultLayoutComputer(graph: Graph) -> MakeDefaultLayoutComputerResult {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func startChildGeometries(_ params: StartChildGeometriesParameters) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func endChildGeometries(_ params: EndChildGeometriesParameters) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func makeLayoutView<L>(
        root: _GraphValue<L>,
        inputs: _ViewInputs,
        body: (_Graph, _ViewInputs) -> _ViewListOutputs
    ) -> _ViewOutputs where L: Layout {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func addDisplayListTreeValue(outputs: inout _ViewOutputs) {
        _openSwiftUIBaseClassAbstractMethod()
    }

//    open func updateData(_ data: inout _ViewDebug.Data, value: TreeValue) {
//        _openSwiftUIBaseClassAbstractMethod()
//    }

    open func makeForEachView<D, ID, C>(view: _GraphValue<ForEach<D, ID, C>>, inputs: _ViewInputs) -> _ViewOutputs? where D: RandomAccessCollection, ID: Hashable, C: View {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func makeForEachViewList<D, ID, C>(view: _GraphValue<ForEach<D, ID, C>>, inputs: _ViewListInputs) -> _ViewListOutputs? where D: RandomAccessCollection, ID: Hashable, C: View {
        _openSwiftUIBaseClassAbstractMethod()
    }

//    open func defaultOpenURLAction(env: EnvironmentValues) -> OpenURLAction {
//        _openSwiftUIBaseClassAbstractMethod()
//    }

    #if canImport(Darwin)
    override dynamic public init() {
        super.init()
    }
    #else
    override dynamic required public init() {
        super.init()
    }
    #endif
}

@_spi(ForOpenSwiftUIOnly)
@available(OpenSwiftUI_v6_0, *)
extension CoreGlue {
    public struct DefaultImplicitRootTypeResult {
        package var value: any _VariadicView.AnyImplicitRoot.Type

        package init(_ value: any _VariadicView.AnyImplicitRoot.Type) {
            self.value = value
        }
    }

    public struct MakeDefaultLayoutComputerResult {
        package var value: Attribute<LayoutComputer>
        
        package init(value: Attribute<LayoutComputer>) {
            self.value = value
        }
    }

    public struct StartChildGeometriesParameters {
        package var recorder: LayoutTrace.Recorder

        package var parentSize: ViewSize

        package var origin: CGPoint

        package var attributeID: UInt32

        package init(recorder: LayoutTrace.Recorder, parentSize: ViewSize, origin: CGPoint, attributeID: UInt32) {
            self.recorder = recorder
            self.parentSize = parentSize
            self.origin = origin
            self.attributeID = attributeID
        }
    }

    public struct EndChildGeometriesParameters {
        package var recorder: LayoutTrace.Recorder

        package var geometries: [ViewGeometry]

        package init(recorder: LayoutTrace.Recorder, geometries: [ViewGeometry]) {
            self.recorder = recorder
            self.geometries = geometries
        }
    }
}

@available(*, unavailable)
extension CoreGlue: Sendable {}

@available(*, unavailable)
extension CoreGlue.DefaultImplicitRootTypeResult: Sendable {}

@available(*, unavailable)
extension CoreGlue.MakeDefaultLayoutComputerResult: Sendable {}

@available(*, unavailable)
extension CoreGlue.StartChildGeometriesParameters: Sendable {}

@available(*, unavailable)
extension CoreGlue.EndChildGeometriesParameters: Sendable {}

// MARK: - CoreGlue2

#if !canImport(Darwin)
// Assume OpenSwiftUI and OpenSwiftUICore is staticlly linked on non-Darwin platform.
// The symbol load process (_initializeCoreGlue) is somehow bugy on Linux.
// So we use it directly here on Swift.
@_spi(ForOpenSwiftUIOnly)
@_silgen_name("OpenSwiftUIGlue2Class")
public func OpenSwiftUIGlue2Class() -> CoreGlue2.Type
#endif

@_spi(ForOpenSwiftUIOnly)
@available(OpenSwiftUI_v6_0, *)
#if canImport(ObjectiveC)
@objc(OpenSwiftUICoreGlue2)
#endif
open class CoreGlue2: NSObject {
    #if canImport(Darwin)
    package static var shared: CoreGlue2 = {
        guard let instance = _initializeCoreGlue2() as? CoreGlue2 else {
            fatalError("Could not cast _initializeCoreGlue2 result to CoreGlue2")
        }
        return instance
    }()
    #else
    package static var shared: CoreGlue2 = {
        let type = OpenSwiftUIGlue2Class()
        let instance = type.init()
        return instance
    }()
    #endif

    open func initializeTestApp() {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func isStatusBarHidden() -> Bool? {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func configureEmptyEnvironment(_: inout EnvironmentValues) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func configureDefaultEnvironment(_: inout EnvironmentValues) {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open func makeRootView(base: AnyView, rootFocusScope: Namespace.ID) -> AnyView {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open var systemDefaultDynamicTypeSize: DynamicTypeSize {
        _openSwiftUIBaseClassAbstractMethod()
    }

    open var codableAttachmentCellType: CoreGlue2.CodableAttachmentCellTypeResult {
        _openSwiftUIBaseClassAbstractMethod()
    }
    
    open func linkURL(_ parameters: LinkURLParameters) -> URL? {
        _openSwiftUIBaseClassAbstractMethod()
    }
    
    package func linkURL(at point: CGPoint, in size: CGSize, stringDrawing: ResolvedStyledText.StringDrawing) -> URL? {
        linkURL(LinkURLParameters(point: point, size: size, stringDrawing: stringDrawing))
    }

    open func transformingEquivalentAttributes(_ attributedString: AttributedString) -> AttributedString {
        _openSwiftUIBaseClassAbstractMethod()
    }

    #if canImport(CoreText)
    @objc(makeSummarySymbolHostIsOn:font:foregroundColor:)
    open func makeSummarySymbolHost(isOn: Bool, font: CTFont, foregroundColor: CGColor) -> AnyObject {
        _openSwiftUIBaseClassAbstractMethod()
    }
    #endif

    #if canImport(Darwin)
    override dynamic public init() {
        super.init()
    }
    #else
    override dynamic required public init() {
        super.init()
    }
    #endif
}

@available(OpenSwiftUI_v6_0, *)
extension CoreGlue2 {
    public struct CodableAttachmentCellTypeResult {
        package var value: (any ProtobufMessage.Type)?

        package init(_ value: (any ProtobufMessage.Type)?) {
            self.value = value
        }
    }

    public struct LinkURLParameters {
        package var point: CGPoint
        package var size: CGSize
        package var stringDrawing: ResolvedStyledText.StringDrawing

        package init(point: CGPoint, size: CGSize, stringDrawing: ResolvedStyledText.StringDrawing) {
            self.point = point
            self.size = size
            self.stringDrawing = stringDrawing
        }
    }
}

@available(*, unavailable)
extension CoreGlue2: Sendable {}

@available(*, unavailable)
extension CoreGlue2.CodableAttachmentCellTypeResult: Sendable {}

@available(*, unavailable)
extension CoreGlue2.LinkURLParameters: Sendable {}
