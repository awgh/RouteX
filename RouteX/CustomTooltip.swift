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

struct CustomTooltip: ViewModifier {
    let text: String
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovered = hovering
            }
            .overlay(
                Group {
                    if isHovered {
                        VStack {
                            Text(text)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(6)
                                .offset(y: -40)
                            
                            Spacer()
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isHovered)
                    }
                }
            )
    }
}

extension View {
    func customTooltip(_ text: String) -> some View {
        modifier(CustomTooltip(text: text))
    }
} 