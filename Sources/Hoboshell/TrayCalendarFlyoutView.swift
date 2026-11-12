import AppKit
import HoboshellCore

final class TrayCalendarFlyoutView: NSView {
    static let contentWidth = DSCalendarCell.side * CGFloat(TrayMonth.daysPerWeek + 1) + DSSpacing.xxs * CGFloat(TrayMonth.daysPerWeek)

    private let context: TrayFlyoutContext
    private let calendar = Calendar.autoupdatingCurrent
    private let monthTitle = DSLabel("", style: .body, weight: .semibold)
    private let monthFormatter = DateFormatter()
    private let gridHolder = NSStackView()
    private var shown: TrayMonth?

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        monthFormatter.locale = .autoupdatingCurrent
        monthFormatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        monthTitle.alignment = .center
        gridHolder.orientation = .vertical
        gridHolder.spacing = DSSpacing.xxs

        let longDate = DateFormatter()
        longDate.locale = .autoupdatingCurrent
        longDate.dateStyle = .long
        let today = DSLabel(longDate.string(from: Date()), style: .title, weight: .semibold)

        let previous = DSButton(symbol: "chevron.left", tip: "Previous month", height: .row)
        previous.onPress = { [weak self] in
            self?.move(by: -1)
        }
        let next = DSButton(symbol: "chevron.right", tip: "Next month", height: .row)
        next.onPress = { [weak self] in
            self?.move(by: 1)
        }
        let navigation = NSStackView(views: [previous, monthTitle, next])
        navigation.orientation = .horizontal
        navigation.alignment = .centerY
        monthTitle.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let todayButton = DSButton(title: "Today", height: .regular, alignment: .leading)
        todayButton.onPress = { [weak self] in
            self?.showCurrentMonth()
        }
        let settings = TraySettings.button(title: "Date and time settings", pane: TraySettings.dateAndTime, context: context)

        let rows = TrayFlyoutStack.make(
            [today, navigation, gridHolder, DSDivider(), todayButton, settings], spacing: DSSpacing.s
        )
        rows.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: trailingAnchor),
            rows.topAnchor.constraint(equalTo: topAnchor),
            rows.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        showCurrentMonth()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func showCurrentMonth() {
        let parts = calendar.dateComponents([.year, .month], from: Date())
        guard let year = parts.year, let month = parts.month else { return }
        show(TrayMonth.make(year: year, month: month, calendar: calendar))
    }

    private func move(by months: Int) {
        show(shown?.shifted(by: months, calendar: calendar))
    }

    private func show(_ month: TrayMonth?) {
        guard let month else { return }
        shown = month
        let first = calendar.date(from: DateComponents(year: month.year, month: month.month, day: 1)) ?? Date()
        monthTitle.stringValue = monthFormatter.string(from: first)
        gridHolder.arrangedSubviews.forEach { $0.removeFromSuperview() }
        gridHolder.addArrangedSubview(makeRow([DSCalendarCell("", style: .blank)] + month.weekdayLabels.map { DSCalendarCell($0, style: .weekday) }))
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        let isThisMonth = today.year == month.year && today.month == month.month
        for week in month.weeks {
            let days = week.days.map { day -> DSCalendarCell in
                guard let day else { return DSCalendarCell("", style: .blank) }
                return DSCalendarCell("\(day)", style: isThisMonth && today.day == day ? .today : .day)
            }
            gridHolder.addArrangedSubview(makeRow([DSCalendarCell("\(week.number)", style: .weekNumber)] + days))
        }
        context.refit()
    }

    private func makeRow(_ cells: [DSCalendarCell]) -> NSStackView {
        let row = NSStackView(views: cells)
        row.orientation = .horizontal
        row.spacing = DSSpacing.xxs
        return row
    }
}
