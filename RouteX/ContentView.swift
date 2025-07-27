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

struct ContentView: View {
    @StateObject private var routeManager = RouteManager()
    @State private var showingAddRoute = false
    @State private var selectedRouteID: NetworkRoute.ID?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var routeToEdit: NetworkRoute?
    
    var filteredRoutes: [NetworkRoute] {
        if searchText.isEmpty {
            return routeManager.routes.sorted { $0.specificity > $1.specificity }
        } else {
            let matchingRoutes = routeManager.routes.filter { route in
                route.matches(searchTerm: searchText)
            }
            
            // If no routes match and we have a search term, include default routes
            var finalRoutes = matchingRoutes
            if matchingRoutes.isEmpty && !searchText.isEmpty {
                let defaultRoutes = routeManager.routes.filter { $0.isDefaultRoute }
                finalRoutes = defaultRoutes
            }
            
            // Sort by specificity (most specific first), then by destination
            return finalRoutes.sorted { route1, route2 in
                if route1.specificity != route2.specificity {
                    return route1.specificity > route2.specificity
                } else {
                    return route1.destination < route2.destination
                }
            }
        }
    }
    
    var selectedRoute: NetworkRoute? {
        guard let selectedID = selectedRouteID else { return nil }
        return filteredRoutes.first(where: { $0.id == selectedID })
    }
    
    var isSelectedRouteEditable: Bool {
        return selectedRoute?.isEditable ?? false
    }
    
    var selectedRouteEditHelpText: String {
        guard let route = selectedRoute else {
            return "Select a route to edit"
        }
        
        if route.isEditable {
            return "Edit the selected route (administrator privileges required)"
        } else {
            return "This route is system-managed and cannot be edited. System routes with flags C/W/I are automatically managed by macOS."
        }
    }
    
    var selectedRouteDeleteHelpText: String {
        guard let route = selectedRoute else {
            return "Select a route to delete"
        }
        
        if route.isEditable {
            return "Delete the selected route (administrator privileges required)"
        } else {
            return "This route is system-managed and cannot be deleted. System routes with flags C/W/I are automatically managed by macOS."
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text("Network Routes")
                        .font(.title)
                        .fontWeight(.bold)
                        .help("RouteX - Professional Network Route Manager")
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            routeManager.refreshRoutes()
                        }) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .disabled(routeManager.isLoading)
                        .help("Refresh the route table to show current network routes")
                        
                        Button(action: {
                            showingAddRoute = true
                        }) {
                            Image(systemName: "plus")
                            Text("Add Route")
                        }
                        .help("Add a new static route to the routing table")
                        
                        Button(action: {
                            if let selectedID = selectedRouteID,
                               let route = filteredRoutes.first(where: { $0.id == selectedID }) {
                                routeToEdit = route
                            }
                        }) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .disabled(selectedRouteID == nil || !isSelectedRouteEditable)
                        .help(selectedRouteEditHelpText)
                        
                        Button(action: {
                            if let selectedID = selectedRouteID,
                               let route = filteredRoutes.first(where: { $0.id == selectedID }) {
                                deleteRoute(route)
                            }
                        }) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .disabled(selectedRouteID == nil || !isSelectedRouteEditable)
                        .help(selectedRouteDeleteHelpText)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search routes (IP, CIDR, shorthand like '127', '192.168', gateway, interface)...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .help("TEST TOOLTIP - Search routes by destination, gateway, or interface. Supports shorthand notation (e.g., '192.168' for 192.168.0.0/16) and CIDR notation.")
                        .onSubmit {
                            // Search submitted: \(searchText)
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Routes table
                if routeManager.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading routes...")
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRoutes.isEmpty {
                    VStack {
                        Image(systemName: "network")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No routes found" : "No routes match your search")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        if searchText.isEmpty {
                            Text("Click 'Add Route' to create your first route")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Table(filteredRoutes, selection: $selectedRouteID) {
                        TableColumn("Destination") { route in
                            HStack(spacing: 4) {
                                Text(route.destination)
                                    .foregroundColor(route.isEditable ? .primary : .secondary)
                                
                                // Show phantom route indicator
                                if route.flags.contains("b") || route.flags.contains("R") {
                                    Image(systemName: "eye.slash.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption2)
                                        .help("Phantom route: This route exists but doesn't appear in standard route listings")
                                }
                                
                                // Show non-editable route indicator
                                if !route.isEditable {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .help("System-managed route (not editable)")
                                }
                            }
                        }
                        .width(min: 120, ideal: 180)
                        
                        TableColumn("Gateway") { route in
                            if route.displayGateway.isEmpty {
                                Text("—")
                                    .foregroundColor(.secondary)
                                    .help(route.gatewayTypeDescription)
                            } else {
                                Text(route.displayGateway)
                                    .foregroundColor(route.isEditable ? .primary : .secondary)
                                    .help(route.gatewayTypeDescription)
                            }
                        }
                        .width(min: 120, ideal: 150)
                        
                        TableColumn("Interface") { route in
                            Text(route.interface)
                                .foregroundColor(route.isEditable ? .primary : .secondary)
                        }
                        .width(min: 100, ideal: 120)
                        
                        TableColumn("Flags") { route in
                            Text(route.flags)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(route.isEditable ? .primary : .secondary)
                        }
                        .width(min: 80, ideal: 100)
                        
                        TableColumn("Expire") { route in
                            Text(route.expire)
                                .foregroundColor(route.isEditable ? .primary : .secondary)
                        }
                        .width(min: 80, ideal: 100)
                    }
                    .tableStyle(.bordered)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                }
                
                // Status bar
                HStack {
                    if let error = routeManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            let editableCount = filteredRoutes.filter { $0.isEditable }.count
                            let systemCount = filteredRoutes.count - editableCount
                            
                            HStack(spacing: 6) {
                                Text("\(filteredRoutes.count) route\(filteredRoutes.count == 1 ? "" : "s")")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                if systemCount > 0 {
                                    Text("(\(editableCount) editable,")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(systemCount) system)")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .help("System-managed routes cannot be edited")
                                }
                            }
                            
                            if !searchText.isEmpty {
                                let searchType = getSearchTypeDescription(for: searchText)
                                Text("Search: \(searchType)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let selectedID = selectedRouteID,
                       let selected = filteredRoutes.first(where: { $0.id == selectedID }) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Selected: \(selected.destination)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("Flags: \(selected.flagDescription)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            if !selected.expire.isEmpty {
                                Text("Expire: \(expireDescription(for: selected.expire))")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
        .sheet(isPresented: $showingAddRoute) {
            AddRouteView(routeManager: routeManager)
        }
        .sheet(item: $routeToEdit) { route in
            AddRouteView(routeManager: routeManager, editingRoute: route)
        }
        .alert("Delete Route", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let selectedID = selectedRouteID,
                   let route = filteredRoutes.first(where: { $0.id == selectedID }) {
                    confirmDeleteRoute(route)
                }
            }
        } message: {
            if let selectedID = selectedRouteID,
               let route = filteredRoutes.first(where: { $0.id == selectedID }) {
                Text("Are you sure you want to delete the route to \(route.destination)?")
            }
        }
        .onAppear {
            routeManager.refreshRoutes()
        }
    }
    
    private func deleteRoute(_ route: NetworkRoute) {
        selectedRouteID = route.id
        showingDeleteAlert = true
    }
    
    private func confirmDeleteRoute(_ route: NetworkRoute) {
        routeManager.deleteRoute(route) { success, error in
            if !success {
                routeManager.errorMessage = error ?? "Failed to delete route"
            }
        }
    }
    
    private func expireDescription(for expire: String) -> String {
        if expire.isEmpty {
            return "No expiration - route is permanent"
        } else if expire == "!" {
            return "Route expires immediately - temporary route"
        } else if let seconds = Int(expire) {
            if seconds == 0 {
                return "Route expires immediately - temporary route"
            } else {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                if minutes > 0 {
                    return "Route expires in \(minutes) minute\(minutes == 1 ? "" : "s")\(remainingSeconds > 0 ? " \(remainingSeconds) second\(remainingSeconds == 1 ? "" : "s")" : "")"
                } else {
                    return "Route expires in \(seconds) second\(seconds == 1 ? "" : "s")"
                }
            }
        } else {
            return "Expiration time: \(expire)"
        }
    }
    
    private func getSearchTypeDescription(for searchTerm: String) -> String {
        // Try to normalize the search term to understand its type
        if let normalized = normalizeSearchTerm(searchTerm) {
            switch normalized.prefixLength {
            case 32:
                return "IP address (/32)"
            case 24:
                return "Class C network (/24)"
            case 16:
                return "Class B network (/16)"
            case 8:
                return "Class A network (/8)"
            default:
                return "CIDR /\(normalized.prefixLength) network"
            }
        }
        
        // Check if it's a CIDR notation
        if searchTerm.contains("/") {
            let components = searchTerm.components(separatedBy: "/")
            if components.count == 2, let prefixLength = Int(components[1]) {
                return "CIDR /\(prefixLength) network"
            }
        }
        
        // Check if it's an IP address
        let ipComponents = searchTerm.components(separatedBy: ".")
        if ipComponents.count == 4 {
            var isValidIP = true
            for component in ipComponents {
                if let octet = Int(component), octet >= 0 && octet <= 255 {
                    continue
                } else {
                    isValidIP = false
                    break
                }
            }
            if isValidIP {
                return "IP address"
            }
        }
        
        // Check if it looks like a gateway
        if searchTerm.contains(".") && !searchTerm.contains(" ") {
            return "Gateway or network"
        }
        
        // Default to text search
        return "Text search"
    }
    
    /// Normalizes a search term to CIDR format for type detection
    private func normalizeSearchTerm(_ searchTerm: String) -> CIDRInfo? {
        // If it's already in CIDR format, parse it directly
        if searchTerm.contains("/") {
            let components = searchTerm.components(separatedBy: "/")
            guard components.count == 2,
                  let prefixLength = Int(components[1]),
                  prefixLength >= 0 && prefixLength <= 32,
                  let networkAddress = parseIPAddress(from: components[0]) else {
                return nil
            }
            return CIDRInfo(networkAddress: networkAddress, prefixLength: prefixLength)
        }
        
        // Handle shorthand notation
        let components = searchTerm.components(separatedBy: ".")
        
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
            guard let ipAddress = parseIPAddress(from: searchTerm) else {
                return nil
            }
            prefixLength = 32
            networkAddress = ipAddress
            
        default:
            return nil
        }
        
        return CIDRInfo(networkAddress: networkAddress, prefixLength: prefixLength)
    }
    
    /// Parses an IP address string
    private func parseIPAddress(from string: String) -> String? {
        let components = string.components(separatedBy: ".")
        guard components.count == 4 else { return nil }
        
        for component in components {
            guard let octet = Int(component), octet >= 0 && octet <= 255 else {
                return nil
            }
        }
        
        return string
    }
}

#Preview {
    ContentView()
} 