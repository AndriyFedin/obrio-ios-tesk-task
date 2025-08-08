//
//  UIView+Layout.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 08.08.2025.
//

import UIKit

extension UIView {
    
    /// Returns a collection of constraints to anchor the bounds of the current view to the given view.
    ///
    /// - Parameter view: The view to anchor to.
    /// - Parameter insets: The insets around the view.
    /// - Returns: The layout constraints needed for this constraint.
    func constraintsForAnchoringTo(boundsOf view: UIView, withInsets insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        return [
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: isLTR ? insets.left : insets.right),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: isLTR ? -insets.right : -insets.left)
        ]
    }
    
    /// Returns a collection of constraints to anchor the bounds of the current view to the given view.
    ///
    /// - Parameter view: The view to anchor to.
    /// - Parameter inset: The amount of inset around the view from all 4 sides.
    /// - Returns: The layout constraints needed for this constraint.
    func constraintsForAnchoringTo(boundsOf view: UIView, withInsets inset: CGFloat = 0) -> [NSLayoutConstraint] {
        constraintsForAnchoringTo(
            boundsOf: view,
            withInsets: .init(top: inset, left: inset, bottom: inset, right: inset)
        )
    }
    
    private var isLTR: Bool {
        UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }
}
