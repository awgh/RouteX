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

@main
struct RouteXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About RouteX") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "RouteX",
                            .version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                            .credits: NSAttributedString(
                                string: "Professional Network Route Manager for macOS\n\nDeveloped by awgh@awgh.org\n\nCopyright © 2025 awgh@awgh.org\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/",
                                attributes: [
                                    .font: NSFont.systemFont(ofSize: 11),
                                    .foregroundColor: NSColor.labelColor
                                ]
                            )
                        ]
                    )
                }
            }
            
            CommandGroup(after: .appInfo) {
                Divider()
                
                Button("RouteX on GitHub") {
                    if let url = URL(string: "https://github.com/awgh/RouteX") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Report an Issue") {
                    if let url = URL(string: "https://github.com/awgh/RouteX/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Contact Developer") {
                    if let url = URL(string: "mailto:awgh@awgh.org") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
} 