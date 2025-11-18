//
//  CodeEditor.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.isEditable = true
        textView.isRichText = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.delegate = context.coordinator

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true

        context.coordinator.textView = textView
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tv = context.coordinator.textView else { return }
        if tv.string != text {
            tv.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditor
        weak var textView: NSTextView?

        init(_ parent: CodeEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
        }
    }
}
