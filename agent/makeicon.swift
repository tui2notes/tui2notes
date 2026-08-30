// Renders the app icon: the same "tablecells" glyph the menu bar shows,
// white on a blue rounded square, written as an .iconset directory.
//
//   swift agent/makeicon.swift <output.iconset>
//
// Kept as a build step rather than a checked-in binary so the two icons can
// never drift apart.

import Cocoa

let SYMBOL = "tablecells"

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: makeicon.swift <output.iconset>\n".utf8))
    exit(2)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1])

guard let symbol = NSImage(systemSymbolName: SYMBOL, accessibilityDescription: nil) else {
    FileHandle.standardError.write(Data("SF Symbol \(SYMBOL) unavailable\n".utf8))
    exit(1)
}

/// A white copy of a template symbol. Tinting has to happen off-screen: a
/// `.sourceAtop` fill on the icon canvas would paint the whole plate white.
func whitened(_ img: NSImage) -> NSImage {
    let out = NSImage(size: img.size)
    out.lockFocus()
    let r = NSRect(origin: .zero, size: img.size)
    img.draw(in: r)
    NSColor.white.set()
    r.fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

/// One icon at `px` square pixels.
func render(_ px: Int) -> Data? {
    let side = CGFloat(px)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: px, pixelsHigh: px,
                                     bitsPerSample: 8, samplesPerPixel: 4,
                                     hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep)
    else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    // macOS icon grid: the art sits inside the canvas with a margin all round.
    let inset = side * 0.086
    let plate = NSRect(x: inset, y: inset, width: side - 2 * inset, height: side - 2 * inset)
    NSGradient(starting: NSColor(srgbRed: 0.39, green: 0.51, blue: 0.98, alpha: 1),
               ending:   NSColor(srgbRed: 0.18, green: 0.27, blue: 0.78, alpha: 1))?
        .draw(in: NSBezierPath(roundedRect: plate,
                               xRadius: plate.width * 0.225,
                               yRadius: plate.width * 0.225),
              angle: -90)

    // The glyph, white and centred, at roughly half the plate.
    if let sized = symbol.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: plate.width * 0.62, weight: .regular)) {
        let glyph = whitened(sized)
        let g = glyph.size
        glyph.draw(in: NSRect(x: (side - g.width) / 2, y: (side - g.height) / 2,
                              width: g.width, height: g.height))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// iconutil expects exactly these names.
let wanted: [(String, Int)] = [
    ("icon_16x16", 16),   ("icon_16x16@2x", 32),
    ("icon_32x32", 32),   ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in wanted {
    guard let png = render(px) else {
        FileHandle.standardError.write(Data("failed to render \(px)px\n".utf8))
        exit(1)
    }
    try? png.write(to: outDir.appendingPathComponent("\(name).png"))
}
