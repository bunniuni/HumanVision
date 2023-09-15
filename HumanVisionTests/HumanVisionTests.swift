//
//  HumanVisionTests.swift
//  HumanVisionTests
//
//  Created by Tony Loehr on 9/14/23.
//

import XCTest
@testable import HumanVision

final class ViewControllerTests: XCTestCase {
    
    var viewController: ViewController!
    
    override func setUp() {
        super.setUp()
        viewController = ViewController()
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    func testBoundingBoxIsCloseTo() {
        // Given
        let box1 = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        let box2 = CGRect(x: 0.15, y: 0.15, width: 0.55, height: 0.55)  // within the 0.1 tolerance
        
        // When
        let isClose = viewController.isBoundingBox(box1, closeTo: box2)
        
        // Then
        XCTAssertTrue(isClose, "Expected bounding boxes to be considered close.")
    }
    
    func testBoundingBoxIsNotCloseTo() {
        // Given
        let box1 = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        let box2 = CGRect(x: 0.3, y: 0.3, width: 0.8, height: 0.8)  // outside the 0.1 tolerance
        
        // When
        let isClose = viewController.isBoundingBox(box1, closeTo: box2)
        
        // Then
        XCTAssertFalse(isClose, "Expected bounding boxes to not be considered close.")
    }
    
    func testBoundingBoxIsCentered() {
        // Given
        let centeredBox = CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1)
        
        // When
        let isCentered = viewController.isCentered(boundingBox: centeredBox)
        
        // Then
        XCTAssertTrue(isCentered, "Expected bounding box to be considered centered.")
    }
    
    func testBoundingBoxIsNotCentered() {
        // Given
        let nonCenteredBox = CGRect(x: 0.8, y: 0.8, width: 0.1, height: 0.1)
        
        // When
        let isCentered = viewController.isCentered(boundingBox: nonCenteredBox)
        
        // Then
        XCTAssertFalse(isCentered, "Expected bounding box to not be considered centered.")
    }
}
