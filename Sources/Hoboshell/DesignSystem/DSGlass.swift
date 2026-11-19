import AppKit

enum DSGlass {
    static var isAvailable: Bool {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            return true
        }
        #endif
        return false
    }

    static func makeBackdrop(cornerRadius: CGFloat = 0) -> NSView {
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.cornerRadius = cornerRadius
            return glass
        }
        #endif
        let blur = NSVisualEffectView()
        blur.material = .menu
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = cornerRadius
        blur.layer?.masksToBounds = cornerRadius > 0
        return blur
    }
}
