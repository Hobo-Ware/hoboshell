import AppKit

if CommandLine.arguments.contains("--restore") {
    SystemChrome.restore()
    exit(0)
}

let app = NSApplication.shared
let isGallery = CommandLine.arguments.contains("--gallery")
let delegate: NSApplicationDelegate = isGallery ? GalleryApp() : AppDelegate()
app.delegate = delegate
app.setActivationPolicy(isGallery ? .regular : .accessory)
app.run()
