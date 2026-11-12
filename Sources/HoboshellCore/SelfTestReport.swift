public struct SelfTestStep: Equatable {
    public let name: String
    public let milliseconds: Double?
    public let failure: String?
    public let budgetMilliseconds: Double

    public init(
        name: String,
        milliseconds: Double?,
        failure: String? = nil,
        budgetMilliseconds: Double = SelfTestReport.budgetMilliseconds
    ) {
        self.name = name
        self.milliseconds = milliseconds
        self.failure = failure
        self.budgetMilliseconds = budgetMilliseconds
    }
}

public struct SelfTestReport: Equatable {
    public static let budgetMilliseconds = 150.0

    public private(set) var steps: [SelfTestStep] = []

    public init() {}

    public mutating func add(_ step: SelfTestStep) {
        steps.append(step)
    }

    public func passes(_ step: SelfTestStep) -> Bool {
        guard step.failure == nil, let milliseconds = step.milliseconds else { return false }
        return milliseconds <= step.budgetMilliseconds
    }

    public var allPassed: Bool {
        !steps.isEmpty && steps.allSatisfy(passes)
    }

    public func line(for index: Int) -> String {
        let step = steps[index]
        let time = step.milliseconds.map { "\(Self.format($0)) ms" } ?? "no time"
        let verdict = passes(step) ? "PASS" : "FAIL"
        let reason = step.failure.map { " (\($0))" } ?? ""
        let ownBudget = step.budgetMilliseconds == Self.budgetMilliseconds ? "" : " (budget \(Self.format(step.budgetMilliseconds)) ms)"
        return "step \(index + 1) \(step.name): \(time) \(verdict)\(reason)\(ownBudget)"
    }

    public var summary: String {
        let passed = steps.filter(passes).count
        let slowest = steps.compactMap(\.milliseconds).max().map(Self.format) ?? "none"
        let budget = Self.format(Self.budgetMilliseconds)
        return "realtime self-test: \(passed) of \(steps.count) steps passed, slowest \(slowest) ms, budget \(budget) ms"
    }

    public var text: String {
        (steps.indices.map(line(for:)) + [summary]).joined(separator: "\n") + "\n"
    }

    public static func format(_ milliseconds: Double) -> String {
        let tenths = (milliseconds * 10).rounded() / 10
        let whole = Int(tenths)
        let fraction = Int(((tenths - Double(whole)) * 10).rounded())
        return "\(whole).\(fraction)"
    }
}

public struct SelfTestArguments: Equatable {
    public let reportPath: String?

    public static func parse(_ arguments: [String]) -> SelfTestArguments? {
        guard let flag = arguments.firstIndex(of: "--selftest"),
              arguments.indices.contains(flag + 1), arguments[flag + 1] == "realtime" else { return nil }
        let path = arguments.firstIndex(of: "--selftest-report")
            .flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
        return SelfTestArguments(reportPath: path)
    }
}
