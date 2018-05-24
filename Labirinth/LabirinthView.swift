//
//  LabirinthView.swift
//  Labirinth
//
//  Created by Ivan Hahanov on 5/22/18.
//  Copyright © 2018 zfort. All rights reserved.
//

import UIKit
import CoreMotion

class LabirinthView: UIView {

    var dimension = 5 {
        didSet {
            labirinth = Labirinth(dimension: dimension)
            setupBehaviours()
            reloadThumbView()
            setNeedsDisplay()
        }
    }
    
    var labirinth: Labirinth!
    
    private var animator: UIDynamicAnimator!
    private var thumb: ThumbView!
    private var holes = [UIBezierPath]()
    private var collision: UICollisionBehavior!
    private var gravity: UIGravityBehavior!
    
    private let borderWidth: CGFloat = 5
    private let borderColor = UIColor.black
    private var cellWidth: CGFloat {
        return (bounds.width - CGFloat((dimension + 1)) * borderWidth) / CGFloat(dimension)
    }
    private let manager = CMMotionManager()
    
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
        holes = []

        UIColor.black.setFill()
        UIColor.black.setStroke()
        for row in 0..<labirinth.dimension {
            for col in 0..<labirinth.dimension {
                let connection = labirinth.connections[row][col]
                print("row \(connection.row) col \(connection.column) l \(connection.left) r \(connection.right) t \(connection.top) b \(connection.bottom)")
                if connection.left == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col)
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth - borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: borderWidth, height: cellWidth + borderWidth * 2))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.right == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + cellWidth + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth - borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: borderWidth, height: cellWidth + borderWidth * 2))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.top == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth - borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row)
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth + borderWidth * 2, height: borderWidth))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.bottom == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth - borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + cellWidth + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth + borderWidth * 2, height: borderWidth))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.hole {
                    let holeRadius = (cellWidth * 0.4) / 2
                    let shift = UInt32((cellWidth - holeRadius * 2)*5) * 2

                    var deviationX = CGFloat(arc4random_uniform(shift)) - CGFloat(shift / 2)
                    var deviationY = CGFloat(arc4random_uniform(shift)) - CGFloat(shift / 2)
                    
                    deviationX /= 10
                    deviationY /= 10
                    
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth + cellWidth / 2 + deviationX
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth + cellWidth / 2 + deviationY
                    let hole = UIBezierPath(arcCenter: CGPoint(x: dx, y: dy), radius: holeRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
                    holes.append(hole)
                    hole.stroke()
                    hole.fill()
                }
            }
        }
    }
    
    private func reloadThumbView() {
        if let thumb = thumb {
            gravity.removeItem(thumb)
            collision.removeItem(thumb)
        }
        thumb?.removeFromSuperview()
        let width = cellWidth * 0.5
        let initFrame = CGRect(x: cellWidth / 2 + borderWidth - width / 2, y: cellWidth / 2 + borderWidth - width / 2, width: width, height: width)
        thumb = ThumbView(frame: initFrame)
        thumb.didMoveTo = { [unowned self] loc in
            for h in self.holes {
                if h.contains(loc) {
                    self.setupBehaviours()
                    self.reloadThumbView()
                    self.setNeedsDisplay()
                    break
                }
            }
        }
        thumb.backgroundColor = .red
        thumb.layer.cornerRadius = thumb.bounds.height / 2
        addSubview(thumb)
        
        gravity.addItem(thumb)
        collision.addItem(thumb)
    }
    
    private func setupBehaviours() {
        collision = UICollisionBehavior(items: [])
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)
        
        gravity = UIGravityBehavior(items: [])
        animator.addBehavior(gravity)
    }

    private func initialize() {

        animator = UIDynamicAnimator(referenceView: self)
        if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 0.01
            manager.startAccelerometerUpdates(to: .main) {
                [weak self] (data: CMAccelerometerData?, error: Error?) in
                if let acceleration = data?.acceleration, let gravity = self?.gravity {
                    let rotation = atan2(-acceleration.y, acceleration.x)
                    let magnitude = sqrt(pow(acceleration.y, 2) + pow(acceleration.x, 2))
                    gravity.angle = CGFloat(rotation)
                    gravity.magnitude = CGFloat(magnitude)
                }
            }
        }
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.01
            manager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data: CMDeviceMotion?, error: Error?) in
                if let gravity = data?.gravity, let gravityBehaviour = self?.gravity {
                    let rotation = atan2(-gravity.y, gravity.x)
                    let magnitude = sqrt(pow(gravity.y, 2) + pow(gravity.x, 2))
                    gravityBehaviour.angle = CGFloat(rotation)
                    gravityBehaviour.magnitude = CGFloat(magnitude)
                }
            }
        }
        dimension = 10
    }
    
}

class ThumbView: UIView {
    
    var didMoveTo: ((CGPoint) -> ())?
    
    override var center: CGPoint {
        didSet {
            didMoveTo?(center)
        }
    }
}
