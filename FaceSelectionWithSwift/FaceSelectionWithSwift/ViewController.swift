//
//  ViewController.swift
//  FaceSelectionWithSwift
//
//  Created by Pierce on 7/14/18.
//  Copyright © 2018 Pierce. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var faceData: [Face]?
    var imageLoaded = false
    var faceTapRecognizers = [UITapGestureRecognizer]()
    var faceRectangleViews = [UIView]()
    var highlights = [CAShapeLayer]()
    
    // These will be very important for the accuracy of the rectangle and highlight placements, see comments below where calculations are made
    var widthConstant: CGFloat = 0.0
    var heightConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Translated from the Obj-C project
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        imageView.image = nil
        textView.text = nil
        
        // I set up the DataManager to fetch and save both the JSON and image files when initialized, so by just launching the app, once viewDidLoad is called, the image and JSON both will be fetched and saved.
        let dataManager = DataManager()
        dataManager.delegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setImageProperties() {
        guard let image = imageView.image else { return }
        let actualImageSize = image.size
        // Here I'm going to resize the imageView to fit within the screen's constraints. This is important as the origin points for the rectangles and the highlights are strictly relative to the actual image size of the image. The image is much larger than the screen of say an iPhone 8 in portait mode. We want to see the whole image so the contentMode for the imageView is set to scaleToFill, and to keep proper aspects the imageView should be resized based on the available size of the screen.
        if actualImageSize.width > view.frame.width {
            let constant = view.frame.width / actualImageSize.width
            imageViewWidth.constant = actualImageSize.width * constant
            imageViewHeight.constant = actualImageSize.height * constant
        }
        imageView.isUserInteractionEnabled = true
        // Add a tapGesture also to the image so user can deselect faces.
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.addGestureRecognizer(imageTap)
    }
    
    func drawFaceRectangles(with faces: [Face]) {
        setImageProperties()
        // Loop through the faces and get the gender and rectangle data
        for face in faces {
            let pink: UIColor = UIColor(red: 0.8784, green: 0, blue: 0.4667, alpha: 1.0)
            let color = face.faceAttributes.gender == "male" ? UIColor.blue : pink
            
            // I noticed that the origin and size dimensions for the rectangles are based on the acutal size of the image, unfortunatley that will cause problems with different screen sizes, and if the content mode of the image isn't set correctly. Based on this im going to use some simple mathematical ratios to adjust the size of the imageView and reset the rectangles accordingly.
            // I can safely force unwrap the image here, mainly because I set the code to only call this method once the DataManagerDelegate has called back to say the image has been loaded. Normally I avoid any force unwrapping.
            widthConstant = imageViewWidth.constant / imageView.image!.size.width
            heightConstant = imageViewHeight.constant / imageView.image!.size.height
            
            // So there's multiple ways I can think of to go about this, one is to use layers to draw lines from point to point based on the rectangle data, another is to use a shape layer to draw a rectangle, but actually for just this simple case we can use a transparent UIView with a colored border to make the appearance of a rectangle. This will also allow me to add a UITapGestureRecognizer to the transparent view so that it can respond to touch events.
            let rectangleView = UIView()
            rectangleView.backgroundColor = .clear
            imageView.addSubview(rectangleView)
            rectangleView.layer.borderColor = color.cgColor
            rectangleView.layer.borderWidth = 2.0 // Not selected, standard border width
            // Here we adjust the points of origin, and the height and width of the rectangles provided from the JSON to fit within the constraints of the imageView (see above for the calculation of the constants)
            let origin = CGPoint(x: CGFloat(face.faceRectangle.left) * widthConstant, y: CGFloat(face.faceRectangle.top) * heightConstant)
            let size = CGSize(width: CGFloat(face.faceRectangle.width) * widthConstant, height: CGFloat(face.faceRectangle.height) * heightConstant)
            // Set the adjusted frame of the face rectangle.
            rectangleView.frame = CGRect(origin: origin, size: size)
            let tap = UITapGestureRecognizer(target: self, action: #selector(faceTapped(_:)))
            rectangleView.addGestureRecognizer(tap)
            faceRectangleViews.append(rectangleView)
            faceTapRecognizers.append(tap)
            // Bring the rectangleView to the front of the imageView in the view hierarchy
            imageView.bringSubview(toFront: rectangleView)
        }
    }
    
    @objc func faceTapped(_ recognizer: UITapGestureRecognizer) {
        guard let faceData = faceData else { return }
        if let index = faceTapRecognizers.index(of: recognizer) {
            let selectedView = faceRectangleViews[index]
            // If selected, set borderWidth of 2.0, else show it selected with width of 5.0
            let borderWidth: CGFloat = selectedView.layer.borderWidth > 2.0 ? 2.0 : 5.0
            selectedView.layer.borderWidth = borderWidth// Deselect those not selected, unless index is non-nil
            // Deselect all faces EXCEPT that of the selected index
            deselectAllFaces(index: index)
            if borderWidth == 2.0 {
                textView.text = nil
            } else {
                //Set the text in textView based on selected face
                setText(for: faceData[index], index: index)
                highlightLandmarks(for: faceData[index])
            }
            
        }
    }
    
    func deselectAllFaces(index: Int? = nil) {
        // This will deselct all the faces, unless an index value is passed in (it's set to nil as default so if the method is called without the parameter defined it will deselct all). If you pass in an index, it will deselect every face excpet for the one with that index.
        for i in 0 ..< faceRectangleViews.count {
            if index != nil && i != index {
                deselectFace(at: i)
            } else if index == nil {
                deselectFace(at: i)
            }
        }
    }
    
    func deselectFace(at index: Int) {
        faceRectangleViews[index].layer.borderWidth = 2.0
        removeHighlights()
    }
    
    @objc func imageTapped(_ recognizer: UITapGestureRecognizer) {
        // the image was tapped outside of the outlined faces, so deselct all faces.
        deselectAllFaces()
        textView.text = nil
    }
    
    func setText(for face: Face, index: Int) {
        let emotionTupleArray = [("Anger", face.faceAttributes.emotion.anger), ("Contempt", face.faceAttributes.emotion.contempt), ("Disgust", face.faceAttributes.emotion.disgust), ("Fear", face.faceAttributes.emotion.fear), ("Happiness", face.faceAttributes.emotion.happiness), ("Neutral", face.faceAttributes.emotion.neutral), ("Sadness", face.faceAttributes.emotion.sadness), ("Surprise", face.faceAttributes.emotion.surprise)]
        let sortedEmotions = emotionTupleArray.sorted { $1.1 < $0.1 }
        print(sortedEmotions)
        let mostConfidentEmotion = sortedEmotions.first
        let confidentPercentage = mostConfidentEmotion!.1 * 100
        let faceArea = faceRectangleViews[index].frame.height * faceRectangleViews[index].frame.width
        let imageArea = imageViewHeight.constant * imageViewWidth.constant
        let faceAreaCalculated = Double(faceArea / imageArea) * 100
        print("FaceArea \(faceAreaCalculated)")
        textView.text = "Gender: \(face.faceAttributes.gender)\rAge: \(face.faceAttributes.age)\rMost Confident Emotion: \(mostConfidentEmotion!.0) - \(confidentPercentage)%\r% of Face Area to Photo: \(faceAreaCalculated.truncate(places: 2))%"
    }
    
    func highlightLandmarks(for face: Face) {
        // The JSON for the face landmarks wasn't structed to make them an array, so it didn't make an array when parsing. in order to iterate through, I'm going to manually make an array of landmarks.
        let landmarks = [face.faceLandmarks.eyebrowLeftInner, face.faceLandmarks.eyebrowLeftOuter, face.faceLandmarks.eyebrowRightInner, face.faceLandmarks.eyebrowRightOuter, face.faceLandmarks.eyeLeftBottom, face.faceLandmarks.eyeLeftInner, face.faceLandmarks.eyeLeftOuter, face.faceLandmarks.eyeLeftTop, face.faceLandmarks.eyeRightBottom, face.faceLandmarks.eyeRightInner, face.faceLandmarks.eyeRightOuter, face.faceLandmarks.eyeRightTop, face.faceLandmarks.mouthLeft, face.faceLandmarks.mouthRight, face.faceLandmarks.noseLeftAlarOutTip, face.faceLandmarks.noseLeftAlarTop, face.faceLandmarks.noseRightAlarOutTip, face.faceLandmarks.noseRightAlarTop, face.faceLandmarks.noseRootLeft, face.faceLandmarks.noseRootRight, face.faceLandmarks.noseTip, face.faceLandmarks.pupilLeft, face.faceLandmarks.pupilRight, face.faceLandmarks.underLipBottom, face.faceLandmarks.underLipTop, face.faceLandmarks.upperLipBottom, face.faceLandmarks.upperLipTop]
        // PHEW That's a lot!
        for landmark in landmarks {
            // Create a CAShapyLayer using the x,y coordinates for the landmark, and draw it on top of the imageView, since that's what the coordinates relate to
            let shape = CAShapeLayer()
            let shapePath = UIBezierPath()
            // Once again the point of origin has to be adjusted to fit the calculated area of the imageView. See above for calculation of contstants.
            let startPoint = CGPoint(x: CGFloat(landmark.x) * widthConstant, y: CGFloat(landmark.y) * heightConstant)
            let π = CGFloat.pi
            // Draw an arc with center point, a radius of 1.0 (2.0 in diameter) from 0 to 2π, so essentially just a circle.
            shapePath.addArc(withCenter: startPoint, radius: 1.0, startAngle: 0, endAngle: 2*π, clockwise: true)
            UIColor.green.setStroke()
            shapePath.stroke()
            shape.path = shapePath.cgPath
            shape.fillColor = UIColor.green.cgColor
            // Append the layers to the array so they can be removed at deselction time.
            highlights.append(shape)
            // Since the highlight points of origin are relative to the dimensions of the image itself, we will add them to the layer of the imageView, not the related rectangle.
            imageView.layer.addSublayer(shape)
        }
    }
    
    func removeHighlights() {
        // Remove all highlights from the superlayer and then clear the array.
        for highlight in highlights {
            highlight.removeFromSuperlayer()
        }
        highlights.removeAll()
    }
    
}

// Conform to the DataManager delegate
extension ViewController: DataManagerDelegate {
    func faceDataLoaded(with faces: [Face]) {
        self.faceData = faces
        if imageLoaded {
            self.drawFaceRectangles(with: faces)
        }
    }
    func imageLoaded(image: UIImage) {
        self.imageLoaded = true
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        self.imageView.image = image
        if let faceData = faceData {
            self.drawFaceRectangles(with: faceData)
        }
    }
}

extension Double {
    // For text display of percentages.
    func truncate(places : Int)-> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}

