//
//  ContentView.swift
//  Thinking In SwiftUI - Tables
//
//  Created by Administrateur on 01/05/2020.
//  Copyright © 2020 Lamarckise. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var cells = [
        [Text(""), Text("Monday").bold(), Text("Tuesday").bold(), Text("Wednesday").bold()],
        [Text("Berlin").bold(), Text("Cloudy"), Text("Mostly\nSunny"), Text("Sunny")],
        [Text("London").bold(), Text("Heavy Rain"), Text("Cloudy"), Text("Sunny")],
    ]
    
    var body: some View {
        Table(cells: cells)
            .font(Font.system(.body, design: .serif))
    }
}

struct MaxSizesPreference: PreferenceKey {
    static let defaultValue: CellSizes = CellSizes()
    static func reduce(value: inout CellSizes, nextValue: () -> CellSizes) {
        value.width.merge(nextValue().width, uniquingKeysWith: max)
        value.height.merge(nextValue().height, uniquingKeysWith: max)
    }
}

extension View {
    func getCellSizes(size: CGSize, path: CellPath) -> CellSizes {
        return CellSizes(width: [path.column: size.width], height: [path.row: size.height])
    }
    func storeMaxSizes(at path: CellPath) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: MaxSizesPreference.self,
                                       value: self.getCellSizes(size: proxy.size, path: path))
            }
        )
    }
}

extension Int {
    var isEven: Bool { self % 2 == 0 }
}

typealias CellPath = (row: Int, column: Int)
struct CellSizes {
    var width: [Int: CGFloat] = [:]
    var height: [Int: CGFloat] = [:]
    func findWidth(for path: CellPath) -> CGFloat? {
        return width[path.column]
    }
    func findHeight(for path: CellPath) -> CGFloat? {
        return height[path.row]
    }
}
extension CellSizes: Equatable {}

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

struct Table<Cell: View>: View {
    var cells: [[Cell]]
    
    @State private var selected: CellPath?
    @State private var maxSizes: CellSizes = CellSizes()
    @EnvironmentObject var keyManager: KeyManager
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(cells.indices) { rowIdx in
                HStack(alignment: .top) {
                    ForEach(self.cells[rowIdx].indices) { colIdx in
                        self.cellFor(path: (row: rowIdx, column: colIdx))
                    }
                }
                .background(
                    rowIdx.isEven ? Color(.systemBackground) : Color(.secondarySystemBackground)
                )
            }
        }
        .onPreferenceChange(MaxSizesPreference.self) { self.maxSizes = $0 }
        .onReceive(keyManager.$keyPressed, perform: handle)
    }
    
    private func handle(key: KeyPressed) {
        guard cells.count > 0 else { return }
        let maxRow = cells.count-1
        let maxCol = cells[0].count-1

        if selected == nil {
            switch key {
            case .down, .right:
                selected = (row: 0, column: 0)
            case .up:
                selected = (row: maxRow, column: 0)
            case .left:
                selected = (row: 0, column: maxCol)
            case .none: break
            }
        } else {
            switch key {
            case .down:
                guard selected!.row < maxRow else { return }
                selected!.row += 1
            case .up:
                guard selected!.row > 0 else { return }
                selected!.row -= 1
            case .left:
                guard selected!.column > 0 else { return }
                selected!.column -= 1
            case .right:
                guard selected!.column < maxCol else { return }
                selected!.column += 1
            case .none: break
            }
        }
    }
    
    typealias BorderStyle = (color: Color, width: CGFloat)
    
    private func borderStyle(for path: CellPath) -> BorderStyle {
        if selected?.column == path.column && selected?.row == path.row {
            return (color: Color.blue, width: 2)
        } else {
            return (color: Color.clear, width: 0)
        }
    }
    
    private func cellFor(path: CellPath) -> some View {
        let border = borderStyle(for: path)
        return cells[path.row][path.column]
            .storeMaxSizes(at: path)
            .frame(
                width: maxSizes.findWidth(for: path),
                height: maxSizes.findHeight(for: path),
                alignment: .topLeading)
            .padding(5)
            .border(border.color, width: border.width)
            .animation(.easeInOut)
            .onTapGesture {
                self.selected = path
            }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
