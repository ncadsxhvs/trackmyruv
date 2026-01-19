//
//  View+Extensions.swift
//  RVU Tracker
//
//  SwiftUI View extension methods for common UI patterns
//

import SwiftUI

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    /// Apply standard padding
    func standardPadding() -> some View {
        self.padding(Constants.UI.padding)
    }

    /// Hide keyboard on tap
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                           to: nil,
                                           from: nil,
                                           for: nil)
        }
    }

    /// Conditional view modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply conditional modifier
    @ViewBuilder
    func ifLet<Value, Transform: View>(_ value: Value?, transform: (Self, Value) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
