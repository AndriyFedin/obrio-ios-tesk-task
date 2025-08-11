//
//  HomeEmptyView.swift
//  TransactionsTestTask
//
//  Created by Andriy Fedin on 11.08.2025.
//

import UIKit
import Combine

final class HomeEmptyView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        setupLayout()
    }
    
    func setTitle(_ title: String) {
        label.text = title
    }
    
    func setActionTitle(_ title: String) {
        button.setTitle(title, for: .normal)
    }
    
    var actionHandler: AnyPublisher<Void, Never> { actionHandlerSubject.eraseToAnyPublisher() }
    
    // MARK: - Private
    
    private let label: UILabel = .init()
    private let button: UIButton = .init(type: .system)
    
    private let actionHandlerSubject: PassthroughSubject<Void, Never> = .init()
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration = .gray()
        button.addAction(UIAction { [weak self] _ in
            self?.actionHandlerSubject.send()
        }, for: .touchUpInside)
    }
    
    private func setupLayout() {
        let vStack = UIStackView(arrangedSubviews: [label, button])
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.distribution = .fill
        vStack.spacing = 16.0
        vStack.alignment = .center
        
        addSubview(vStack)
        
        NSLayoutConstraint.activate(vStack.constraintsForAnchoringTo(boundsOf: self, withInset: 0))
    }
}
