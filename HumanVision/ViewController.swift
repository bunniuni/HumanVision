//
//  ViewController.swift
//  HumanVision
//
//  Created by Emery Hollingsworth on 9/14/23.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    weak var delegate: ViewControllerDelegate?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var detectionRequest: VNCoreMLRequest?
    var detectionModel: VNCoreMLModel?
    
    // Properties to track previous bounding box and check if human is centered and not moving
    var previousBoundingBox: CGRect?
    var detectionsCounter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermissionsAndSetup()
        setupModel()
    }
    
    func checkCameraPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            initiateCameraSetup()
            
        case .notDetermined: // The user has not yet been asked to grant camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.initiateCameraSetup()
                    }
                }
            }
            
        default:
            // Handles cases: .denied, .restricted, and @unknown default
            return
        }
    }
    
    func initiateCameraSetup() {

        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
    
    func setupModel() {
        do {
            detectionModel = try VNCoreMLModel(for: YOLOv3TinyFP16().model)
            
            if let model = detectionModel {
                detectionRequest = VNCoreMLRequest(model: model, completionHandler: handleDetection)
            }
        } catch {
            print("Model loading error :( - \(error)")
        }
    }
    
    func handleDetection(request: VNRequest, error: Error?) {
        guard let results = request.results else { return }

        DispatchQueue.main.async {
            self.view.layer.sublayers?.removeSubrange(1...)
            
            for observation in results where observation is VNRecognizedObjectObservation {
                guard let recognizedObjectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                }

                if recognizedObjectObservation.labels.contains(where: { $0.identifier == "person" && $0.confidence > 0.8 }) {
                    let boundingBox = recognizedObjectObservation.boundingBox
                    var color = UIColor.red

                    // Check if human is centered and not moving
                    if self.isCentered(boundingBox: boundingBox) {
                        if self.previousBoundingBox == boundingBox {
                            self.detectionsCounter += 1
                        } else {
                            self.detectionsCounter = 0
                        }

                        if self.detectionsCounter > 5 {  // Assuming 5 consecutive detections indicate a stop
                            color = .green
                        }
                    }

                    self.drawBorder(for: boundingBox, color: color)
                    self.previousBoundingBox = boundingBox
                }
            }
        }
    }
    
    func isCentered(boundingBox: CGRect) -> Bool {
        let centerX = boundingBox.origin.x + (boundingBox.width / 2)
        let centerY = boundingBox.origin.y + (boundingBox.height / 2)
        return (centerX > 0.4 && centerX < 0.6) && (centerY > 0.4 && centerY < 0.6)  // Assuming centered within 20% margin
    }
    
    func drawBorder(for boundingBox: CGRect, color: UIColor) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: boundingBox.origin.x * view.bounds.width,
                                  y: (1 - boundingBox.origin.y - boundingBox.height) * view.bounds.height,
                                  width: boundingBox.width * view.bounds.width,
                                  height: boundingBox.height * view.bounds.height)
        shapeLayer.borderWidth = 4
        shapeLayer.borderColor = color.cgColor
        view.layer.addSublayer(shapeLayer)
    }

}

protocol ViewControllerDelegate: AnyObject {
    // viewcontroller functions to call on coordinator
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            if let request = detectionRequest {
                try imageRequestHandler.perform([request])
            }
        } catch {
            print(error)
        }
    }
}
