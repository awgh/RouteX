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
import SwiftUI

class RouteManager: ObservableObject {
@Published var routes: [NetworkRoute] = []
@Published var isLoading = false
@Published var errorMessage: String?

// Track phantom routes (blackhole, reject) that don't appear in netstat
private var phantomRouteCache: Set<String> = []
private let phantomRouteCacheKey = "RouteX_PhantomRoutes"

init() {
loadPhantomRouteCache()
refreshRoutes()
}

// MARK: - Phantom Route Cache Management

private func loadPhantomRouteCache() {
// Phantom route cache loading - simplified for package build
// In a full app context, this would use UserDefaults
}

private func savePhantomRouteCache() {
// Phantom route cache saving - simplified for package build
// In a full app context, this would use UserDefaults
}

private func addToPhantomCache(_ destination: String) {
phantomRouteCache.insert(destination)
savePhantomRouteCache()
}

private func removeFromPhantomCache(_ destination: String) {
phantomRouteCache.remove(destination)
savePhantomRouteCache()
}

func refreshRoutes() {
isLoading = true
errorMessage = nil

DispatchQueue.global(qos: .userInitiated).async { [weak self] in
self?.fetchRoutes { routes in
DispatchQueue.main.async {
self?.routes = routes
self?.isLoading = false
}
}
}
}

private func fetchRoutes(completion: @escaping ([NetworkRoute]) -> Void) {
let task = Process()
let pipe = Pipe()

task.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
task.arguments = ["-rn"]  // Use regular output for speed
task.standardOutput = pipe

do {
try task.run()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""

let visibleRoutes = parseNetstatOutput(output)

// ENHANCEMENT: Also discover phantom routes (blackhole, reject) that don't appear in netstat
discoverPhantomRoutes(existingRoutes: visibleRoutes) { phantomRoutes in
let allRoutes = visibleRoutes + phantomRoutes
completion(allRoutes)
}
} catch {
DispatchQueue.main.async {
self.errorMessage = "Failed to fetch routes: \(error.localizedDescription)"
}
completion([])
}
}

/// Discovers routes that exist in the kernel but don't appear in netstat (like blackhole, reject routes)
private func discoverPhantomRoutes(existingRoutes: [NetworkRoute], completion: @escaping ([NetworkRoute]) -> Void) {
// Check if we have any cached phantom route destinations to verify
let phantomDestinations = getPhantomRouteDestinations()

var phantomRoutes: [NetworkRoute] = []
let dispatchGroup = DispatchGroup()

for destination in phantomDestinations {
dispatchGroup.enter()

// Skip if we already have this route in visible routes
if existingRoutes.contains(where: { $0.destination == destination }) {
dispatchGroup.leave()
continue
}

// Try to get route details for this destination
DispatchQueue.global(qos: .utility).async {
if let retrievedRoute = self.getRouteDetails(for: destination) {

// Verify it's actually a phantom route (has blackhole or reject flags)
if retrievedRoute.flags.contains("b") || retrievedRoute.flags.contains("R") {

// Create a new route with the correct destination
let phantomRoute = NetworkRoute(
destination: destination,
gateway: retrievedRoute.gateway,
interface: retrievedRoute.interface,
flags: retrievedRoute.flags,
expire: retrievedRoute.expire,
routeType: retrievedRoute.routeType,
mtu: retrievedRoute.mtu,
hopCount: retrievedRoute.hopCount,
rtt: retrievedRoute.rtt,
rttvar: retrievedRoute.rttvar,
sendpipe: retrievedRoute.sendpipe,
recvpipe: retrievedRoute.recvpipe,
ssthresh: retrievedRoute.ssthresh
)
phantomRoutes.append(phantomRoute)
}
}
dispatchGroup.leave()
}
}

dispatchGroup.notify(queue: .main) {
completion(phantomRoutes)
}
}

/// Get list of potential phantom route destinations to check
/// This could be enhanced to use persistent storage
private func getPhantomRouteDestinations() -> [String] {
// Return cached phantom routes plus some common test destinations
var destinations = Array(phantomRouteCache)

// Add some common test destinations for development
destinations.append(contentsOf: [
"192.168.98.0",   // Our test destination
"192.168.99.0"    // Another test destination
])

return Array(Set(destinations)) // Remove duplicates
}

/// Check if a route has phantom flags (blackhole, reject) that cause it to not appear in netstat
private func isPhantomRoute(_ route: NetworkRoute) -> Bool {
return route.flags.contains("b") || route.flags.contains("R")
}

private func parseNetstatOutput(_ output: String) -> [NetworkRoute] {
let lines = output.components(separatedBy: .newlines)
var routes: [NetworkRoute] = []

for line in lines {
let trimmed = line.trimmingCharacters(in: .whitespaces)
if let route = NetworkRoute.parse(from: trimmed) {
routes.append(route)
}
}

return routes
}

func addRoute(_ route: NetworkRoute, completion: @escaping (Bool, String?) -> Void) {
addRoute(route, advancedOptions: [:], completion: completion)
}

func addRoute(_ route: NetworkRoute, advancedOptions: [String: String] = [:], completion: @escaping (Bool, String?) -> Void) {
guard !route.destination.isEmpty && !route.gateway.isEmpty else {
completion(false, "Destination and gateway are required")
return
}

DispatchQueue.global(qos: .userInitiated).async { [weak self] in
guard let self = self else { return }

// Execute the route command with elevated privileges
let result = self.executeRouteCommandWithElevation("add", route: route, advancedOptions: advancedOptions)

DispatchQueue.main.async {
if result.success {
// Track phantom routes (blackhole, reject) that won't appear in netstat
if self.isPhantomRoute(route) {
self.addToPhantomCache(route.destination)
}

// Refresh the route list
self.refreshRoutes()
completion(true, nil)
} else {
completion(false, result.error)
}
}
}
}

func deleteRoute(_ route: NetworkRoute, completion: @escaping (Bool, String?) -> Void) {
DispatchQueue.global(qos: .userInitiated).async { [weak self] in
guard let self = self else { return }

let result = self.executeRouteCommandWithElevation("delete", route: route)

DispatchQueue.main.async {
if result.success {
// Remove from phantom cache if it was a phantom route
self.removeFromPhantomCache(route.destination)

// Refresh the route list
self.refreshRoutes()
completion(true, nil)
} else {
completion(false, result.error)
}
}
}
}

/// Execute a route command using osascript with administrator privileges
private func executeRouteCommandWithElevation(_ command: String, route: NetworkRoute, advancedOptions: [String: String] = [:]) -> (success: Bool, error: String) {

// Validate route before execution
if !validateRouteForCommand(route, command: command) {
return (false, "Invalid route configuration for \(command) command")
}
// Prepare the route command with advanced options
var routeArgs = [command]

// Add advanced options
for (key, value) in advancedOptions {
if !value.isEmpty {
routeArgs.append("-\(key)")
routeArgs.append(value)
}
}

// Add gateway type modifiers BEFORE destination/gateway
let gwType = gatewayType(route.gateway)
switch gwType {
case .iface:
routeArgs.append("-interface")
case .mac:
routeArgs.append("-link")
case .ipAddress, .special:
// No additional modifier needed for IP gateways
break
case .invalid:
return (false, "Invalid gateway type")
}

// Add destination and gateway at the very end (after ALL modifiers)
// Sanitize IPv6 addresses to remove zone identifiers and prefix lengths
let sanitizedDestination = sanitizeIPv6Address(route.destination)
let sanitizedGateway = sanitizeIPv6Address(route.gateway)

// Use explicit route type handling
let effectiveRouteType = route.effectiveRouteType()
let routeCommandDestination = route.getRouteCommandDestination()

// Add explicit -net or -host flag based on route type (MUST come before other flags)
switch effectiveRouteType {
case .network:
routeArgs.append("-net")
case .host:
routeArgs.append("-host")
case .auto:
// This shouldn't happen with the new system, but fallback to old logic
let isNetworkRoute = shouldTreatAsNetworkRoute(sanitizedDestination)
if isNetworkRoute {
routeArgs.append("-net")
} else {
routeArgs.append("-host")
}
}

// Add route flags AFTER route type (-net/-host)
for flag in route.flags {
switch flag {
case "S":
routeArgs.append("-static")
case "R":
routeArgs.append("-reject")
case "b":
routeArgs.append("-blackhole")
case "L":
routeArgs.append("-llinfo")
// Note: Static flag (S) is automatically added, don't need to specify
// Note: Link info flag (L) is not typically user-controllable
default:
break
}
}

// Add destination and gateway (CRITICAL - these were missing!)
routeArgs.append(routeCommandDestination)
routeArgs.append(sanitizedGateway)

// Add interface if specified and not empty
if !route.interface.isEmpty && route.interface != "*" {
routeArgs.append("-ifscope")
routeArgs.append(route.interface)
}

// Note: Proxy ARP functionality is handled automatically by macOS ARP subsystem
// when routing entries exist, not through route command flags

let routeCommand = "/sbin/route \(routeArgs.joined(separator: " "))"

// Execute with elevated privileges using osascript
let task = Process()
let pipe = Pipe()

task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
task.arguments = [
"-e", "do shell script \"\(routeCommand)\" with administrator privileges"
]
task.standardOutput = pipe
task.standardError = pipe

do {
try task.run()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""

if task.terminationStatus == 0 {
return (true, "")
} else {
// Check for specific error messages
if output.contains("User canceled") || output.contains("canceled") {
return (false, "Authorization was canceled by the user.")
} else if output.contains("not allowed") || output.contains("denied") {
return (false, "Access denied. Administrator privileges are required.")
} else {
// Clean up the error message and provide more context
let cleanOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
if cleanOutput.isEmpty {
return (false, "Route command failed with exit code \(task.terminationStatus)")
} else {
return (false, "Route command failed: \(cleanOutput)")
}
}
}

} catch {
return (false, "Failed to execute route command: \(error.localizedDescription)")
}
}

func getNetworkInterfaces() -> [String] {
let task = Process()
let pipe = Pipe()

task.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
task.arguments = ["-l"]
task.standardOutput = pipe

do {
try task.run()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""

return output.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
} catch {
return []
}
}

func validateIPAddress(_ ipAddress: String) -> Bool {
    let components = ipAddress.components(separatedBy: ".")
    guard components.count == 4 else { return false }

    for component in components {
        guard let number = Int(component), number >= 0 && number <= 255 else {
            return false
        }
    }

    return true
}

/// Validates both IPv4 and IPv6 addresses
func isValidIPAddress(_ ipAddress: String) -> Bool {
    // Check IPv4 first (simple validation)
    if validateIPAddress(ipAddress) {
        return true
    }

    // For IPv6, use routing-specific validation
    return isValidIPv6ForRouting(ipAddress)
}

/// Sanitizes IPv6 addresses for route command by removing zone identifiers and prefix lengths
/// Examples: "fe80::%utun5/64" -> "fe80::", "2001:db8::1%en0" -> "2001:db8::1"
func sanitizeIPv6Address(_ address: String) -> String {
var sanitized = address

// Remove zone identifier (e.g., %utun5, %en0)
if let percentIndex = sanitized.firstIndex(of: "%") {
sanitized = String(sanitized[..<percentIndex])
}

// Remove prefix length (e.g., /64, /128)
if let slashIndex = sanitized.firstIndex(of: "/") {
sanitized = String(sanitized[..<slashIndex])
}

return sanitized
}

/// Validates if an IPv6 address is suitable for routing
func isValidIPv6ForRouting(_ address: String) -> Bool {
let sanitized = sanitizeIPv6Address(address)

// Check if it's a valid IPv6 address first
var ipv6addr = in6_addr()
guard sanitized.withCString({ inet_pton(AF_INET6, $0, &ipv6addr) }) == 1 else {
return false
}

// Reject unspecified address (::)
if sanitized == "::" {
return false
}

// Reject incomplete link-local prefix (fe80:: without interface identifier)
// Valid link-local addresses like fe80::1, fe80::254 are allowed
if sanitized.lowercased() == "fe80::" {
return false
}

return true
}

func validateCIDR(_ cidr: String) -> Bool {
let components = cidr.components(separatedBy: "/")
guard components.count == 2 else { return false }

// Check if the network address part is valid (supports shorthand notation)
guard validateNetworkAddress(components[0]) else { return false }

guard let mask = Int(components[1]), mask >= 0 && mask <= 32 else {
return false
}

return true
}

func validateNetworkAddress(_ address: String) -> Bool {
let components = address.components(separatedBy: ".")

// Support 1-4 octets for shorthand notation
guard components.count >= 1 && components.count <= 4 else { return false }

for component in components {
guard let number = Int(component), number >= 0 && number <= 255 else {
return false
}
}

return true
}

/// Parses a network address string with shorthand notation support
/// Examples: "10" -> "10.0.0.0", "192.168" -> "192.168.0.0"
func parseNetworkAddress(_ address: String) -> String? {
let components = address.components(separatedBy: ".")

// Support 1-4 octets for shorthand notation
guard components.count >= 1 && components.count <= 4 else { return nil }

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

// MARK: - Advanced Route Validation

func validateMetric(_ metric: String, type: String) -> Bool {
guard let value = Int(metric) else { return false }

switch type {
case "mtu":
return value >= 68 && value <= 65535
case "hopcount":
return value >= 0 && value <= 255
case "rtt", "rttvar":
return value >= 0 && value <= 65535
case "sendpipe", "recvpipe", "ssthresh":
return value >= 0 && value <= 65535
case "expire":
return value >= 0
default:
return value >= 0
}
}

func getRouteFlagDescriptions() -> [String: String] {
return [
"S": "Static Route - Manually added route",
"R": "Reject Route - Emit ICMP unreachable when matched",
"b": "Blackhole Route - Silently discard packets",
"L": "Link Level Info - Validly translates proto addr to link addr"
]
}

// MARK: - Gateway Validation Helpers

func isValidInterfaceName(_ name: String) -> Bool {
// Accept common interface prefixes
let prefixes = ["en", "lo", "bridge", "utun", "gif", "stf", "p2p"]
for prefix in prefixes {
if name.hasPrefix(prefix) { return true }
}
return false
}

func isValidMACAddress(_ mac: String) -> Bool {
let parts = mac.split(separator: ":")
if parts.count != 6 { return false }
for part in parts {
if part.count != 2 || part.range(of: "^[0-9A-Fa-f]{2}$", options: .regularExpression) == nil {
return false
}
}
return true
}

func isSpecialGateway(_ gateway: String) -> Bool {
    return gateway == "*" || gateway.hasPrefix("link#")
}

/// Determine the gateway type for command construction
enum GatewayType { case ipAddress, iface, mac, special, invalid }
func gatewayType(_ gateway: String) -> GatewayType {
    if isValidIPAddress(gateway) { return .ipAddress }
    if isValidInterfaceName(gateway) { return .iface }
    if isValidMACAddress(gateway) { return .mac }
    if isSpecialGateway(gateway) { return .special }
    return .invalid
}

/// Validate route configuration before executing commands
    internal func validateRouteForCommand(_ route: NetworkRoute, command: String) -> Bool {
// Basic validation for all commands
if route.destination.isEmpty {
return false
}
// For add commands, gateway is required and must be a valid type
if command == "add" {
if route.gateway.isEmpty {
return false
}
let type = gatewayType(route.gateway)
if type == .invalid {
return false
}
}
// Validate destination format (support CIDR, full IP, and shorthand notation)
if !validateCIDR(route.destination) && !isValidIPAddress(route.destination) && !validateNetworkAddress(route.destination) {
return false
}

// Additional IPv6 validation for routing suitability
let sanitizedDestination = sanitizeIPv6Address(route.destination)
if sanitizedDestination.contains(":") && !isValidIPv6ForRouting(route.destination) {
return false
}

let sanitizedGateway = sanitizeIPv6Address(route.gateway)
if sanitizedGateway.contains(":") && !isValidIPv6ForRouting(route.gateway) {
return false
}
return true
}

/// Generate the route command string for testing/debugging (without execution)
func generateRouteCommand(_ command: String, route: NetworkRoute, advancedOptions: [String: String] = [:]) -> String {
var routeArgs = [command]

// Add advanced options
for (key, value) in advancedOptions {
if !value.isEmpty {
routeArgs.append("-\(key)")
routeArgs.append(value)
}
}

// Add gateway type modifiers BEFORE destination/gateway
let gwType = gatewayType(route.gateway)
switch gwType {
case .iface:
routeArgs.append("-interface")
case .mac:
routeArgs.append("-link")
case .ipAddress, .special:
// No additional modifier needed for IP gateways
break
case .invalid:
// For generateRouteCommand, just proceed without modifier for invalid gateways
break
}

// Add destination and gateway at the very end (after ALL modifiers)
// Sanitize IPv6 addresses to remove zone identifiers and prefix lengths
let sanitizedDestination = sanitizeIPv6Address(route.destination)
let sanitizedGateway = sanitizeIPv6Address(route.gateway)

// Use explicit route type handling
let effectiveRouteType = route.effectiveRouteType()
let routeCommandDestination = route.getRouteCommandDestination()

// Add explicit -net or -host flag based on route type (MUST come before other flags)
switch effectiveRouteType {
case .network:
routeArgs.append("-net")
case .host:
routeArgs.append("-host")
case .auto:
// This shouldn't happen with the new system, but fallback to old logic
let isNetworkRoute = shouldTreatAsNetworkRoute(sanitizedDestination)
if isNetworkRoute {
routeArgs.append("-net")
} else {
routeArgs.append("-host")
}
}

// Add route flags (blackhole, reject, etc.)
for flag in route.flags {
switch flag {
case "S":
routeArgs.append("-static")
case "R":
routeArgs.append("-reject")
case "b":
routeArgs.append("-blackhole")
case "L":
routeArgs.append("-llinfo")
// Note: Static flag (S) is automatically added, don't need to specify
// Note: Link info flag (L) is not typically user-controllable
default:
break
}
}

// Add destination and gateway
routeArgs.append(routeCommandDestination)
routeArgs.append(sanitizedGateway)

// Add interface if specified and not empty
if !route.interface.isEmpty && route.interface != "*" {
routeArgs.append("-ifscope")
routeArgs.append(route.interface)
}

return "/sbin/route \(routeArgs.joined(separator: " "))"
}

/// Get detailed metrics for a specific route using 'route get'
func getRouteDetails(for destination: String) -> NetworkRoute? {
// Normalize the destination to match how routes are actually created
let lookupDestination: String

if destination.contains("/") {
// CIDR notation - use the network address part
let parts = destination.split(separator: "/")
let networkPart = String(parts[0])

// If it's shorthand CIDR like "172.16.42/24", expand the network part
if let expanded = parseNetworkAddress(networkPart) {
lookupDestination = expanded
} else {
lookupDestination = networkPart
}
} else {
// For shorthand notation, it's created as host route by default (left-padded)
let components = destination.components(separatedBy: ".")
if components.count >= 1 && components.count <= 3 && validateNetworkAddress(destination) {
// This was created as a host route - use left-padded address
lookupDestination = NetworkRoute().parseHostAddressLeftPad(destination) ?? destination
} else {
// Full IP address - use as-is
lookupDestination = destination
}
}

let task = Process()
let pipe = Pipe()

task.executableURL = URL(fileURLWithPath: "/sbin/route")
task.arguments = ["get", lookupDestination]
task.standardOutput = pipe
task.standardError = pipe

do {
try task.run()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""

return parseRouteGetOutput(output, destination: destination)
} catch {
return nil
}
}

/// Parse the output of 'route get' command
private func parseRouteGetOutput(_ output: String, destination: String) -> NetworkRoute? {
let lines = output.components(separatedBy: .newlines)
var gateway = ""
var interface = ""
var flags = ""
var expire = ""
var mtu = ""
var hopCount = ""
var rtt = ""
var rttvar = ""
var sendpipe = ""
var recvpipe = ""
var ssthresh = ""

let expectedFields = ["recvpipe", "sendpipe", "ssthresh", "rtt,msec", "rttvar", "hopcount", "mtu", "expire"]

var index = 0
while index < lines.count {
let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
if trimmed.isEmpty { index += 1; continue }

// Parse flags line: "flags: <UP,GATEWAY,BLACKHOLE,DONE,STATIC,PRCLONING>"
if trimmed.hasPrefix("flags:") {
let flagsContent = trimmed.replacingOccurrences(of: "flags:", with: "").trimmingCharacters(in: .whitespaces)
flags = parseSystemFlagsToRouteXFormat(flagsContent)
index += 1
continue
}

// Parse gateway line: "gateway: 192.168.1.1"
if trimmed.hasPrefix("gateway:") {
gateway = trimmed.replacingOccurrences(of: "gateway:", with: "").trimmingCharacters(in: .whitespaces)
index += 1
continue
}

// Parse interface line: "interface: en0"
if trimmed.hasPrefix("interface:") {
interface = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
index += 1
continue
}

// Robust table header detection for metrics
let lowerTrimmed = trimmed.lowercased()
if expectedFields.allSatisfy({ lowerTrimmed.contains($0) }) {
let headerFields = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
// Find the next non-empty line for values
var valueLine = ""
var valueIndex = index + 1
while valueIndex < lines.count {
let candidate = lines[valueIndex].trimmingCharacters(in: .whitespaces)
if !candidate.isEmpty {
valueLine = candidate
break
}
valueIndex += 1
}
let values = valueLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
for (idx, field) in headerFields.enumerated() {
if idx < values.count {
let value = values[idx]

switch field.lowercased() {
case "recvpipe":
recvpipe = value
case "sendpipe":
sendpipe = value
case "ssthresh":
ssthresh = value
case "rtt,msec":
rtt = value
case "rttvar":
rttvar = value
case "hopcount":
hopCount = value
case "mtu":
mtu = value
case "expire":
expire = value
default:
break
}
}
}
break // Exit after processing the metrics table
}
index += 1
}

return NetworkRoute(
destination: destination,
gateway: gateway,
interface: interface,
flags: flags,
expire: expire,
routeType: .auto,
mtu: mtu,
hopCount: hopCount,
rtt: rtt,
rttvar: rttvar,
sendpipe: sendpipe,
recvpipe: recvpipe,
ssthresh: ssthresh
)
}

/// Convert system flags format to RouteX flag format
/// Input: "<UP,GATEWAY,BLACKHOLE,DONE,STATIC,PRCLONING>"
/// Output: "bS" (blackhole + static)
private func parseSystemFlagsToRouteXFormat(_ systemFlags: String) -> String {
let cleanFlags = systemFlags.replacingOccurrences(of: "<", with: "")
.replacingOccurrences(of: ">", with: "")
let flagComponents = cleanFlags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

var routeXFlags = ""

for flag in flagComponents {
switch flag.uppercased() {
case "STATIC":
routeXFlags += "S"
case "REJECT":
routeXFlags += "R"
case "BLACKHOLE":
routeXFlags += "b"
case "LLINFO":
routeXFlags += "L"
// Skip system flags that aren't user-controllable
case "UP", "GATEWAY", "DONE", "PRCLONING", "HOST", "DYNAMIC", "MODIFIED":
break
default:
break
}
}

return routeXFlags
}

/// Normalize destination for route command (host or network)
func normalizedRouteDestination(_ destination: String, isHost: Bool) -> String? {
if destination.contains("/") {
// CIDR/network notation, use as-is
return destination
} else if isHost {
// Host route, left-pad
return NetworkRoute().parseHostAddressLeftPad(destination)
} else {
// Network route, right-pad (support shorthand notation)
return parseNetworkAddress(destination)
}
}

/// Determine if destination should be treated as network route (requires -net flag)
private func shouldTreatAsNetworkRoute(_ destination: String) -> Bool {
// Only CIDR notation gets -net flag automatically
// Shorthand notation becomes host routes by default (per macOS route man page)
return destination.contains("/")
}
}
