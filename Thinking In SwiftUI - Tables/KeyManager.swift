//
//  KeyManager.swift
//  Thinking In SwiftUI - Tables
//
//  Created by Administrateur on 01/05/2020.
//  Copyright © 2020 Lamarckise. All rights reserved.
//

import SwiftUI

class KeyAwareController<Content>: UIHostingController<Content> where Content: View {
    override func becomeFirstResponder() -> Bool { true }
    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(keyPressed)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(keyPressed)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(keyPressed)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(keyPressed))
        ]
    }
    
    var keyManager: KeyManager
    
    init(rootView: Content, keyManager: KeyManager) {
        self.keyManager = keyManager
        super.init(rootView: rootView)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        self.keyManager = KeyManager()
        super.init(coder: aDecoder)
    }
    
    @objc func keyPressed(_ sender: UIKeyCommand) {
        keyManager.keyHasBeenPressed(sender)
    }
}

enum KeyPressed {
    case up, down, left, right, none
}

class KeyManager: ObservableObject {
    @Published var keyPressed: KeyPressed = .none
    
    @objc public func keyHasBeenPressed(_ sender: UIKeyCommand) {
        switch sender.input {
        case UIKeyCommand.inputUpArrow:
            keyPressed = .up
        case UIKeyCommand.inputDownArrow:
            keyPressed = .down
        case UIKeyCommand.inputLeftArrow:
            keyPressed = .left
        case UIKeyCommand.inputRightArrow:
            keyPressed = .right
        default:
            break
        }
    }
}
