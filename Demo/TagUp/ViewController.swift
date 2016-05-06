//
//  ViewController.swift
//  TagUp
//
//  Created by Behrooz Amuyan on 4/24/16.
//  Copyright © 2016 Behrooz. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON



class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    // stores the two API calls which have been made to AMEGGA.Retriveing tags = tags and comfidences, colors = Retrieving color information
    var tags   : [JSON]!
    var colors : [JSON]!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnTakePhotoOutlet: UIButton!
    @IBOutlet weak var activityInductorView: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    // If the app is run on the simulator , Photo Libarary folder gets choseb to pick an image.If it runs on device Camera gets activated.
    @IBAction func btnTakePhoto(sender: UIButton) {
        
        let picker = UIImagePickerController()
        picker.delegate      = self
        picker.allowsEditing = false
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            picker.sourceType = UIImagePickerControllerSourceType.Camera
        } else {
            picker.sourceType = .PhotoLibrary
            picker.modalPresentationStyle = .FullScreen
        }
        presentViewController(picker, animated: true, completion: nil)
        
    }
    
    //Read the Image Picked from UIImagePickerController
    //“imagePickerController:didFinishPickingMediaWithInfo:” which is called exactly what it sounds like it should be, when the user picks something.
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = pickedImage
            btnTakePhotoOutlet.hidden = true
            progressView.progress = 0.0
            progressView.hidden = false
            activityInductorView.startAnimating()
            
            //uploadint the image by calling the uploadImage() - Alamofir.upload

            uploadImage(pickedImage, progress: { percent in
                self.progressView.setProgress(percent, animated: true)
                
            })
            
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Checks if the device doesn't have a camera , it asks the user to select a photo
        if !UIImagePickerController.isSourceTypeAvailable((.Camera)){
            btnTakePhotoOutlet.setTitle("Select Photo", forState: .Normal)
        
        }
        // set the image view nill at the time of loading
        imageView.image = nil
        // setting the Take Photo button attributes.
        btnTakePhotoOutlet.layer.cornerRadius = 5
        btnTakePhotoOutlet.layer.borderWidth = 1
        btnTakePhotoOutlet.layer.borderColor = UIColor.blackColor().CGColor
    }

    
}
// MARK: - Networking
//These UIImageXXXRepresentation functions strip the image of its meta data.
extension ViewController {
    func uploadImage ( image : UIImage, progress :(percent : Float) ->Void ) -> Void {
        let imageData  = UIImageJPEGRepresentation(image, 0.5)
        
        //Uploading the picked image
        Alamofire.upload(
            .POST,
            "http://api.imagga.com/v1/content",
            headers: ["Authorization" : "Basic YWNjXzkxZGIzNDNiNzY5ZTcxNTowNDA5NzhjZmE1ZTJkYTE0Mjg2NWJkZTZmMzMyODU3Mw=="],
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: imageData!, name: "imagefile",
                    fileName: "image.jpg", mimeType: "image/jpeg")
            },
            encodingCompletion: { encodingResult in
                // getting akcnowledgemnet  - response of uploading image
                print ("reposns ein cURL \(encodingResult)")
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.progress{ bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                        print(totalBytesWritten)
                        // https://github.com/Alamofire/Alamofire   -- look for "Uploading with Progress"
                        // This closure is NOT called on the main queue for performance
                        // reasons. To update your ui, dispatch to the main queue.
                        dispatch_async(dispatch_get_main_queue()) {
                            print("Total bytes written on main queue: \(totalBytesWritten)")
                            let percent = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
                            progress(percent: percent)
                            }
                        }
                        .responseJSON { response in
                            debugPrint(response)
                    }
                    upload.validate()
                    upload.responseJSON { response in
                        // get the image id - SwiftyJSON
                        let json = JSON(data: response.data!)
                        let uploadFiles = json["uploaded"]
                        let firstFile = uploadFiles[0]
                        let firstFileID = firstFile["id"].stringValue
                        
                        
                        print ("firstFileID is \(firstFileID)")
                        
                        // calling downloadTags() inside of the uploadImage()
                        // getting the tags from the API call to imagga
                        
                        self.downloadTags(firstFileID, success: { json in
                            
                            // Write a function / closure to handle the json that is passed back to me by the function 'downloadTags'
                            self.downloadColors(firstFileID, success: { colors in
                                self.colors = colors
                                print ("colors top is \(colors)")
                                //self.btnTakePhotoOutlet.hidden = false
                                self.progressView.hidden = true
                                self.activityInductorView.stopAnimating()
                                self.performSegueWithIdentifier("ShowResults", sender: self)
                                self.btnTakePhotoOutlet.hidden = false
                            })
                            self.tags = json
                            
                            // a sample code to validate the response.
                           // self.shouldPerformSegueWithIdentifier("ShowResults", sender: self)
//                            Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
//                                .validate(statusCode: 200..<300)
//                                .validate(contentType: ["application/json"])
//                                .response { response in
//                                    // response handling code
//                            }
                            
                         })
                        
                        }
                    // the enum getting returned by the validation() - https://github.com/Alamofire/Alamofire   look for "Manual Validation"
                   case .Failure(let encodingError):
                    print(encodingError)
                }
                
            })
    }
    // downloading tags and confidences finction
    func downloadTags( contentID:String, success: (json: [JSON]) -> Void ) -> Void  {
    
    Alamofire.request(.GET, "http://api.imagga.com/v1/tagging", parameters: ["content": contentID], headers: ["Authorization" : "Basic YWNjXzkxZGIzNDNiNzY5ZTcxNTowNDA5NzhjZmE1ZTJkYTE0Mjg2NWJkZTZmMzMyODU3Mw=="]).responseJSON { response in
        
        let json = JSON(data: response.data!)
        
        
        // With SwiftyJSON, you can access keys without the need to type cast and unwrapped optionals. HUGE!!!!
        
        let tagsAndConfidences = json["results"][0]["tags"].arrayValue
        
        success(json: tagsAndConfidences)
        
       
    }
    
}
    // downlading colors information
    func downloadColors(contentID: String, success:(colors:[JSON]) -> Void) -> Void {
        Alamofire.request(.GET, "https://api.imagga.com/v1/colors", parameters:["content": contentID],  headers: ["Authorization" : "Basic YWNjXzkxZGIzNDNiNzY5ZTcxNTowNDA5NzhjZmE1ZTJkYTE0Mjg2NWJkZTZmMzMyODU3Mw=="]).responseJSON { response in
            let json = JSON(data: response.data!)
            
            let colors = json["results"][0]["info"]["foreground_colors"].arrayValue
            
            
            success(colors: colors)
            
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
            navigationItem.title = nil
            let controller = segue.destinationViewController as! TagsViewController
       
            controller.tags   = tags
            controller.colors = colors
            print ("tags is \(tags)")
            print ( "colors is \(colors)")
        
    }
    
    
}


