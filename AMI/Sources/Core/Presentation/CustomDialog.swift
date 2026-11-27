//
//  CustomDialog.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 26/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

extension View {
    /// Presents a lightweight, in-place dialog on top of the modified view.
    ///
    /// Unlike `sheet` or `fullScreenCover`, the dialog is rendered as an
    /// `overlay`, so it is confined to the bounds of the view it is applied
    /// to — apply it high in the view hierarchy (e.g. a root screen) to get
    /// a full-screen dimmed backdrop.
    ///
    /// The dialog:
    /// - dims the area behind it with `background`; tapping the dimmed area
    ///   dismisses it;
    /// - displays `content` in a rounded card using the semantic
    ///   `.background` style, so it adapts to light/dark mode;
    /// - fades in/out (0.2 s ease-in-out) when `isPresented` changes.
    ///
    /// Because the overlay only exists while `isPresented` is `true`, any
    /// `@State` held inside `content` is discarded when the dialog is
    /// dismissed.
    ///
    /// - Parameters:
    ///   - background: Color used to dim the view behind the dialog.
    ///   - padding: Padding applied inside the card, around `content`.
    ///   - margin: Padding applied outside the card, between the card and the
    ///     edges of the modified view.
    ///   - cornerRadius: Corner radius of the dialog card; also drives the
    ///     shadow radius.
    ///   - isPresented: Binding controlling dialog visibility. Set it to
    ///     `false` — from `content` (e.g. a button) or by tapping the dimmed
    ///     area — to dismiss.
    ///   - content: The dialog's content.
    /// - Returns: The modified view with the dialog overlay attached.
    func customDialog(background: Color = Color.black.opacity(0.4),
                      padding: EdgeInsets = EdgeInsets(top: 24.0, leading: 24.0, bottom: 24.0, trailing: 24.0),
                      margin: EdgeInsets = EdgeInsets(top: 32.0, leading: 32.0, bottom: 32.0, trailing: 32.0),
                      cornerRadius: CGFloat = 28.0,
                      isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> some View) -> some View {
        overlay {
            if isPresented.wrappedValue {
                ZStack {
                    // Dimmed backdrop covering the modified view; tapping it dismisses the dialog.
                    background
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented.wrappedValue = false
                        }
                    // Dialog card: content + inner padding + semantic background
                    // (adapts to light/dark mode) + shadow + outer margin.
                    content()
                        .padding(padding)
                        .background(.background, in: RoundedRectangle(cornerRadius: cornerRadius))
                        .shadow(radius: cornerRadius)
                        .padding(margin)
                }
                // Fades the whole dialog in/out; paired with the animation below.
                .transition(.opacity)
            }
        }
        // Drives the fade whenever the binding flips.
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}
