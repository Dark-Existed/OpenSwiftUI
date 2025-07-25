//
//  DisplayListViewRenderer.swift
//  OpenSwiftUICore
//
//  Audited for iOS 18.0
//  Status: Blocked by ViewUpdater and ViewRasterizer
//  ID: 21FFA3C7D88AC65BB559906758271BFC (SwiftUICore)

package import Foundation

protocol ViewRendererBase: AnyObject {
    var platform: DisplayList.ViewUpdater.Platform { get }
    var exportedObject: AnyObject? { get }
    func render(rootView: AnyObject, from list: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version, environment: DisplayList.ViewRenderer.Environment) -> Time
    func renderAsync(to list: DisplayList, time: Time, targetTimestamp: Time?, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time?
    func destroy(rootView: AnyObject)
    var viewCacheIsEmpty: Bool { get }
}

@_spi(ForOpenSwiftUIOnly)
extension DisplayList {
    final public class ViewRenderer {
        package struct Environment: Equatable {
            package var contentsScale: CGFloat
            
            #if os(macOS)
            package var opaqueBackground: Bool = false
            #endif
            
            package static let invalid = Environment(contentsScale: .zero)

            package init(contentsScale: CGFloat) {
                self.contentsScale = contentsScale
            }
            
            #if os(macOS)
            package init(contentsScale: CGFloat, opaqueBackground: Bool) {
                self.contentsScale = contentsScale
                self.opaqueBackground = opaqueBackground
            }
            #endif
        }
        
        let platform: DisplayList.ViewUpdater.Platform

        package var configuration: _RendererConfiguration = .init()

        package weak var host: (any ViewRendererHost)? = nil

        private enum State {
            case none
            case updating
            case rasterizing
        }

        private var state: State = .none

        private var renderer: (any ViewRendererBase)? = nil

        private var configChanged: Bool = true

        package init(platform: DisplayList.ViewUpdater.Platform) {
            self.platform = platform
        }
        
        private func updateRenderer(rootView: AnyObject) -> any ViewRendererBase {
            guard configChanged else {
                return renderer!
            }
            configChanged = false
            let renderStateMatchCheck = switch configuration.renderer {
            case .default: state == .updating
            case .rasterized: state == .rasterizing
            }
            if !renderStateMatchCheck {
                if let renderer {
                    renderer.destroy(rootView: rootView)
                }
                renderer = nil
                state = .none
            }
            if let renderer {
                switch configuration.renderer {
                case .default: break
                case let .rasterized(options):
                    let rasterizer = renderer as! ViewRasterizer
                    rasterizer.options = options
                    rasterizer.renderer.platformViewMode = options.drawsPlatformViews ? .rendered(update: true) : .unsupported
                    rasterizer.host = host
                }
            } else {
                switch configuration.renderer {
                case .default:
                    let updater = ViewUpdater()
                    // TODO: ViewUpdater
                    renderer = updater
                    state = .updating
                case let .rasterized(options):
                    let rasterizer = ViewRasterizer(platform: platform, host: host, rootView: rootView, options: options)
                    renderer = rasterizer
                    state = .rasterizing
                }
            }
            return renderer!
        }
        
        package func exportedObject(rootView: AnyObject) -> AnyObject? {
            let renderer = updateRenderer(rootView: rootView)
            return renderer.exportedObject
        }

        #if canImport(Darwin) && _OPENSWIFTUI_SWIFTUI_RENDER
        @_silgen_name("OpenSwiftUITestStub_DisplayListViewRendererRenderRootView")
        package func swiftUI_render(
            rootView: AnyObject,
            from list: DisplayList,
            time: Time,
            nextTime: Time,
            version: DisplayList.Version,
            maxVersion: DisplayList.Version,
            environment: DisplayList.ViewRenderer.Environment
        ) -> Time
        #endif

        package func render(
            rootView: AnyObject,
            from list: DisplayList,
            time: Time,
            nextTime: Time,
            version: DisplayList.Version,
            maxVersion: DisplayList.Version,
            environment: DisplayList.ViewRenderer.Environment
        ) -> Time {
            let renderer = updateRenderer(rootView: rootView)
            let result = renderer.render(rootView: rootView, from: list, time: time, version: version, maxVersion: maxVersion, environment: environment)
            let interval = min(nextTime, result) - time
            let maxInterval = max(interval, configuration.minFrameInterval)
            return time + maxInterval
        }
        
        package func renderAsync(to list: DisplayList, time: Time, nextTime: Time, targetTimestamp: Time?, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time? {
            guard !configChanged, let renderer else {
                return nil
            }
            let result = renderer.renderAsync(to: list, time: time, targetTimestamp: targetTimestamp, version: version, maxVersion: maxVersion)
            if let result {
                let interval = min(nextTime, result) - time
                let maxInterval = max(interval, configuration.minFrameInterval)
                return time + maxInterval
            } else {
                return nil
            }
        }
        
        package var viewCacheIsEmpty: Bool {
            renderer?.viewCacheIsEmpty ?? true
        }
    }
}

// MARK: - DisplayList.ViewRasterizer

private var printTree: Bool?

extension DisplayList {
    private final class ViewRasterizer: ViewRendererBase {
        let platform: DisplayList.ViewUpdater.Platform
        weak var host: ViewRendererHost?
        var drawingView: AnyObject?
        var options: _RendererConfiguration.RasterizationOptions
        let renderer: DisplayList.GraphicsRenderer
        var seed: DisplayList.Seed
        var lastContentsScale: CGFloat

        init(platform: DisplayList.ViewUpdater.Platform, host: ViewRendererHost?, rootView: AnyObject, options: _RendererConfiguration.RasterizationOptions) {
            _openSwiftUIBaseClassAbstractMethod()
        }

        var exportedObject: AnyObject? {
            platform.definition.getRBLayer(drawingView: drawingView!)
        }

        func render(rootView: AnyObject, from list: DisplayList, time: Time, version: DisplayList.Version, maxVersion: DisplayList.Version, environment: DisplayList.ViewRenderer.Environment) -> Time {
            // _openSwiftUIUnimplementedFailure()
            if printTree == nil {
                printTree = ProcessEnvironment.bool(forKey: "OPENSWIFTUI_PRINT_TREE")
            }
            if let printTree, printTree {
                print("View \(Unmanaged.passUnretained(rootView).toOpaque()) at \(time):\n\(list.description)")
            }
            return .zero
        }

        func renderAsync(to list: DisplayList, time: Time, targetTimestamp: Time?, version: DisplayList.Version, maxVersion: DisplayList.Version) -> Time? {
            _openSwiftUIUnimplementedFailure()
        }

        func destroy(rootView: AnyObject) {
            _openSwiftUIUnimplementedFailure()
        }

        var viewCacheIsEmpty: Bool {
            _openSwiftUIUnimplementedFailure()
        }
    }
}
