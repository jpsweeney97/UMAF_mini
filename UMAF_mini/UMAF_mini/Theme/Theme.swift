//
//  Theme.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI

// Global design tokens for UMAF Mini
enum UMAFTheme {
    // Accent color (you can later move this to Assets.xcassets)
    static let accent = Color(nsColor: .systemTeal)

    // Background gradient for the whole window
    static let windowGradient = LinearGradient(
        colors: [
            Color(nsColor: .windowBackgroundColor),
            Color(nsColor: .controlBackgroundColor)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Panel-style background (for editor/inspector cards)
    static let panelBackground = Color.black.opacity(0.06)

    // Border color for panels
    static let panelBorder = Color.white.opacity(0.12)
}

// Generic glassy card you can reuse around content
struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(.ultraThinMaterial)
            .background(UMAFTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(UMAFTheme.panelBorder, lineWidth: 1)
            )
    }
}
