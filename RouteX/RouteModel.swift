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

import Foundation

// MARK: - Route Type Definitions

/// Enum to explicitly specify whether a route should be treated as network or host route
enum RouteType: String, CaseIterable, Codable {
    case auto = "auto"     // Automatically determine based on destination format
    case network = "net"   // Explicitly treat as network route (uses -net flag)
    case host = "host"     // Explicitly treat as host route (uses -host flag)

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .network: return "Network"
        case .host: return "Host"
        }
    }

    var description: String {
        switch self {
        case .auto: return "Automatically determine route type based on destination format"
        case .network: return "Force network route (destination represents a network/subnet)"
        case .host: return "Force host route (destination represents a single host)"
        }
    }
}

/// Result of interpreting a destination string for routing
struct DestinationInterpretation {
    let isValid: Bool
    let interpretedType: RouteType  // What we think it should be
    let networkForm: String?        // How it would look as a network route (e.g., "172.1.0.0/16")
    let hostForm: String?          // How it would look as a host route (e.g., "172.0.0.1/32")
    let errorMessage: String?      // Error if invalid

    var statusDescription: String {
        if !isValid {
            return errorMessage ?? "Invalid destination"
        }

        switch interpretedType {
        case .auto:
            return "Auto-detected"
        case .network:
            return "Network route"
        case .host:
            return "Host route"
        }
    }
}

struct NetworkRoute: Identifiable, Codable {
    var id = UUID()
    var destination: String
    var gateway: String
    var interface: String
    var flags: String
    var expire: String

    // Route type specification
    var routeType: RouteType = .auto

    // Advanced metrics fields
    var mtu: String = ""
    var hopCount: String = ""
    var rtt: String = ""
    var rttvar: String = ""
    var sendpipe: String = ""
    var recvpipe: String = ""
    var ssthresh: String = ""

    init(destination: String = "", gateway: String = "", interface: String = "", flags: String = "", expire: String = "",
         routeType: RouteType = .auto,
         mtu: String = "", hopCount: String = "", rtt: String = "", rttvar: String = "", sendpipe: String = "",
         recvpipe: String = "", ssthresh: String = "") {

        self.destination = destination
        self.gateway = gateway
        self.interface = interface
        self.flags = flags
        self.expire = expire
        self.routeType = routeType
        self.mtu = mtu
        self.hopCount = hopCount
        self.rtt = rtt
        self.rttvar = rttvar
        self.sendpipe = sendpipe
        self.recvpipe = recvpipe
        self.ssthresh = ssthresh
    }

    // MARK: - Destination Interpretation

    /// Interprets the destination string and provides network/host route options
    func interpretDestination() -> DestinationInterpretation {
        return NetworkRoute.interpretDestination(destination)
    }

    /// Static method to interpret any destination string
    static func interpretDestination(_ destination: String) -> DestinationInterpretation {
        // Handle empty destination
        if destination.isEmpty {
            return DestinationInterpretation(
                isValid: false,
                interpretedType: .auto,
                networkForm: nil,
                hostForm: nil,
                errorMessage: "Destination cannot be empty"
            )
        }

        // Handle special destinations
        if destination.lowercased() == "default" || destination == "0.0.0.0/0" {
            return DestinationInterpretation(
                isValid: true,
                interpretedType: .network,
                networkForm: "0.0.0.0/0",
                hostForm: nil,
                errorMessage: nil
            )
        }

        // Handle full CIDR notation (e.g., "192.168.1.0/24" or shorthand "172.16.42/24")
        if destination.contains("/") {
            if validateCIDRFormat(destination) {
                let components = destination.components(separatedBy: "/")
                let networkPart = components[0]
                let prefixLength = components[1]

                // Check if this is a /32 (host route) or network route
                if prefixLength == "32" {
                    // /32 is a host route - single IP address
                    let octets = networkPart.components(separatedBy: ".")
                    var expandedOctets = octets

                    // Right-pad with zeros to make complete IP address
                    while expandedOctets.count < 4 {
                        expandedOctets.append("0")
                    }

                    let hostForm = "\(expandedOctets.joined(separator: "."))/32"

                    return DestinationInterpretation(
                        isValid: true,
                        interpretedType: .host,
                        networkForm: nil,
                        hostForm: hostForm,
                        errorMessage: nil
                    )
                } else {
                    // All other CIDR prefixes are network routes
                    let octets = networkPart.components(separatedBy: ".")
                    var expandedOctets = octets

                    // Right-pad with zeros to make complete network address
                    while expandedOctets.count < 4 {
                        expandedOctets.append("0")
                    }

                    let expandedNetworkForm = "\(expandedOctets.joined(separator: "."))/\(prefixLength)"

                    return DestinationInterpretation(
                        isValid: true,
                        interpretedType: .network,
                        networkForm: expandedNetworkForm,
                        hostForm: nil,
                        errorMessage: nil
                    )
                }
            } else {
                return DestinationInterpretation(
                    isValid: false,
                    interpretedType: .auto,
                    networkForm: nil,
                    hostForm: nil,
                    errorMessage: "Invalid CIDR notation format"
                )
            }
        }

        // Handle IPv6 addresses
        if destination.contains(":") {
            if isValidIPv6Address(destination) {
                return DestinationInterpretation(
                    isValid: true,
                    interpretedType: .host,
                    networkForm: nil,
                    hostForm: destination + "/128",
                    errorMessage: nil
                )
            } else {
                return DestinationInterpretation(
                    isValid: false,
                    interpretedType: .auto,
                    networkForm: nil,
                    hostForm: nil,
                    errorMessage: "Invalid IPv6 address format"
                )
            }
        }

        // Handle IPv4 addresses and shorthand notation
        let components = destination.components(separatedBy: ".")

        // Validate all components are numeric and in valid range
        for component in components {
            guard let octet = Int(component), octet >= 0 && octet <= 255 else {
                return DestinationInterpretation(
                    isValid: false,
                    interpretedType: .auto,
                    networkForm: nil,
                    hostForm: nil,
                    errorMessage: "Invalid IP address format: octets must be 0-255"
                )
            }
        }

        var networkForm: String?
        var hostForm: String?
        var interpretedType: RouteType = .auto

        switch components.count {
        case 1:
            // Single octet: "172"
            // Network: 172.0.0.0/8, Host: 172.0.0.0/32
            let octet = components[0]
            networkForm = "\(octet).0.0.0/8"
            hostForm = "\(octet).0.0.0/32"
            interpretedType = .network  // Default to network for single octet

        case 2:
            // Two octets: "172.1"
            // Network: 172.1.0.0/16, Host: 172.0.0.1/32 (left-padded interpretation)
            let octet1 = components[0]
            let octet2 = components[1]
            networkForm = "\(octet1).\(octet2).0.0/16"
            hostForm = "\(octet1).0.0.\(octet2)/32"
            interpretedType = .network  // Default to network for two octets

        case 3:
            // Three octets: "192.168.1"
            // Network: 192.168.1.0/24, Host: 192.168.0.1/32 (left-padded interpretation)
            let octet1 = components[0]
            let octet2 = components[1]
            let octet3 = components[2]
            networkForm = "\(octet1).\(octet2).\(octet3).0/24"
            hostForm = "\(octet1).\(octet2).0.\(octet3)/32"
            interpretedType = .network  // Default to network for three octets

        case 4:
            // Full IP address: "192.168.1.100"
            // Network: 192.168.1.100/32 (treat as host), Host: 192.168.1.100/32
            networkForm = "\(destination)/32"
            hostForm = "\(destination)/32"
            interpretedType = .host  // Default to host for complete IP

        default:
            return DestinationInterpretation(
                isValid: false,
                interpretedType: .auto,
                networkForm: nil,
                hostForm: nil,
                errorMessage: "Invalid IP address format: too many octets"
            )
        }

        return DestinationInterpretation(
            isValid: true,
            interpretedType: interpretedType,
            networkForm: networkForm,
            hostForm: hostForm,
            errorMessage: nil
        )
    }

    /// Returns the effective route type considering user override
    func effectiveRouteType() -> RouteType {
        if routeType != .auto {
            return routeType
        }

        let interpretation = interpretDestination()
        return interpretation.interpretedType
    }

    /// Returns the destination string that should be used in route commands
    func getRouteCommandDestination() -> String {
        let interpretation = interpretDestination()
        let effectiveType = effectiveRouteType()

        switch effectiveType {
        case .auto:
            // This shouldn't happen, but fallback to original destination
            return destination
        case .network:
            return interpretation.networkForm ?? destination
        case .host:
            return interpretation.hostForm ?? destination
        }
    }

    // MARK: - Validation Helper Methods

    private static func validateCIDRFormat(_ cidr: String) -> Bool {
        let components = cidr.components(separatedBy: "/")
        guard components.count == 2 else { return false }

        // Validate the network address part (allow shorthand notation)
        let networkPart = components[0]
        let octets = networkPart.components(separatedBy: ".")

        // Allow 1-4 octets for shorthand notation (e.g., "172", "172.16", "172.16.42", "172.16.42.0")
        guard octets.count >= 1 && octets.count <= 4 else { return false }

        // Validate each octet is in valid range
        for octet in octets {
            guard let value = Int(octet), value >= 0 && value <= 255 else { return false }
        }

        // Validate prefix length
        guard let prefixLength = Int(components[1]),
              prefixLength >= 0 && prefixLength <= 32 else { return false }

        return true
    }

    private static func isValidIPv6Address(_ address: String) -> Bool {
        var ipv6addr = in6_addr()
        return address.withCString { inet_pton(AF_INET6, $0, &ipv6addr) } == 1
    }

    private static func isValidIPAddress(_ ip: String) -> Bool {
        // Check IPv4
        var ipv4addr = in_addr()
        if ip.withCString({ inet_pton(AF_INET, $0, &ipv4addr) }) == 1 {
            return true
        }

        // Check IPv6
        var ipv6addr = in6_addr()
        if ip.withCString({ inet_pton(AF_INET6, $0, &ipv6addr) }) == 1 {
            return true
        }

        return false
    }

    // MARK: - CIDR and Network Functions

    /// Returns the normalized CIDR representation of this route's destination
    var normalizedCIDR: CIDRInfo? {
        return normalizeToCIDR(destination)
    }

    /// Returns the CIDR prefix length for this route
    var cidrPrefixLength: Int {
        return normalizedCIDR?.prefixLength ?? 0
    }

    /// Returns the network address for this route
    var networkAddress: String {
        return normalizedCIDR?.networkAddress ?? destination
    }

    /// Returns the specificity score (higher = more specific)
    var specificity: Int {
        // Default route (0.0.0.0/0) has lowest specificity
        if isDefaultRoute {
            return 0
        }
        return cidrPrefixLength
    }

    /// Checks if this route matches a given IP address or CIDR range
    func matches(searchTerm: String) -> Bool {
        // Direct string match
        if destination.localizedCaseInsensitiveContains(searchTerm) ||
           gateway.localizedCaseInsensitiveContains(searchTerm) ||
           interface.localizedCaseInsensitiveContains(searchTerm) {
            return true
        }

        // Normalize search term to CIDR and compare
        if let searchCIDR = normalizeToCIDR(searchTerm),
           let routeCIDR = normalizedCIDR {
            return routeCIDR.overlaps(with: searchCIDR)
        }

        // IP address match
        if let searchIP = NetworkRoute.parseIPAddress(from: searchTerm),
           let routeCIDR = normalizedCIDR {
            return routeCIDR.contains(searchIP)
        }

        return false
    }

    /// Checks if this is a default route (0.0.0.0/0 or "default")
    var isDefaultRoute: Bool {
        return destination == "default" || destination == "0.0.0.0/0"
    }

    /// Checks if this route contains a specific IP address
    func containsIP(_ ip: String) -> Bool {
        guard let routeCIDR = normalizedCIDR,
              let ipAddress = NetworkRoute.parseIPAddress(from: ip) else {
            return false
        }

        return routeCIDR.contains(ipAddress)
    }

    /// Returns a human-readable gateway display value
    /// Shows only IP addresses, leaves blank for MAC addresses, interface names, etc.
    var displayGateway: String {
        return self.gateway
    }

    /// Determines if this route can be safely edited by users
    var isEditable: Bool {
        // Routes that should NOT be edited (system-managed):

        // 1. Cache/Cloning routes (C flag) - automatically managed
        if flags.contains("C") {
            return false
        }

        // 2. Cloned routes (W flag) - dynamically created from parent routes
        if flags.contains("W") {
            return false
        }

        // 3. Interface scope routes (I or i flags) - system interface management
        if flags.contains("I") || flags.contains("i") {
            return false
        }

        // 4. Link-local auto-configuration (169.254.0.0/16)
        if destination.hasPrefix("169.254") {
            return false
        }

        // 5. Routes to specific MAC addresses (gateway contains colons in MAC format)
        if gateway.contains(":") && gateway.split(separator: ":").count == 6 {
            // This looks like a MAC address - likely an ARP entry
            return false
        }

        // 6. Link# gateways (internal kernel references)
        if gateway.hasPrefix("link#") {
            return false
        }

        // Routes that ARE editable:
        // - Static routes (S flag)
        // - User-created gateway routes (UGS, UGSc without C/W/I flags)
        // - User-created host routes (UH without W flag)
        // - User-created reject routes (UR)

        return true
    }

    /// Returns a description of the gateway type for tooltips and debugging
    var gatewayTypeDescription: String {
        // Check if gateway is a valid IP address
        if let _ = NetworkRoute.parseIPAddress(from: gateway) {
            return "IP Gateway: \(gateway)"
        }

        // Check if it's a MAC address (contains colons and hex characters)
        if gateway.contains(":") && gateway.count == 17 {
            let components = gateway.components(separatedBy: ":")
            if components.count == 6 {
                var isValidMAC = true
                for component in components {
                    if component.count == 2 && component.range(of: "^[0-9A-Fa-f]{2}$", options: .regularExpression) == nil {
                        isValidMAC = false
                        break
                    }
                }
                if isValidMAC {
                    return "MAC Address: \(gateway)"
                }
            }
        }

        // Check if it's an interface name (common interface prefixes)
        let interfacePrefixes = ["en", "lo", "bridge", "utun", "gif", "stf", "p2p"]
        for prefix in interfacePrefixes {
            if gateway.hasPrefix(prefix) {
                return "Interface: \(gateway)"
            }
        }

        // Check if it's a link reference (link#number)
        if gateway.hasPrefix("link#") {
            return "Link Reference: \(gateway)"
        }

        // Check if it's a special value
        if gateway == "*" {
            return "No Gateway (direct interface)"
        }

        // Default case
        return "Gateway: \(gateway)"
    }

    /// Checks if this route matches a given CIDR range
    func matchesCIDR(_ searchCIDR: CIDRInfo) -> Bool {
        guard let routeCIDR = normalizedCIDR else {
            return false
        }

        // Check if the search CIDR overlaps with this route's CIDR
        return routeCIDR.overlaps(with: searchCIDR)
    }

    // MARK: - Helper Functions

    /// Normalizes any network notation to CIDR format
    /// Supports: "192.168.1.0/24", "192.168.1", "192.168", "127", "default", etc.
    private func normalizeToCIDR(_ string: String) -> CIDRInfo? {
        // Handle special cases
        if string.lowercased() == "default" {
            return CIDRInfo(networkAddress: "0.0.0.0", prefixLength: 0)
        }

        // If it's already in CIDR format, parse it directly
        if string.contains("/") {
            return parseCIDR(from: string)
        }

        // Handle shorthand notation
        let components = string.components(separatedBy: ".")

        // Determine the prefix length based on the number of octets
        let prefixLength: Int
        let networkAddress: String

        switch components.count {
        case 1:
            // Single octet: "127" -> "127.0.0.0/8"
            guard let octet = Int(components[0]), octet >= 0 && octet <= 255 else {
                return nil
            }
            prefixLength = 8
            networkAddress = "\(octet).0.0.0"

        case 2:
            // Two octets: "192.168" -> "192.168.0.0/16"
            guard let octet1 = Int(components[0]), octet1 >= 0 && octet1 <= 255,
                  let octet2 = Int(components[1]), octet2 >= 0 && octet2 <= 255 else {
                return nil
            }
            prefixLength = 16
            networkAddress = "\(octet1).\(octet2).0.0"

        case 3:
            // Three octets: "192.168.1" -> "192.168.1.0/24"
            guard let octet1 = Int(components[0]), octet1 >= 0 && octet1 <= 255,
                  let octet2 = Int(components[1]), octet2 >= 0 && octet2 <= 255,
                  let octet3 = Int(components[2]), octet3 >= 0 && octet3 <= 255 else {
                return nil
            }
            prefixLength = 24
            networkAddress = "\(octet1).\(octet2).\(octet3).0"

        case 4:
            // Full IP address: "192.168.1.1" -> "192.168.1.1/32"
            guard let ipAddress = NetworkRoute.parseIPAddress(from: string) else {
                return nil
            }
            prefixLength = 32
            networkAddress = ipAddress

        default:
            return nil
        }

        return CIDRInfo(networkAddress: networkAddress, prefixLength: prefixLength)
    }

    /// Parses CIDR notation (e.g., "192.168.1.0/24", "172.16.42/24")
    private func parseCIDR(from string: String) -> CIDRInfo? {
        let components = string.components(separatedBy: "/")
        guard components.count == 2,
              let prefixLength = Int(components[1]),
              prefixLength >= 0 && prefixLength <= 32 else {
            return nil
        }

        // Parse the network address part, supporting shorthand notation
        let networkAddressPart = components[0]
        let networkAddress = parseNetworkAddress(from: networkAddressPart)

        guard let networkAddress = networkAddress else {
            return nil
        }

        return CIDRInfo(networkAddress: networkAddress, prefixLength: prefixLength)
    }

    /// Parses a network address string, supporting shorthand notation
    /// Examples: "192.168.1.0", "192.168.1", "192.168", "127"
    private func parseNetworkAddress(from string: String) -> String? {
        let components = string.components(separatedBy: ".")

        // Validate each component
        for component in components {
            guard let octet = Int(component), octet >= 0 && octet <= 255 else {
                return nil
            }
        }

        // Pad with zeros to make it a full IP address
        var paddedComponents = components
        while paddedComponents.count < 4 {
            paddedComponents.append("0")
        }

        return paddedComponents.joined(separator: ".")
    }

    /// Parses an IP address string, right-padding for networks (default)
    static func parseIPAddress(from string: String) -> String? {
        // Sanitize IPv6 addresses by removing zone identifiers and prefix lengths
        var sanitized = string

        // Remove zone identifier (e.g., %utun5, %en0)
        if let percentIndex = sanitized.firstIndex(of: "%") {
            sanitized = String(sanitized[..<percentIndex])
        }

        // Remove prefix length (e.g., /64, /128)
        if let slashIndex = sanitized.firstIndex(of: "/") {
            sanitized = String(sanitized[..<slashIndex])
        }

        // Use Swift's built-in IPv4/IPv6 detection
        var ipv4addr = in_addr()
        var ipv6addr = in6_addr()
        if sanitized.withCString({ inet_pton(AF_INET, $0, &ipv4addr) }) == 1 {
            return sanitized // IPv4
        }
        if sanitized.withCString({ inet_pton(AF_INET6, $0, &ipv6addr) }) == 1 {
            return sanitized // IPv6
        }
        return nil
    }

    /// Parses a host address string, left-padding for hosts (e.g., 128.32 -> 128.0.0.32)
    func parseHostAddressLeftPad(_ string: String) -> String? {
        let components = string.components(separatedBy: ".")
        guard components.count >= 1 && components.count <= 4 else { return nil }

        // Left-pad for host addresses
        var paddedComponents = components
        while paddedComponents.count < 4 {
            paddedComponents.insert("0", at: paddedComponents.startIndex)
        }

        // Validate each component
        for component in paddedComponents {
            guard let octet = Int(component), octet >= 0 && octet <= 255 else {
                return nil
            }
        }

        return paddedComponents.joined(separator: ".")
    }

    // MARK: - Flag Descriptions

    var flagDescription: String {
        var descriptions: [String] = []

        for char in flags {
            switch char {
            case "U": descriptions.append("Up")
            case "G": descriptions.append("Gateway")
            case "H": descriptions.append("Host")
            case "S": descriptions.append("Static")
            case "C": descriptions.append("Clone")
            case "W": descriptions.append("Was cloned")
            case "L": descriptions.append("Link")
            case "M": descriptions.append("Modified")
            case "D": descriptions.append("Dynamic")
            case "A": descriptions.append("Address")
            case "R": descriptions.append("Reject")
            case "I": descriptions.append("Interface")
            case "B": descriptions.append("Broadcast")
            case "b": descriptions.append("Blackhole")
            case "c": descriptions.append("Cloned")
            case "g": descriptions.append("Gateway")
            case "r": descriptions.append("Reject")
            case "s": descriptions.append("Static")
            case "u": descriptions.append("Up")
            default: break
            }
        }

        return descriptions.isEmpty ? "No flags" : descriptions.joined(separator: ", ")
    }

    // Parse route from netstat output line
    static func parse(from line: String) -> NetworkRoute? {
        // Skip empty lines and headers
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("Destination") || trimmed.hasPrefix("Kernel") || trimmed.hasPrefix("Internet:") {
            return nil
        }

        // Split the line into components
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Ensure we have enough components
        guard components.count >= 4 else { return nil }

        let destination = components[0]
        let gateway = components[1]
        let flags = components[2]
        let interface = components[3]

        // Handle optional fields - expire is in column 5 (after Netif)
        let expire = components.count > 4 ? components[4] : ""

        // Extract metrics from verbose output
        var mtu = ""
        var hopCount = ""
        var rtt = ""
        var rttvar = ""
        var sendpipe = ""
        var recvpipe = ""
        var ssthresh = ""

        // Parse additional fields from verbose output
        if components.count > 5 {
            for index in 5..<components.count {
                let field = components[index]

                // Look for metric patterns
                if field.hasPrefix("mtu=") {
                    mtu = String(field.dropFirst(4))
                } else if field.hasPrefix("hop=") {
                    hopCount = String(field.dropFirst(4))
                } else if field.hasPrefix("rtt=") {
                    rtt = String(field.dropFirst(4))
                } else if field.hasPrefix("rttvar=") {
                    rttvar = String(field.dropFirst(7))
                } else if field.hasPrefix("sendpipe=") {
                    sendpipe = String(field.dropFirst(9))
                } else if field.hasPrefix("recvpipe=") {
                    recvpipe = String(field.dropFirst(9))
                } else if field.hasPrefix("ssthresh=") {
                    ssthresh = String(field.dropFirst(9))
                }
            }
        }

        return NetworkRoute(
            destination: destination,
            gateway: gateway,
            interface: interface,
            flags: flags,
            expire: expire,
            mtu: mtu,
            hopCount: hopCount,
            rtt: rtt,
            rttvar: rttvar,
            sendpipe: sendpipe,
            recvpipe: recvpipe,
            ssthresh: ssthresh
        )
    }

    // Convert to route command arguments
    func toRouteArgs() -> [String] {
        var args: [String] = []

        // Add destination
        args.append(destination)

        // Add gateway
        args.append(gateway)

        // Add interface if specified and not empty
        if !interface.isEmpty && interface != "*" {
            args.append("-ifscope")
            args.append(interface)
        }

        return args
    }

    // Convert to netstat command arguments (legacy method)
    func toNetstatArgs() -> [String] {
        return [destination, gateway, interface]
    }
}

// MARK: - CIDR Information Structure

struct CIDRInfo {
    let networkAddress: String
    let prefixLength: Int

    /// Returns the subnet mask for this CIDR
    var subnetMask: String {
        let mask = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF
        let octets = [
            (mask >> 24) & 0xFF,
            (mask >> 16) & 0xFF,
            (mask >> 8) & 0xFF,
            mask & 0xFF
        ]
        return octets.map(String.init).joined(separator: ".")
    }

    /// Returns the first IP address in this range
    var firstIP: String {
        return networkAddress
    }

    /// Returns the last IP address in this range
    var lastIP: String {
        let hostBits = 32 - prefixLength
        let hostMask: UInt32 = (1 << hostBits) - 1
        let networkBits = (parseIPToInt(networkAddress) ?? 0) & (0xFFFFFFFF << hostBits)
        let lastIPInt = networkBits | hostMask
        return parseIntToIP(lastIPInt)
    }

    /// Checks if this CIDR contains a specific IP address
    func contains(_ ip: String) -> Bool {
        guard let ipInt = parseIPToInt(ip),
              let networkInt = parseIPToInt(networkAddress) else {
            return false
        }

        let hostBits = 32 - prefixLength
        let networkMask: UInt32 = 0xFFFFFFFF << hostBits
        let networkBits = networkInt & networkMask
        let ipNetworkBits = ipInt & networkMask

        return networkBits == ipNetworkBits
    }

    /// Checks if this CIDR overlaps with another CIDR
    func overlaps(with other: CIDRInfo) -> Bool {
        // Check if the network addresses are in the same range
        guard let thisNetwork = parseIPToInt(networkAddress),
              let otherNetwork = parseIPToInt(other.networkAddress) else {
            return false
        }

        let thisHostBits = 32 - prefixLength
        let otherHostBits = 32 - other.prefixLength
        let maxHostBits = max(thisHostBits, otherHostBits)
        let mask: UInt32 = 0xFFFFFFFF << maxHostBits

        return (thisNetwork & mask) == (otherNetwork & mask)
    }

    // MARK: - Helper Functions

    private func parseIPToInt(_ ip: String) -> UInt32? {
        let components = ip.components(separatedBy: ".")
        guard components.count == 4 else { return nil }

        var result: UInt32 = 0
        for (index, component) in components.enumerated() {
            guard let octet = UInt32(component), octet <= 255 else { return nil }
            result |= octet << ((3 - index) * 8)
        }
        return result
    }

    private func parseIntToIP(_ int: UInt32) -> String {
        let octets = [
            (int >> 24) & 0xFF,
            (int >> 16) & 0xFF,
            (int >> 8) & 0xFF,
            int & 0xFF
        ]
        return octets.map(String.init).joined(separator: ".")
    }
}

#if DEBUG
func testHostNetworkShorthandParsing() {
    let model = NetworkRoute()
    // Host shorthand
    assert(model.parseHostAddressLeftPad("128.32") == "128.0.0.32", "Host shorthand 128.32 failed")
    assert(model.parseHostAddressLeftPad("128.32.130") == "128.32.0.130", "Host shorthand 128.32.130 failed")
    assert(model.parseHostAddressLeftPad("128.32.130.1") == "128.32.130.1", "Host shorthand 128.32.130.1 failed")
    // Network shorthand
    assert(NetworkRoute.parseIPAddress(from: "128.32") == "128.32.0.0", "Network shorthand 128.32 failed")
    assert(NetworkRoute.parseIPAddress(from: "128.32.130") == "128.32.130.0", "Network shorthand 128.32.130 failed")
    assert(NetworkRoute.parseIPAddress(from: "128.32.130.1") == "128.32.130.1", "Network shorthand 128.32.130.1 failed")
            // Host and network shorthand parsing tests passed.
}
#endif
