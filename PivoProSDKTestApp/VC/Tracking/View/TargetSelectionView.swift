//
//  TargetSelectionView.swift
//  PivoProSDKTestApp
//
//  Created by Tuan on 2020/04/16.
//  Copyright © 2020 3i. All rights reserved.
//

import Foundation
import UIKit

class TargetSelectionView: UIView {
  
  let dashedPhase = CGFloat(0.0)
  let dashedLinesLengths: [CGFloat] = [4.0, 2.0]
  
  // Rubber-banding setup
  var rubberbandingStart = CGPoint.zero
  var rubberbandingVector = CGPoint.zero
  var rubberbandingRect: CGRect {
    let pt1 = self.rubberbandingStart
    let pt2 = CGPoint(x: self.rubberbandingStart.x + self.rubberbandingVector.x, y: self.rubberbandingStart.y + self.rubberbandingVector.y)
    let rect = CGRect(x: min(pt1.x, pt2.x), y: min(pt1.y, pt2.y), width: abs(pt1.x - pt2.x), height: abs(pt1.y - pt2.y))
    
    return rect
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    self.setNeedsDisplay()
  }
  
  override func draw(_ rect: CGRect) {
    backgroundColor = UIColor.clear
    let ctx = UIGraphicsGetCurrentContext()!
    
    ctx.saveGState()
    
    ctx.clear(rect)
    ctx.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    ctx.setLineWidth(2.0)
    
    // Draw rubberbanding rectangle, if available
    if self.rubberbandingRect != CGRect.zero {
      ctx.setStrokeColor(UIColor.blue.cgColor)
      
      // Switch to dashed lines for rubberbanding selection
      ctx.setLineDash(phase: dashedPhase, lengths: dashedLinesLengths)
      ctx.stroke(self.rubberbandingRect)
    }
    
    ctx.restoreGState()
  }
}
