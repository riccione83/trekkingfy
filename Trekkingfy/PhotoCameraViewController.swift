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
    func returnWithPhotoError()
}


class PhotoCameraViewController: UIViewController {
    
    @IBOutlet var btnCancel: UIButton!
    @IBOutlet var previewView: UIView!
    @IBOutlet var captureImageView: UIImageView!
    @IBOutlet var btnTakePhoto: UIButton!
    @IBOutlet var btnOK: UIButton!
    @IBOutlet var txtNote: UITextField!
    @IBOutlet var photoBackgroundButton: UIView!
    @IBOutlet var btnNavigateToPoint: UIButton!
    @IBOutlet var lblNote: UILabel!
    @IBOutlet var lblLocate: UILabel!
    
    var mainViewDelegate: PhotoShootDelegate?
    var currentID:Int?
    var currentLocation:Point?
    var currentNote:String?
    var currentImage:UIImage?
    var boxView:UIView!
    let myButton: UIButton = UIButton()
    var imageOrientation = UIImageOrientation.right
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func swipeLeftImage(_ sender:Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnOKClicked(_ sender: Any) {
        self.dismiss(animated: true) {
            self.mainViewDelegate?.setPhoto(image: self.captureImageView.image!, id: self.currentID!, note: self.txtNote.text!)
        }
    }
    
    @IBAction func navigateToThisPoint(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SOSModeViewController") as! SOSModeViewController
        vc.endPoint = self.currentLocation
        vc.pointDescription = self.currentNote
        self.present(vc, animated: false, completion: nil)
    }
    
    
    @IBAction func takePhoto(_ sender: Any) {
        
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: self.imageOrientation)
                    
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    self.captureImageView.image = image
                    self.btnOK.isHidden = false
                    self.txtNote.isHidden = false
                    self.btnTakePhoto.isHidden = true
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if(currentID == -1) {
            btnTakePhoto.isHidden = false
            btnOK.isHidden = false
            btnNavigateToPoint.isHidden = true
            startPhotoCamera()
            
            if(videoPreviewLayer != nil) {
                videoPreviewLayer!.frame = previewView.bounds
            }
            else
            {
                showMessage(message: "Sorry, Unable to start camera".localized, completitionHandler: { (completed) in
                    
                    self.dismiss(animated: false, completion: nil)
                    self.mainViewDelegate?.returnWithPhotoError()
                })
            }
        }
        else {
            btnTakePhoto.isHidden = true
            btnOK.isHidden = true
            btnNavigateToPoint.isHidden = false
            photoBackgroundButton.isHidden = true
            txtNote.isHidden = true
            lblNote.isHidden = false
            lblNote.text = currentNote
            lblLocate.isHidden = false
            captureImageView.image = currentImage
            
            DispatchQueue.global(qos: .background).async {
                self.currentImage?.getColors { colors in
                        self.lblNote.textColor = colors.primary
                }
            }
        }
    }
    
    private func showMessage(message:String, completitionHandler:@escaping (_ success:Bool) -> ())  {
        let alert = UIAlertController(title: "Trekkingfy", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
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
    
        session =  AVCaptureSession()
        
        session!.sessionPreset = AVCaptureSession.Preset.photo
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        
        guard (backCamera != nil) else {
            return
        }
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera!)
            
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
            
            if session!.canAddOutput(stillImageOutput!) {
                session!.addOutput(stillImageOutput!)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewView.layer.addSublayer(videoPreviewLayer!)
                previewView.bringSubview(toFront: photoBackgroundButton)
                previewView.bringSubview(toFront: btnTakePhoto)
                previewView.bringSubview(toFront: btnCancel)
                previewView.bringSubview(toFront: btnOK)
                previewView.bringSubview(toFront: btnNavigateToPoint)
                previewView.bringSubview(toFront: lblLocate)
                previewView.bringSubview(toFront: txtNote)
                session!.startRunning()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnNavigateToPoint.isHidden = true
        lblNote.isHidden = true
        lblLocate.isHidden = true
        btnTakePhoto.isHidden = false
    }
    
}
