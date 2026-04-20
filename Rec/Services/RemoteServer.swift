import Foundation
import Network
import Combine

class RemoteServer: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL: String = ""
    @Published var connectedClients = 0

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var appState: AppState?
    private let queue = DispatchQueue(label: "com.rec.remoteserver")

    func start(appState: AppState) {
        self.appState = appState
        let port = NWEndpoint.Port(integerLiteral: UInt16(appState.remotePort))

        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            listener = try NWListener(using: parameters, on: port)
        } catch {
            print("Failed to create listener: \(error)")
            return
        }

        listener?.service = NWListener.Service(name: "Rec Remote", type: "_http._tcp")

        listener?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isRunning = true
                    self?.updateServerURL()
                case .failed, .cancelled:
                    self?.isRunning = false
                default:
                    break
                }
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
        DispatchQueue.main.async {
            self.isRunning = false
            self.connectedClients = 0
        }
    }

    private func updateServerURL() {
        if let address = getLocalIPAddress() {
            let port = appState?.remotePort ?? 8089
            serverURL = "http://\(address):\(port)"
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                DispatchQueue.main.async {
                    self?.connectedClients += 1
                }
                self?.receiveData(on: connection)
            case .failed, .cancelled:
                DispatchQueue.main.async {
                    self?.connectedClients = max(0, (self?.connectedClients ?? 1) - 1)
                }
            default:
                break
            }
        }

        connections.append(connection)
        connection.start(queue: queue)
    }

    private func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleHTTPRequest(data: data, connection: connection)
            }
            if isComplete || error != nil {
                connection.cancel()
            } else {
                self?.receiveData(on: connection)
            }
        }
    }

    private func handleHTTPRequest(data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else { return }
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return }

        let method = parts[0]
        let path = parts[1]

        switch (method, path) {
        case ("GET", "/"):
            sendHTMLResponse(connection: connection)
        case ("POST", "/play"):
            DispatchQueue.main.async { [weak self] in
                self?.appState?.isPaused = false
            }
            sendJSONResponse(connection: connection, json: "{\"status\":\"playing\"}")
        case ("POST", "/pause"):
            DispatchQueue.main.async { [weak self] in
                self?.appState?.isPaused = true
            }
            sendJSONResponse(connection: connection, json: "{\"status\":\"paused\"}")
        case ("POST", "/stop"):
            DispatchQueue.main.async { [weak self] in
                self?.appState?.stopPrompting()
            }
            sendJSONResponse(connection: connection, json: "{\"status\":\"stopped\"}")
        case ("POST", "/speed-up"):
            DispatchQueue.main.async { [weak self] in
                self?.appState?.adjustSpeed(by: 0.5)
            }
            sendJSONResponse(connection: connection, json: "{\"status\":\"ok\",\"speed\":\(self.appState?.scrollSpeed ?? 2.0)}")
        case ("POST", "/speed-down"):
            DispatchQueue.main.async { [weak self] in
                self?.appState?.adjustSpeed(by: -0.5)
            }
            sendJSONResponse(connection: connection, json: "{\"status\":\"ok\",\"speed\":\(self.appState?.scrollSpeed ?? 2.0)}")
        case ("GET", "/status"):
            let state = appState
            let json = """
            {"playing":\(state?.isPrompting == true && state?.isPaused != true),"paused":\(state?.isPaused ?? false),"speed":\(state?.scrollSpeed ?? 2.0),"script":"\(state?.currentScript?.title ?? "None")"}
            """
            sendJSONResponse(connection: connection, json: json)
        default:
            sendNotFound(connection: connection)
        }
    }

    private func sendHTMLResponse(connection: NWConnection) {
        let html = RemoteControlHTML.page
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
        sendResponse(connection: connection, response: response)
    }

    private func sendJSONResponse(connection: NWConnection, json: String) {
        let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(json.utf8.count)\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n\(json)"
        sendResponse(connection: connection, response: response)
    }

    private func sendNotFound(connection: NWConnection) {
        let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        sendResponse(connection: connection, response: response)
    }

    private func sendResponse(connection: NWConnection, response: String) {
        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil, 0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
}
