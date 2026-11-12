import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 4, let side = Int(arguments[3]), let image = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: render-svg.swift IN.svg OUT.png SIDE\n".utf8))
    exit(1)
}
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
NSGraphicsContext.current = nil
guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: arguments[2]))
