//
//  AppIconRenderer.swift
//  tictacspatial
//
//  Created by Mike Sanford (1540) on 8/15/24.
//

import Foundation
import AppKit

final class AppIconRenderer {
    private let iOSAppIcon = AppIconIOS()
    private let macOSAppIcon = AppIconMacOS()
    private let visionOSAppIcon = AppIconVisionOS()
    let iOSMacOSPath: String
    let visionOSPath: String

    init(iOSMacOSPath: String, visionOSPath: String) {
        self.iOSMacOSPath = iOSMacOSPath
        self.visionOSPath = visionOSPath
    }

    func writeMacOSImages(for contents: AppIconiOSmacOSContents, folder: URL) {
        writeImages(for: contents, folder: folder, platform: .macOS)
    }

    func writeIOSImages(for contents: AppIconiOSmacOSContents, folder: URL) {
        writeImages(for: contents, folder: folder, platform: .iOS)
    }

    private func appIcon(for platform: Platform) -> any AppIconRenderable {
        switch platform {
        case .macOS:
            macOSAppIcon
        case .iOS:
            iOSAppIcon
        case .visionOS:
            visionOSAppIcon
        }
    }

    private func writeImages(for contents: AppIconiOSmacOSContents,
                             folder: URL,
                             platform: Platform) {
        let renderContexts = contents.renderContexts.filter { $0.platform == platform }
        for renderContext in renderContexts {
            let url = folder.appendingPathComponent(renderContext.filename)
            let appIcon = appIcon(for: platform)
            appIcon.writeImage(renderContext: renderContext, to: url)
        }
    }

    private func writeContentsJSON(for contents: AppIconiOSmacOSContents, folder: URL) {
        let fileURL = folder.appendingPathComponent("Contents.json")
        do {
            try contents.writeJSON(to: fileURL)
        } catch {
            print("writeContentsJSON error: \(error as NSError)")
        }
    }

    private func writeContentsJSON(for contents: AppIconVisionOSContents, folder: URL) {
        let fileURL = folder.appendingPathComponent("Contents.json")
        do {
            try contents.writeJSON(to: fileURL)
        } catch {
            print("writeContentsJSON error: \(error as NSError)")
        }
    }

    private func writeLayer(folder: URL, filename: String, image: NSImage, layer: AppIconVisionOS.RenderLayer) {
        do {
            let layerFolder = folder.appending(path: filename, directoryHint: .isDirectory)
            let contentFolder = layerFolder.appending(path: "Content.imageset", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: contentFolder, withIntermediateDirectories: true)

            let parentContentsEncoder = JSONEncoder()
            parentContentsEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let parentContentsData = try parentContentsEncoder.encode(ContentsInfo.default)
            let parentContentsFileURL = layerFolder.appending(path: "Contents.json", directoryHint: .notDirectory)
            try parentContentsData.write(to: parentContentsFileURL)

            let baseFilename = filename.dropFileExtension()
            let fileType: NSBitmapImageRep.FileType = if layer == .all || layer == .back {
                .jpeg
            } else {
                .png
            }
            let imageFilename = "\(baseFilename).\(fileType == .jpeg ? "jpg" : "png")"
            let layerContents = AppIconLayerContents(.init(filename: imageFilename))
            let layerContentsEncoder = JSONEncoder()
            layerContentsEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let layerContentsData = try layerContentsEncoder.encode(layerContents)
            let layerContentsFileURL = contentFolder.appending(path: "Contents.json", directoryHint: .notDirectory)
            try layerContentsData.write(to: layerContentsFileURL)

            let imageFileURL = contentFolder.appending(path: imageFilename, directoryHint: .notDirectory)
            image.write(to: imageFileURL, as: fileType)
        } catch {
            print("writeLayer error: \(error as NSError)")
        }
    }

    func macOSExampleImage(length: CGFloat, languageDirection: LanguageDirection) -> NSImage {
        let renderContext = RenderContext(length: length, languageDirection: languageDirection, platform: .macOS)
        return macOSAppIcon.image(renderContext: renderContext)
    }

    func iOSExampleImage(length: CGFloat, appearanceType: AppearanceType?) -> NSImage {
        let renderContext = RenderContext(length: length, appearanceType: appearanceType, platform: .iOS)
        return iOSAppIcon.image(renderContext: renderContext)
    }

    func visionOSExampleImage(length: CGFloat, layer: AppIconVisionOS.RenderLayer) -> NSImage {
        let renderContext = RenderContext(length: length, platform: .visionOS)
        return visionOSAppIcon.image(renderContext: renderContext, layer: layer)
    }

    private func writeiOSmacOSFiles(for contents: AppIconiOSmacOSContents) {
        let folder = URL(filePath: iOSMacOSPath, directoryHint: .isDirectory)
        writeContentsJSON(for: contents, folder: folder)
        writeIOSImages(for: contents, folder: folder)
        writeMacOSImages(for: contents, folder: folder)
    }

    private func writeVisionOSFiles(for contents: AppIconVisionOSContents) {
        do {
            if FileManager.default.fileExists(atPath: visionOSPath) {
                try FileManager.default.removeItem(atPath: visionOSPath)
                try FileManager.default.createDirectory(atPath: visionOSPath, withIntermediateDirectories: false)
            }
        } catch {
            print("failed to write visionOS files. error: \(error as NSError)")
            return
        }
        let folder = URL(filePath: visionOSPath, directoryHint: .isDirectory)
        writeContentsJSON(for: contents, folder: folder)
        let layerInfos = visionOSAppIcon.layerInfo(for: contents.layers)
        for layerInfo in layerInfos {
            let layer = layerInfo.1
            writeLayer(folder: folder, filename: layerInfo.0.filename, image: visionOSAppIcon.image(layer: layer), layer: layer)
        }
    }

    func writeFiles() {
        do {
            let contents = try AppIconiOSmacOSContents(filename: "Contents-ios")
            writeiOSmacOSFiles(for: contents)
        } catch {
            assertionFailure("\(error as NSError)")
        }
        do {
            let contents = try AppIconVisionOSContents(filename: "Contents-visionos")
            writeVisionOSFiles(for: contents)
        } catch {
            assertionFailure("\(error as NSError)")
        }
    }
}

private extension String {
    func dropFileExtension() -> String {
        let components = components(separatedBy: ".")
        return if components.count > 1 {
            components.dropLast().joined(separator: ".")
        } else {
            self
        }
    }
}
