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
            reloadThumbView()
            setupBoundaries()
            setNeedsDisplay()
        }
    }
    
    var labirinth: Labirinth!
    
    private var animator: UIDynamicAnimator!
    private var thumb: UIView!
    private var collision: UICollisionBehavior!
    private var gravity: UIGravityBehavior!
    
    private let borderWidth: CGFloat = 1
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
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.right == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + cellWidth + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: borderWidth, height: cellWidth))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.top == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row)
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth, height: borderWidth))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
                if connection.bottom == nil {
                    let dx = CGFloat(col) * cellWidth + borderWidth * CGFloat(col) + borderWidth
                    let dy = CGFloat(row) * cellWidth + borderWidth * CGFloat(row) + cellWidth + borderWidth
                    let wall = UIBezierPath(rect: CGRect(x: dx, y: dy, width: cellWidth, height: borderWidth))
                    collision.addBoundary(withIdentifier: wall, for: wall)
                    wall.stroke()
                    wall.fill()
                }
            }
        }
    }
    
    private func reloadThumbView() {
        thumb?.removeFromSuperview()
        let width = cellWidth * 0.6
        thumb = UIView(frame: CGRect(x: cellWidth / 2 + borderWidth - width / 2, y: cellWidth / 2 + borderWidth - width / 2, width: width, height: width))
        thumb.backgroundColor = .red
        thumb.layer.cornerRadius = thumb.bounds.height / 2
        addSubview(thumb)
        
        gravity = UIGravityBehavior(items: [thumb])
        
        animator.addBehavior(gravity)
    }
    
    private func setupBoundaries() {
        collision = UICollisionBehavior(items: [thumb])
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)
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
        dimension = 20
    }
    
}
