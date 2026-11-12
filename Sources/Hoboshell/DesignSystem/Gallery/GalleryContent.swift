import AppKit
import HoboshellCore

enum GalleryContent {
    private static let fieldWidth: CGFloat = 200
    private static let rowWidth: CGFloat = 150
    private static let taskbarButtonWidth: CGFloat = 120
    private static let toolbarWidth: CGFloat = 640
    private static let cardSize = NSSize(width: 240, height: 96)

    static func page() -> NSView {
        let sections = [
            colors(), scales(), text(), buttons(), toggles(), fields(), menus(), rows(), grid(), startMenu(), switcher(), chrome(), taskbar(), tray(), dialogs(),
        ]
        let stack = NSStackView(views: [DSLabel("Hoboshell design system", style: .title, weight: .semibold)] + sections)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = DSSpacing.xl
        return stack
    }

    private static func colors() -> NSView {
        let roles: [(String, NSColor)] = [
            ("surface", DSColor.surface), ("raisedSurface", DSColor.raisedSurface), ("field", DSColor.field),
            ("border", DSColor.border), ("text", DSColor.text), ("dimText", DSColor.dimText),
            ("accent", DSColor.accent), ("onAccent", DSColor.onAccent), ("danger", DSColor.danger), ("focusRing", DSColor.focusRing),
        ]
        let overlays: [(String, NSColor)] = [
            ("faint", DSColor.faint), ("hover", DSColor.hover), ("pressed", DSColor.pressed), ("selected", DSColor.selected), ("accentTint", DSColor.accentTint), ("runMark", DSColor.runMark),
        ]
        let desktops: [(String, NSColor)] = ShellVariant.allCases.map { ($0.displayName, DSColor.desktop(for: $0)) }
        return GalleryRow.section("Colour roles", [
            GalleryRow.make("roles", roles.map { ($0.0, swatch($0.1)) }),
            GalleryRow.make("overlays", overlays.map { ($0.0, swatch($0.1)) }),
            GalleryRow.make("desktop", desktops.map { ($0.0, swatch($0.1)) }),
        ])
    }

    private static func scales() -> NSView {
        let spacing: [(String, CGFloat)] = [
            ("xxs 2", DSSpacing.xxs), ("xs 4", DSSpacing.xs), ("s 8", DSSpacing.s),
            ("m 12", DSSpacing.m), ("l 16", DSSpacing.l), ("xl 24", DSSpacing.xl),
        ]
        let radii: [(String, CGFloat)] = [("control 4", DSRadius.control), ("card 8", DSRadius.card), ("panel 12", DSRadius.panel)]
        let heights: [(String, CGFloat)] = [
            ("compact 24", DSControlHeight.compact.value), ("row 28", DSControlHeight.row.value), ("regular 32", DSControlHeight.regular.value),
            ("taskbar 40", DSControlHeight.taskbar.value),
        ]
        let icons: [(String, CGFloat)] = [
            ("inline 16", DSIconSize.inline), ("row 18", DSIconSize.row), ("toolbar 20", DSIconSize.toolbar),
            ("taskbar 24", DSIconSize.taskbar), ("grid 48", DSIconSize.grid),
            ("picture 96", DSIconSize.picture),
        ]
        return GalleryRow.section("Values", [
            GalleryRow.make("spacing", spacing.map { ($0.0, block(width: $0.1, height: DSSpacing.l, radius: DSRadius.none)) }),
            GalleryRow.make("radius", radii.map { ($0.0, block(width: DSIconSize.grid, height: DSIconSize.grid, radius: $0.1)) }),
            GalleryRow.make("control height", heights.map { ($0.0, block(width: DSIconSize.grid, height: $0.1, radius: DSRadius.control)) }),
            GalleryRow.make("icon size", icons.map { ($0.0, symbol($0.1)) }),
        ])
    }

    private static func text() -> NSView {
        let samples: [(String, NSView)] = [
            ("caption 11", DSLabel("The quick brown fox", style: .caption)),
            ("body 13", DSLabel("The quick brown fox", style: .body)),
            ("title 15", DSLabel("The quick brown fox", style: .title)),
            ("medium", DSLabel("The quick brown fox", weight: .medium)),
            ("semibold", DSLabel("The quick brown fox", weight: .semibold)),
            ("dimText", DSLabel("The quick brown fox", color: DSColor.dimText)),
            ("danger", DSLabel("The quick brown fox", color: DSColor.danger)),
        ]
        return GalleryRow.section("Text", [GalleryRow.make("styles", samples)])
    }

    private static func buttons() -> NSView {
        var rows: [NSView] = []
        let heights: [(String, DSControlHeight)] = [("compact", .compact), ("regular", .regular), ("taskbar", .taskbar)]
        for (name, height) in heights {
            rows.append(GalleryRow.states("\(name) / text") { DSButton(title: "Button", height: height) })
            rows.append(GalleryRow.states("\(name) / icon") {
                DSButton(symbol: "folder.fill", tip: "Folder", height: height)
            })
            rows.append(GalleryRow.states("\(name) / icon + text") {
                DSButton(title: "New folder", image: DSIconSize.symbol("folder.badge.plus"), height: height)
            })
        }
        return GalleryRow.section("DSButton", rows)
    }

    private static func toggles() -> NSView {
        let toggle = GalleryRow.states("toggle button") {
            DSToggleButton(symbol: "eye", tip: "Show hidden files")
        }
        let switches: [(String, NSView)] = [
            ("first", DSSegmentedSwitch(segments: viewSegments(), selectedIndex: 0)),
            ("second", DSSegmentedSwitch(segments: viewSegments(), selectedIndex: 1)),
            ("disabled", disabledSwitch()),
        ]
        return GalleryRow.section("DSToggleButton and DSSegmentedSwitch", [toggle, GalleryRow.make("segmented switch", switches)])
    }

    private static func fields() -> NSView {
        let filled = DSTextField(placeholder: "Name")
        filled.stringValue = "Documents"
        let focused = DSTextField(placeholder: "Name")
        focused.showsFocus = true
        let disabled = DSTextField(placeholder: "Name")
        disabled.isEnabled = false
        let text: [(String, NSView)] = [
            ("rest", sized(DSTextField(placeholder: "Name"))), ("filled", sized(filled)),
            ("focus", sized(focused)), ("disabled", sized(disabled)),
            ("card radius", sized(DSTextField(placeholder: "Name", radius: DSRadius.card))),
        ]
        let searchFilled = DSSearchField(placeholder: "Search")
        searchFilled.stringValue = "report"
        let searchFocused = DSSearchField(placeholder: "Search")
        searchFocused.showsFocus = true
        let searchDisabled = DSSearchField(placeholder: "Search")
        searchDisabled.isEnabled = false
        let search: [(String, NSView)] = [
            ("rest", sized(DSSearchField(placeholder: "Search"))), ("filled", sized(searchFilled)),
            ("focus", sized(searchFocused)), ("disabled", sized(searchDisabled)),
            ("card radius", sized(DSSearchField(placeholder: "Search", radius: DSRadius.card))),
        ]
        return GalleryRow.section("DSTextField and DSSearchField", [
            GalleryRow.make("text field", text), GalleryRow.make("search field", search),
        ])
    }

    private static func menus() -> NSView {
        let button = DSButton(title: "Open menu", image: DSIconSize.symbol("contextualmenu.and.cursorarrow"))
        button.onPress = { [weak button] in
            guard let button else { return }
            DSMenu.popUp(sampleMenu(), below: button)
        }
        return GalleryRow.section("DSMenuItem", [GalleryRow.make("closure menu", [("normal, checked, disabled", button)])])
    }

    private static func rows() -> NSView {
        let folder = NSImage(named: NSImage.folderName)
        let listStates = GalleryRow.states("DSListRow") {
            sized(DSListRow(title: "Documents", image: folder, detail: "12 items"), width: rowWidth)
        }
        let header = DSSectionHeader("Quick access")
        header.translatesAutoresizingMaskIntoConstraints = false
        header.widthAnchor.constraint(equalToConstant: rowWidth).isActive = true
        return GalleryRow.section("DSListRow and DSSectionHeader", [
            listStates, GalleryRow.make("DSSectionHeader", [("header", header)]),
        ])
    }

    private static func grid() -> NSView {
        let folder = NSImage(named: NSImage.folderName) ?? NSImage()
        let photo = NSImage(size: NSSize(width: 96, height: 64), flipped: false) { rect in
            DSColor.accent.setFill()
            rect.fill()
            return true
        }
        func tile(_ name: String, _ image: NSImage, isPicture: Bool) -> () -> DSControl {
            {
                let tile = DSTile()
                tile.show(name: name, image: image, isPicture: isPicture)
                tile.translatesAutoresizingMaskIntoConstraints = false
                tile.widthAnchor.constraint(equalToConstant: DSTile.size.width).isActive = true
                tile.heightAnchor.constraint(equalToConstant: DSTile.size.height).isActive = true
                return tile
            }
        }
        return GalleryRow.section("DSGridCell and DSTile", [
            GalleryRow.states("DSGridCell") {
                let cell = DSGridCell()
                cell.show(name: "Documents", icon: folder)
                cell.translatesAutoresizingMaskIntoConstraints = false
                cell.widthAnchor.constraint(equalToConstant: DSGridCell.size.width).isActive = true
                cell.heightAnchor.constraint(equalToConstant: DSGridCell.size.height).isActive = true
                return cell
            },
            GalleryRow.states("DSTile icon", tile("Documents", folder, isPicture: false)),
            GalleryRow.states("DSTile picture", tile("Holiday photo from the beach in Portugal 2026.jpeg", photo, isPicture: true)),
        ])
    }

    private static func startMenu() -> NSView {
        let application = NSImage(named: NSImage.applicationIconName) ?? NSImage()
        let letter = DSLetterHeader("A")
        letter.translatesAutoresizingMaskIntoConstraints = false
        letter.widthAnchor.constraint(equalToConstant: rowWidth).isActive = true
        return GalleryRow.section("Start menu pieces", [
            GalleryRow.states("rail button") {
                DSButton(image: HoboIcon.home.image(side: DSIconSize.toolbar), height: .regular, tip: "Home")
            },
            GalleryRow.states("pinned tile") {
                let cell = DSGridCell()
                cell.show(name: "Safari", icon: application)
                cell.translatesAutoresizingMaskIntoConstraints = false
                cell.widthAnchor.constraint(equalToConstant: DSGridCell.size.width).isActive = true
                cell.heightAnchor.constraint(equalToConstant: DSGridCell.size.height).isActive = true
                return cell
            },
            GalleryRow.states("result row") {
                sized(DSListRow(title: "Quarterly plan.pdf", image: NSImage(named: NSImage.folderName), detail: "Documents"), width: toolbarWidth / 2)
            },
            GalleryRow.make("letter header", [("A", letter)]),
            GalleryRow.make("avatar", [("picture", DSAvatar(side: DSIconSize.taskbar, image: application)), ("none", DSAvatar(side: DSIconSize.taskbar))]),
        ])
    }

    private static func switcher() -> NSView {
        let application = NSImage(named: NSImage.applicationIconName)
        let photo = NSImage(size: DSSwitcherTile.pictureSize, flipped: false) { rect in
            DSColor.raisedSurface.setFill()
            rect.fill()
            return true
        }
        func tile(picture: NSImage?) -> () -> DSControl {
            {
                let tile = DSSwitcherTile()
                tile.show(title: "Quarterly plan - Notes", icon: application)
                if let picture {
                    tile.show(picture: picture)
                }
                return tile
            }
        }
        return GalleryRow.section("DSSwitcherTile", [
            GalleryRow.states("icon placeholder", tile(picture: nil)),
            GalleryRow.states("window picture", tile(picture: photo)),
        ])
    }

    private static func chrome() -> NSView {
        let toolbar = DSToolbar([
            .group([
                DSButton(symbol: "chevron.left", tip: "Back"),
                DSButton(symbol: "chevron.right", tip: "Forward"),
            ]),
            .divider,
            .flexible(DSSearchField(placeholder: "Search")),
            .divider,
            .view(DSButton(title: "Sort", image: DSIconSize.symbol("arrow.up.arrow.down"))),
        ])
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.widthAnchor.constraint(equalToConstant: toolbarWidth).isActive = true

        let card = DSCard()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: cardSize.width).isActive = true
        card.heightAnchor.constraint(equalToConstant: cardSize.height).isActive = true
        let inner = DSLabel("Card and flyout panel", weight: .medium)
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: DSSpacing.m),
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: DSSpacing.m),
        ])

        let badges: [(String, NSView)] = [
            ("neutral", DSBadge("3", tone: .neutral)), ("accent", DSBadge("New", tone: .accent)),
            ("danger", DSBadge("Failed", tone: .danger)),
        ]
        return GalleryRow.section("DSToolbar, DSCard, DSBadge", [
            GalleryRow.make("DSToolbar", [("40 high, 8 edge, 4 gap", toolbar)]),
            GalleryRow.make("DSCard", [("radius 8, border, shadow", card)]),
            GalleryRow.make("DSBadge", badges),
        ])
    }

    private static func taskbar() -> NSView {
        let folder = NSImage(named: NSImage.folderName)
        let marks: [(String, NSView)] = [
            ("none", DSRunMark()), ("running", mark(.running)), ("active", mark(.active)), ("background", mark(.background)),
        ]
        func button(_ configure: @escaping (DSTaskbarButton) -> Void) -> () -> DSControl {
            {
                let button = DSTaskbarButton(title: "Documents", image: folder, width: taskbarButtonWidth, alignment: .leading)
                configure(button)
                return button
            }
        }
        return GalleryRow.section("DSRunMark and DSTaskbarButton", [
            GalleryRow.make("DSRunMark", marks),
            GalleryRow.states("pinned, not running", button { _ in }),
            GalleryRow.states("running", button { $0.runState = .running }),
            GalleryRow.states("active window", button { $0.runState = .active }),
            GalleryRow.states("pinned, no window", button { $0.runState = .background }),
            GalleryRow.states("group with count", button {
                $0.runState = .running
                $0.countText = "3"
            }),
            GalleryRow.states("unread badge", button {
                $0.runState = .running
                $0.notificationText = "12"
            }),
        ])
    }

    private static func tray() -> NSView {
        let folder = NSImage(named: NSImage.folderName)
        let icons: [(String, NSView)] = [
            ("icon", DSTrayIcon(icon: folder, tip: "Documents")),
            ("with unread badge", DSTrayIcon(icon: folder, tip: "Documents", badge: "12")),
        ]
        let slider = DSSlider()
        slider.doubleValue = 0.55
        let disabled = DSSlider()
        disabled.isEnabled = false
        return GalleryRow.section("Tray: DSTrayIcon, DSCalendarCell, DSSlider", [
            GalleryRow.make("background app", icons),
            GalleryRow.make("DSCalendarCell", [
                ("day", DSCalendarCell("12", style: .day)), ("today", DSCalendarCell("13", style: .today)),
                ("week number", DSCalendarCell("46", style: .weekNumber)), ("weekday", DSCalendarCell("M", style: .weekday)),
            ]),
            GalleryRow.make("DSSlider", [("level", sized(slider)), ("disabled", sized(disabled))]),
        ])
    }

    private static func mark(_ state: DSRunMark.State) -> DSRunMark {
        let mark = DSRunMark()
        mark.state = state
        return mark
    }

    private static func dialogs() -> NSView {
        let error = DSButton(title: "Show error")
        error.onPress = {
            DSDialog.showError(title: "Could not rename", message: "A file with that name already exists.")
        }
        let confirm = DSButton(title: "Show confirm")
        confirm.onPress = {
            _ = DSDialog.confirm(
                title: "Move to Trash?", message: "The item can be restored from the Trash.",
                confirmTitle: "Move to Trash", isDestructive: true
            )
        }
        return GalleryRow.section("DSDialog", [GalleryRow.make("alerts", [("error", error), ("confirm", confirm)])])
    }

    private static func viewSegments() -> [DSSegmentedSwitch.Segment] {
        [
            DSSegmentedSwitch.Segment(symbol: "list.bullet", tip: "Details"),
            DSSegmentedSwitch.Segment(symbol: "square.grid.2x2", tip: "Icons"),
        ]
    }

    private static func disabledSwitch() -> DSSegmentedSwitch {
        let control = DSSegmentedSwitch(segments: viewSegments())
        control.isEnabled = false
        return control
    }

    private static func sampleMenu() -> NSMenu {
        DSMenu.make([
            DSMenuItem("Open", symbol: "arrow.up.forward.app") {},
            DSMenuItem("Show hidden files", state: .on) {},
            DSMenuItem("Paste", isEnabled: false) {},
            DSMenu.separator(),
            DSMenu.submenu("Sort by", [DSMenuItem("Name") {}, DSMenuItem("Size") {}]),
        ])
    }

    private static func sized(_ view: NSView, width: CGFloat = fieldWidth) -> NSView {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }

    private static func sized(_ row: DSListRow, width: CGFloat) -> DSListRow {
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalToConstant: width).isActive = true
        return row
    }

    private static func swatch(_ color: NSColor) -> NSView {
        let view = block(width: DSIconSize.grid, height: DSIconSize.grid, radius: DSRadius.control)
        view.layer?.backgroundColor = color.cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = DSColor.border.cgColor
        return view
    }

    private static func block(width: CGFloat, height: CGFloat, radius: CGFloat) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = DSColor.accent.cgColor
        view.layer?.cornerRadius = radius
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: width),
            view.heightAnchor.constraint(equalToConstant: height),
        ])
        return view
    }

    private static func symbol(_ side: CGFloat) -> NSView {
        DSIconView(side: side, image: DSIconSize.symbol("folder.fill"))
    }
}
