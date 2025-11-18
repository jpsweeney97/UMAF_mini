
import SwiftUI

public struct Toast: View {
    public enum Kind { case info, success, warning, error }
    let kind: Kind
    let message: String

    public init(_ message: String, kind: Kind = .info) {
        self.message = message
        self.kind = kind
    }

    public var body: some View {
        Text(message)
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(radius: 2)
            .accessibilityLabel(message)
    }
}

public struct ToastHost<Content: View>: View {
    @Binding var toast: Toast?
    var content: () -> Content

    public init(toast: Binding<Toast?>, @ViewBuilder content: @escaping () -> Content) {
        self._toast = toast
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            content()
            if let t = toast {
                t
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toast?.message)
    }
}
