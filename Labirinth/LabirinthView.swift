//
//  LabirinthView.swift
//  Labirinth
//
//  Created by Ivan Hahanov on 5/22/18.
//  Copyright © 2018 zfort. All rights reserved.
//

import UIKit

enum Direction: Int {
    case left, right, top, bottom
}

class Labirinth {
    
    let dimension: Int
    private(set) var connections: [[Connection]] = []
    
    var cache = [Connection]()
    
    init(dimension: Int = 10) {
        self.dimension = dimension
        connections = generateLabirinth()
    }
    
    private func generateLabirinth() -> [[Connection]] {
        var labirinth = [[Connection]]()
        for i in 0..<dimension {
            var row = [Connection]()
            for j in 0..<dimension {
                row.append(Connection(row: i, column: j))
            }
            labirinth.append(row)
        }
        
        //        labMatrix = labirinth
        //
        //        //Build Path
        //        var currentPosition: Connection = labirinth[0][0]
        //        while true {
        //            currentPosition = nextConnection(for: currentPosition)
        //            if currentPosition.row == dimension - 1 && currentPosition.column == dimension - 1 {
        //                break
        //            }
        //        }
        //
        labirinth = removeClosedSpaces(labirinth: labirinth)
        
        var prevConnection = labirinth[0][0]
        for row in 0..<labirinth.count {
            for col in 0..<labirinth.count  {
                let connection = labirinth[row][col]
                if connection === prevConnection {
                    continue
                }
                if !self.connection(from: prevConnection, to: connection) {
                    if prevConnection.row == connection.row {
                        prevConnection.right = connection
                        connection.left = prevConnection
                    } else {
                        labirinth[prevConnection.row][connection.column].bottom = connection
                        connection.top = labirinth[prevConnection.row][connection.column]
                    }
                }
                cache = []
                prevConnection = connection
            }
        }
        
        return labirinth
    }
    
    private func removeClosedSpaces(labirinth: [[Connection]]) -> [[Connection]] {
        var new = labirinth
        for row in 0..<labirinth.count {
            for col in 0..<labirinth.count {
                let connection = new[row][col]
                if connection.bottom == nil || connection.top == nil || connection.left == nil || connection.right == nil {
                    _ = nextConnection(for: connection, in: labirinth)
                }
            }
        }
        return new
    }
    
    private func nextConnection(for connection: Connection, in lab: [[Connection]]) -> Connection {
        while true {
            let direction = Direction(rawValue: Int(arc4random() % 4))!
            var next: Connection
            switch direction {
            case .left:
                if connection.column - 1 < 0 {
                    continue
                }
                next = lab[connection.row][connection.column - 1]
                if next.top?.right?.bottom === connection || next.bottom?.right?.top === connection {
                    continue
                }
                connection.left = next
                next.right = connection
            case .right:
                if connection.column + 1 >= dimension {
                    continue
                }
                next = lab[connection.row][connection.column + 1]
                if next.top?.left?.bottom === connection || next.bottom?.left?.top === connection {
                    continue
                }
                connection.right = next
                next.left = connection
            case .top:
                if connection.row - 1 < 0 {
                    continue
                }
                next = lab[connection.row - 1][connection.column]
                if next.left?.bottom?.right === connection || next.right?.bottom?.left === connection {
                    continue
                }
                connection.top = next
                next.bottom = connection
            case .bottom:
                if connection.row + 1 >= dimension {
                    continue
                }
                next = lab[connection.row + 1][connection.column]
                if next.left?.top?.right === connection || next.right?.top?.left === connection {
                    continue
                }
                connection.bottom = next
                next.top = connection
            }
            return next
        }
    }
    
    func connection(from: Connection, to: Connection) -> Bool {
        if from.left === to || from.right === to || from.top === to || from.bottom === to {
            return true
        } else {
            cache.append(from)
            let connectedToLeft = cache.contains(where: { $0 === from.left }) || from.left == nil ? false : connection(from: from.left!, to: to)
            let connectedToRight = cache.contains(where: { $0 === from.right }) || from.right == nil ? false : connection(from: from.right!, to: to)
            let connectedToTop = cache.contains(where: { $0 === from.top }) || from.top == nil ? false : connection(from: from.top!, to: to)
            let connectedToBottom = cache.contains(where: { $0 === from.bottom }) || from.bottom == nil ? false : connection(from: from.bottom!, to: to)
            return connectedToLeft || connectedToRight || connectedToTop || connectedToBottom
        }
    }
}

class Connection {
    
    let row: Int
    let column: Int
    
    var left: Connection?
    var right: Connection?
    var top: Connection?
    var bottom: Connection?
    
    weak var prevConnection: Connection?
    
    init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
    
}

class LabirinthView: UIView {

    var dimension = 5 {
        didSet {
            labirinth = Labirinth(dimension: dimension)
        }
    }
    
    var labirinth: Labirinth!
    
    private var animator: UIDynamicAnimator!
    private var thumb: UIView!
    private var collision: UICollisionBehavior!
    
    private let borderWidth: CGFloat = 1
    private let borderColor = UIColor.black
    
    // MARK: - Private methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let cellWidth = (bounds.width - CGFloat((dimension + 1)) * borderWidth) / CGFloat(dimension)
        UIColor.black.setFill()
        UIColor.black.setStroke()
        for row in 0..<labirinth.dimension {
            for col in 0..<labirinth.dimension {
                let connection = labirinth.connections[row][col]
                print("row \(connection.row) col \(connection.column) l \(connection.left) r \(connection.right) t \(connection.top) b \(connection.bottom)")
                if connection.left == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col)
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: borderWidth, height: cellWidth))
                    wall.stroke()
                    wall.fill()
                }
                if connection.right == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + cellWidth + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: borderWidth, height: cellWidth))
                    wall.stroke()
                    wall.fill()
                }
                if connection.top == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row)
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth, height: borderWidth))
                    wall.stroke()
                    wall.fill()
                }
                if connection.bottom == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + cellWidth + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth, height: borderWidth))
                    wall.stroke()
                    wall.fill()
                }
            }
        }
    }

    private func initialize() {
        thumb = UIView(frame: CGRect(x: 5, y: 5, width: 10, height: 10))
        thumb.backgroundColor = .red
        thumb.layer.cornerRadius = thumb.bounds.height / 2
        addSubview(thumb)

        animator = UIDynamicAnimator(referenceView: self)
        collision = UICollisionBehavior(items: [thumb])
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)
        
        dimension = 20
    }
    
}
