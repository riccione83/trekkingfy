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
    
    var mainViewDelegate: PhotoShootDelegate?
    var currentID:Int?
    
    var boxView:UIView!
    let myButton: UIButton = UIButton()
    
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
                    
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                
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
            self.dismiss(animated: false, completion: nil)
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
        } catch let error1 as NSError {
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
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                previewView.layer.addSublayer(videoPreviewLayer!)
                session!.startRunning()
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startPhotoCamera()
    }

}
