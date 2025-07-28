/*
 * RouteX - Professional Network Route Manager for macOS
 * Copyright (C) 2025 awgh@awgh.org
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import SwiftUI

struct AddRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var routeManager: RouteManager

    // Route to edit (nil for new routes)
    let editingRoute: NetworkRoute?

    // Convenience initializer for new routes
    init(routeManager: RouteManager) {
        self.routeManager = routeManager
        self.editingRoute = nil
    }

    // Initializer for editing existing routes
    init(routeManager: RouteManager, editingRoute: NetworkRoute?) {
        self.routeManager = routeManager
        self.editingRoute = editingRoute
    }

    @State private var destination = ""
    @State private var gateway = ""
    @State private var interface = ""
    @State private var routeType = RouteType.auto
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    @State private var availableInterfaces: [String] = []
    @State private var showErrorDetails = false

    // Advanced options
    @State private var routeFlags: Set<RouteFlag> = []
    @State private var mtu = ""
    @State private var hopCount = ""
    @State private var expire = ""
    @State private var rtt = ""
    @State private var rttvar = ""
    @State private var sendpipe = ""
    @State private var recvpipe = ""
    @State private var ssthresh = ""

    // Add a new enum for gateway type
    enum GatewayInputType: String, CaseIterable, Identifiable {
        case ip = "IP Address"
        case iface = "Interface"
        case mac = "MAC Address"
        var id: String { self.rawValue }
    }
    @State private var gatewayType: GatewayInputType = .ip

    // Computed properties
    private var isEditing: Bool {
        editingRoute != nil
    }

    private var windowTitle: String {
        isEditing ? "Edit Route" : "Add New Route"
    }

    private var submitButtonTitle: String {
        isEditing ? "Update Route" : "Add Route"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 15) {
                Text(windowTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                // Simplified privilege information
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)

                    Text(isEditing ? "Administrator privileges will be requested when updating the route" : "Administrator privileges will be requested when adding the route")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 30)

            // Main configuration form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Basic Configuration Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Route Configuration")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 12) {
                            // Destination
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Destination")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                TextField("e.g., 192.168.1.0/24, 192.168.1, or 10", text: $destination)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: destination) { _ in validateInput() }

                                // Destination interpretation and route type controls
                                if !destination.isEmpty {
                                    let interpretation = NetworkRoute.interpretDestination(destination)

                                    VStack(alignment: .leading, spacing: 8) {
                                        // Route Type Selection
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Route Type")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)

                                            Picker("Route Type", selection: $routeType) {
                                                ForEach(RouteType.allCases, id: \.self) { type in
                                                    Text(type.displayName).tag(type)
                                                }
                                            }
                                            .pickerStyle(SegmentedPickerStyle())

                                            Text(routeType.description)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        // Interpretation Display
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: interpretation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                                    .foregroundColor(interpretation.isValid ? .green : .orange)

                                                Text("Interpretation:")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)

                                                Text(interpretation.statusDescription)
                                                    .font(.caption)
                                                    .foregroundColor(interpretation.isValid ? .primary : .orange)
                                            }

                                            if interpretation.isValid {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    if let networkForm = interpretation.networkForm {
                                                        HStack {
                                                            Text("As Network:")
                                                                .font(.caption2)
                                                                .foregroundColor(.secondary)
                                                            Text(networkForm)
                                                                .font(.caption2)
                                                                .foregroundColor(.primary)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(routeType == .auto && interpretation.interpretedType == .network || routeType == .network ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                                                .cornerRadius(4)
                                                        }
                                                    }

                                                    if let hostForm = interpretation.hostForm {
                                                        HStack {
                                                            Text("As Host:")
                                                                .font(.caption2)
                                                                .foregroundColor(.secondary)
                                                            Text(hostForm)
                                                                .font(.caption2)
                                                                .foregroundColor(.primary)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(routeType == .auto && interpretation.interpretedType == .host || routeType == .host ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                                                .cornerRadius(4)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }

                            // Gateway
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Gateway")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Picker("Gateway Type", selection: $gatewayType) {
                                    ForEach(AddRouteView.GatewayInputType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.bottom, 4)

                                TextField(gatewayType == .ip ? "e.g., 192.168.1.1 or 2001:db8::1" : (gatewayType == .iface ? "e.g., en0" : "e.g., 00:11:22:33:44:55"), text: $gateway)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(gatewayType == .iface)
                                    .onChange(of: gatewayType) { newType in
                                        if newType == .iface, !interface.isEmpty {
                                            gateway = interface
                                        }
                                    }

                                Text(gatewayType == .ip ? "IPv4 or IPv6 address" : (gatewayType == .iface ? "Interface name (e.g., en0)" : "MAC address (e.g., 00:11:22:33:44:55)"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if isEditing && editingRoute?.displayGateway.isEmpty == true {
                                    Text("Note: Original route uses a non-IP gateway. Please enter a valid value.")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            // Interface (conditional)
                            if gatewayType == .ip || gatewayType == .mac {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Interface (Optional)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Picker("Interface", selection: $interface) {
                                        Text("Auto").tag("")
                                        ForEach(availableInterfaces, id: \.self) { interface in
                                            Text(interface).tag(interface)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Advanced Options (Collapsible)
                    AdvancedOptionsSection(
                        routeFlags: $routeFlags,
                        mtu: $mtu,
                        hopCount: $hopCount,
                        expire: $expire,
                        rtt: $rtt,
                        rttvar: $rttvar,
                        sendpipe: $sendpipe,
                        recvpipe: $recvpipe,
                        ssthresh: $ssthresh,
                        gatewayType: $gatewayType,
                        isEditing: isEditing,
                        hasMutuallyExclusiveFlags: hasMutuallyExclusiveFlags
                    )
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .frame(height: 450)

            // Error message
            if !errorMessage.isEmpty {
                VStack(spacing: 8) {
                    ScrollView {
                        // Allow text selection for error message
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 180) // Increased height for better readability

                    // Show Details button for modal
                    Button("Show Details") {
                        showErrorDetails = true
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 30)
                .sheet(isPresented: $showErrorDetails) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Error Details")
                            .font(.headline)
                        ScrollView {
                            Text(errorMessage)
                                .textSelection(.enabled)
                                .font(.body)
                                .foregroundColor(.red)
                                .padding()
                        }
                        Button("Close") { showErrorDetails = false }
                            .padding(.top)
                    }
                    .padding()
                    .frame(minWidth: 400, minHeight: 300)
                }
            }

            // Action buttons
            HStack(spacing: 15) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button(submitButtonTitle) {
                    if isEditing {
                        updateRoute()
                    } else {
                        addRoute()
                    }
                }
                .disabled(!isValidInput || isSubmitting)
                .keyboardShortcut(.return)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            .padding(.horizontal, 30)
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadInterfaces()
            if let route = editingRoute {
                initializeFormWithRoute(route)
            }
        }
    }

    private var isValidInput: Bool {
        !destination.isEmpty && !gateway.isEmpty && errorMessage.isEmpty && !hasMutuallyExclusiveFlags
    }

    private var hasMutuallyExclusiveFlags: Bool {
        // Check for mutually exclusive flag combinations
        return routeFlags.contains(.blackhole) && routeFlags.contains(.reject)
    }

    private var flagCombinationError: String? {
        if routeFlags.contains(.blackhole) && routeFlags.contains(.reject) {
            return "Blackhole and Reject flags are mutually exclusive. A route cannot both silently drop packets (Blackhole) and send ICMP unreachable messages (Reject)."
        }
        return nil
    }

    private func validateInput() {
        errorMessage = ""

        // Check for mutually exclusive flag combinations first
        if let flagError = flagCombinationError {
            errorMessage = flagError
            return
        }

        if !destination.isEmpty {
            let interpretation = NetworkRoute.interpretDestination(destination)
            if !interpretation.isValid {
                errorMessage = interpretation.errorMessage ?? "Invalid destination format"
                return
            }
        }

        if !gateway.isEmpty {
            switch gatewayType {
            case .ip:
                if !routeManager.isValidIPAddress(gateway) {
                    // Check if it's an invalid IPv6 special address
                    let sanitized = routeManager.sanitizeIPv6Address(gateway)
                    if sanitized.contains(":") {
                        if sanitized == "::" {
                            errorMessage = "Invalid gateway: IPv6 unspecified address (::) cannot be used for routing."
                        } else if sanitized.lowercased() == "fe80::" {
                            errorMessage = "Invalid gateway: Use a complete link-local address like fe80::1, not the network prefix fe80::"
                        } else {
                            errorMessage = "Invalid gateway. Enter a valid IPv4 or IPv6 address."
                        }
                    } else {
                        errorMessage = "Invalid gateway. Enter a valid IPv4 or IPv6 address."
                    }
                }
            case .iface:
                if !routeManager.isValidInterfaceName(gateway) {
                    errorMessage = "Invalid gateway. Enter a valid interface name (e.g., en0)."
                }
            case .mac:
                if !routeManager.isValidMACAddress(gateway) {
                    errorMessage = "Invalid gateway. Enter a valid MAC address (e.g., 00:11:22:33:44:55)."
                }
            }
        }
    }

    private func loadInterfaces() {
        availableInterfaces = routeManager.getNetworkInterfaces()
    }

    private func initializeFormWithRoute(_ route: NetworkRoute) {
        destination = route.destination
        routeType = route.routeType

        // Detect gateway type and set value/type accordingly (support both IPv4 and IPv6)
        if routeManager.isValidIPAddress(route.gateway) {
            gateway = route.gateway
            gatewayType = .ip
        } else if routeManager.isValidInterfaceName(route.gateway) {
            gateway = route.gateway
            gatewayType = .iface
        } else if routeManager.isValidMACAddress(route.gateway) {
            gateway = route.gateway
            gatewayType = .mac
        } else {
            gateway = route.gateway
            gatewayType = .ip // Default fallback
        }

        interface = route.interface

        // Parse route flags
        let flagCharacters = Set(route.flags.map { String($0) })
        routeFlags = RouteFlag.allCases.filter { flagCharacters.contains($0.rawValue) }.reduce(into: Set<RouteFlag>()) { result, flag in
            result.insert(flag)
        }

        expire = route.expire

        // Fetch detailed metrics for this route
        if let detailedRoute = routeManager.getRouteDetails(for: route.destination) {
            mtu = detailedRoute.mtu
            hopCount = detailedRoute.hopCount
            rtt = detailedRoute.rtt
            rttvar = detailedRoute.rttvar
            sendpipe = detailedRoute.sendpipe
            recvpipe = detailedRoute.recvpipe
            ssthresh = detailedRoute.ssthresh
        } else {
            // Fallback to basic route data if detailed fetch fails
            mtu = route.mtu
            hopCount = route.hopCount
            rtt = route.rtt
            rttvar = route.rttvar
            sendpipe = route.sendpipe
            recvpipe = route.recvpipe
            ssthresh = route.ssthresh
        }
    }

    private func addRoute() {
        isSubmitting = true

        // Use the gateway value as entered, type is handled by backend
        let newRoute = NetworkRoute(
            destination: destination,
            gateway: gateway,
            interface: interface,
            flags: routeFlags.map { $0.rawValue }.joined(),
            expire: expire,
            routeType: routeType,
            mtu: mtu,
            hopCount: hopCount,
            rtt: rtt,
            rttvar: rttvar,
            sendpipe: sendpipe,
            recvpipe: recvpipe,
            ssthresh: ssthresh
        )

        // Add advanced options to the route
        var advancedOptions: [String: String] = [:]

        if !mtu.isEmpty { advancedOptions["mtu"] = mtu }
        if !hopCount.isEmpty { advancedOptions["hopcount"] = hopCount }
        if !rtt.isEmpty { advancedOptions["rtt"] = rtt }
        if !rttvar.isEmpty { advancedOptions["rttvar"] = rttvar }
        if !sendpipe.isEmpty { advancedOptions["sendpipe"] = sendpipe }
        if !recvpipe.isEmpty { advancedOptions["recvpipe"] = recvpipe }
        if !ssthresh.isEmpty { advancedOptions["ssthresh"] = ssthresh }

        routeManager.addRoute(newRoute, advancedOptions: advancedOptions) { success, error in
            isSubmitting = false

            if success {
                dismiss()
            } else {
                // AddRouteView error: \(error ?? "unknown")
                errorMessage = error ?? "Failed to add route"
            }
        }
    }

    private func updateRoute() {
        guard let originalRoute = editingRoute else { return }

        isSubmitting = true

        // First delete the original route
        routeManager.deleteRoute(originalRoute) { deleteSuccess, deleteError in

            if deleteSuccess {
                // Then add the updated route
                let updatedRoute = NetworkRoute(
                    destination: self.destination,
                    gateway: self.gateway,
                    interface: self.interface,
                    flags: self.routeFlags.map { $0.rawValue }.joined(),
                    expire: self.expire,
                    routeType: self.routeType,
                    mtu: self.mtu,
                    hopCount: self.hopCount,
                    rtt: self.rtt,
                    rttvar: self.rttvar,
                    sendpipe: self.sendpipe,
                    recvpipe: self.recvpipe,
                    ssthresh: self.ssthresh
                )

                // Add advanced options to the route
                var advancedOptions: [String: String] = [:]

                if !self.mtu.isEmpty { advancedOptions["mtu"] = self.mtu }
                if !self.hopCount.isEmpty { advancedOptions["hopcount"] = self.hopCount }
                if !self.rtt.isEmpty { advancedOptions["rtt"] = self.rtt }
                if !self.rttvar.isEmpty { advancedOptions["rttvar"] = self.rttvar }
                if !self.sendpipe.isEmpty { advancedOptions["sendpipe"] = self.sendpipe }
                if !self.recvpipe.isEmpty { advancedOptions["recvpipe"] = self.recvpipe }
                if !self.ssthresh.isEmpty { advancedOptions["ssthresh"] = self.ssthresh }

                self.routeManager.addRoute(updatedRoute, advancedOptions: advancedOptions) { success, error in
                    DispatchQueue.main.async {
                        self.isSubmitting = false

                        if success {
                            self.dismiss()
                        } else {
                            // AddRouteView error: \(error ?? "unknown")
                            // If adding the updated route failed, try to restore the original
                            self.routeManager.addRoute(originalRoute) { restoreSuccess, restoreError in
                                if !restoreSuccess {
                                    self.errorMessage = "Failed to update route and restore original: \(error ?? "Unknown error")"
                                } else {
                                    self.errorMessage = "Failed to update route: \(error ?? "Unknown error")"
                                }
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    // AddRouteView error: \(deleteError ?? "unknown")
                    self.errorMessage = "Failed to delete original route: \(deleteError ?? "Unknown error")"
                }
            }
        }
    }
}

// MARK: - Advanced Options Section

struct AdvancedOptionsSection: View {
    @Binding var routeFlags: Set<RouteFlag>
    @Binding var mtu: String
    @Binding var hopCount: String
    @Binding var expire: String
    @Binding var rtt: String
    @Binding var rttvar: String
    @Binding var sendpipe: String
    @Binding var recvpipe: String
    @Binding var ssthresh: String
    @Binding var gatewayType: AddRouteView.GatewayInputType
    let isEditing: Bool
    let hasMutuallyExclusiveFlags: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with disclosure indicator
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Advanced Options")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 8)

            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Route Flags
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Route Flags")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .help("Route flags control how the route behaves")
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 6) {
                            ForEach(RouteFlag.allCases, id: \.self) { flag in
                                let isConflicted = (flag == .blackhole && routeFlags.contains(.reject)) ||
                                                  (flag == .reject && routeFlags.contains(.blackhole))

                                HStack(spacing: 4) {
                                    Toggle(flag.displayName, isOn: Binding(
                                        get: {
                                            self.routeFlags.contains(flag)
                                        },
                                        set: { isOn in
                                            if isOn {
                                                self.routeFlags.insert(flag)
                                            } else {
                                                self.routeFlags.remove(flag)
                                            }
                                        }
                                    ))
                                    .toggleStyle(CheckboxToggleStyle())
                                    .font(.caption)
                                    .help(flag.description)

                                    if isConflicted {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption2)
                                            .help("This flag conflicts with another selected flag")
                                    }
                                }
                            }
                        }

                        // Show warning message for mutually exclusive flags
                        if hasMutuallyExclusiveFlags {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)

                                Text("Warning: Blackhole and Reject flags are mutually exclusive")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 4)
                        }

                        // Show info message for phantom routes
                        if routeFlags.contains(.blackhole) || routeFlags.contains(.reject) {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption2)

                                Text("Note: Blackhole and Reject routes won't appear in the main route list but will function normally")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Network Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Network Metrics")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .help("Network metrics help optimize routing performance")
                        }

                        // First row: MTU and Hop Count
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MTU")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("1500", text: $mtu)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hop Count")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("1", text: $hopCount)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }
                        }

                        // Second row: RTT and RTT Variance
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RTT (ms)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("10", text: $rtt)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("RTT Variance")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("5", text: $rttvar)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }
                        }

                        // Third row: Send and Receive Pipe
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Send Pipe")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("65536", text: $sendpipe)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Receive Pipe")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("65536", text: $recvpipe)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }
                        }

                        // Fourth row: SSThresh and Expire
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SSThresh")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("65536", text: $ssthresh)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expire (sec)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("3600", text: $expire)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Route Flag Enum

enum RouteFlag: String, CaseIterable {
    case staticRoute = "S"
    case reject = "R"
    case blackhole = "b"
    case llinfo = "L"

    var displayName: String {
        switch self {
        case .staticRoute: return "Static"
        case .reject: return "Reject"
        case .blackhole: return "Blackhole"
        case .llinfo: return "Link Info"
        }
    }

    var description: String {
        switch self {
        case .staticRoute: return "Static route - manually configured"
        case .reject: return "Reject route - sends ICMP unreachable"
        case .blackhole: return "Blackhole route - silently drops packets"
        case .llinfo: return "Link-level information available"
        }
    }
}

// MARK: - Custom Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}

#Preview {
    AddRouteView(routeManager: RouteManager())
}
