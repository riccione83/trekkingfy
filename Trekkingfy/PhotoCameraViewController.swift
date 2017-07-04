//
//  PhotoCameraViewController.swift
//  Trekkingfy
//
//  Created by Riccardo Rizzo on 26/05/17.
//  Copyright © 2017 Riccardo Rizzo. All rights reserved.
//

import UIKit
import AVFoundation

protocol PhotoShootDelegate {
    
    func setPhoto(image:UIImage, id:Int, note:String)
    
}


class PhotoCameraViewController: UIViewController {
    
    @IBOutlet var previewView: UIView!
    
    @IBOutlet var captureImageView: UIImageView!
    @IBOutlet var btnTakePhoto: UIButton!
    @IBOutlet var btnOK: UIButton!
    @IBOutlet var txtNote: UITextField!
    @IBOutlet var photoBackgroundButton: UIView!
    
    
    var mainViewDelegate: PhotoShootDelegate?
    var currentID:Int?
    
    var boxView:UIView!
    let myButton: UIButton = UIButton()
    
    
    var imageOrientation = UIImageOrientation.right
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnOKClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            self.mainViewDelegate?.setPhoto(image: self.captureImageView.image!, id: self.currentID!, note: self.txtNote.text!)
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: self.imageOrientation)
                    //UIImageOrientation.right
                    
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    self.captureImageView.image = image
                    self.btnOK.isHidden = false
                    self.txtNote.isHidden = false
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Setup your camera here...
        
        if(videoPreviewLayer != nil) {
            videoPreviewLayer!.frame = previewView.bounds
        }
        else
        {
            showMessage(message: "Sorry, Unable to start camera", completitionHandler: { (completed) in
                
                self.dismiss(animated: false, completion: nil)
                
            })
            
        }
    }
    
    private func showMessage(message:String, completitionHandler:@escaping (_ success:Bool) -> ())  {
        let alert = UIAlertController(title: "Trekkingfy", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (UIAlertAction) in
            completitionHandler(true)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        
        layer.videoOrientation = orientation
        
        self.videoPreviewLayer?.frame = self.view.bounds
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.videoPreviewLayer?.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    imageOrientation = UIImageOrientation.right
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    imageOrientation = UIImageOrientation.down
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                imageOrientation = UIImageOrientation.up
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                imageOrientation = UIImageOrientation.down
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                    break
                }
            }
        }
    }
    
    private func startPhotoCamera() {
        
        btnOK.isHidden = true
        txtNote.isHidden = true
        
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
            
        }
        catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            if session!.canAddOutput(stillImageOutput) {
                session!.addOutput(stillImageOutput)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                //videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                previewView.layer.addSublayer(videoPreviewLayer!)
                
                previewView.bringSubview(toFront: photoBackgroundButton)
                previewView.bringSubview(toFront: btnTakePhoto)
                previewView.bringSubview(toFront: txtNote)
                session!.startRunning()
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startPhotoCamera()
    }
    
}
