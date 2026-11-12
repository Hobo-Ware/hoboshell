import Darwin
import Foundation
import HoboshellCore
import Network

final class TrayNetwork {
    static let shared = TrayNetwork()
    static let didChange = Notification.Name("HoboshellTrayNetworkDidChange")

    private(set) var summary = NetworkSummary(isOnline: true, link: .other)
    private var interfaceNames: [String] = []
    private let monitor = NWPathMonitor()
    private var isStarted = false

    func start() {
        guard !isStarted else { return }
        isStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            let summary = NetworkSummary(isOnline: path.status == .satisfied, link: Self.link(of: path))
            let names = path.availableInterfaces.map(\.name)
            DispatchQueue.main.async {
                self?.summary = summary
                self?.interfaceNames = names
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
        monitor.start(queue: DispatchQueue(label: "dev.hoboware.hoboshell.network"))
    }

    func localAddress() -> String? {
        NetworkAddress.pick(from: Self.ipv4Addresses(), preferring: interfaceNames)
    }

    private static func link(of path: NWPath) -> NetworkLinkKind {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        if path.usesInterfaceType(.cellular) { return .cellular }
        return .other
    }

    private static func ipv4Addresses() -> [NetworkAddress.Candidate] {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return [] }
        defer { freeifaddrs(list) }
        var found: [NetworkAddress.Candidate] = []
        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let flags = Int32(entry.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0,
                  let socket = entry.pointee.ifa_addr, socket.pointee.sa_family == sa_family_t(AF_INET) else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let status = getnameinfo(socket, socklen_t(socket.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            guard status == 0 else { continue }
            found.append(NetworkAddress.Candidate(interface: String(cString: entry.pointee.ifa_name), address: String(cString: host)))
        }
        return found
    }
}
