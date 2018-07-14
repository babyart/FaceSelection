//
//  Face.swift
//  FaceSelectionSwift
//
//  Created by Pierce on 7/13/18.
//  Copyright © 2018 Pierce. All rights reserved.
//

import Foundation

// Make properties for the values observed in JSON file from AWS endpoint

// One main reason I decided to do this project in Swift is due to the new Codable protocol released in Swift 4. After looking at the JSON file that I would be parsing, I noticed that it was somewhat intricate. It contained nested JSON objects, and had a decent number of properties. This type of case is perfect for the new JSON Decoding abilities with Swift 4. As you can see below you can easily create a struct, where the properties are named exactly what you would see in your JSON, and you can also create structs for the nested JSON objects. As long as your structs conform to the Codable protocol, and the properties are named and structured properly, then you just have to tell the JSONDecoder to decode the data, and it magically parses the JSON for you!

struct Face: Codable {
    struct FaceRectangle: Codable {
        var top: Int
        var left: Int
        var width: Int
        var height: Int
    }
    struct FaceAttributes: Codable {
        var hair: FaceAttributesHair
        var smile: Double
        var headPose: FaceAttributesHeadPose
        var gender: String
        var age: Double
        var facialHair: FaceAttributesFacialHair
        var glasses: String
        var makeup: FaceAttributesMakeup
        var emotion: FaceAttributesEmotion
        var occlusion: FaceAttributesOcclusion
        var accessories: [FaceAttributesAccessory]
        var blur: FaceAttributesAccessoryBlur
        var exposure: FaceAttributesExposure
        var noise: FaceAttributesNoise
    }
    struct FaceLandmarks: Codable {
        var pupilLeft: FaceLandmark
        var pupilRight: FaceLandmark
        var noseTip: FaceLandmark
        var mouthLeft: FaceLandmark
        var mouthRight: FaceLandmark
        var eyebrowLeftOuter: FaceLandmark
        var eyebrowLeftInner: FaceLandmark
        var eyeLeftOuter: FaceLandmark
        var eyeLeftTop: FaceLandmark
        var eyeLeftBottom: FaceLandmark
        var eyeLeftInner: FaceLandmark
        var eyebrowRightInner: FaceLandmark
        var eyebrowRightOuter: FaceLandmark
        var eyeRightInner: FaceLandmark
        var eyeRightTop: FaceLandmark
        var eyeRightBottom: FaceLandmark
        var eyeRightOuter: FaceLandmark
        var noseRootLeft: FaceLandmark
        var noseRootRight: FaceLandmark
        var noseLeftAlarTop: FaceLandmark
        var noseRightAlarTop: FaceLandmark
        var noseLeftAlarOutTip: FaceLandmark
        var noseRightAlarOutTip: FaceLandmark
        var upperLipTop: FaceLandmark
        var upperLipBottom: FaceLandmark
        var underLipTop: FaceLandmark
        var underLipBottom: FaceLandmark
    }
    struct FaceAttributesHair: Codable {
        var bald: Double
        var invisible: Bool
        var hairColor: [FaceAttributesHairColor]
    }
    struct FaceAttributesHairColor: Codable {
        var color: String
        var confidence: Double
    }
    struct FaceAttributesHeadPose: Codable {
        var pitch: Double
        var roll: Double
        var yaw: Double
    }
    struct FaceAttributesFacialHair: Codable {
        var moustache: Double
        var beard: Double
        var sideburns: Double
    }
    struct FaceAttributesMakeup: Codable {
        var eyeMakeup: Bool
        var lipMakeup: Bool
    }
    struct FaceAttributesEmotion: Codable {
        var anger: Double
        var contempt: Double
        var disgust: Double
        var fear: Double
        var happiness: Double
        var neutral: Double
        var sadness: Double
        var surprise: Double
    }
    struct FaceAttributesOcclusion: Codable {
        var foreheadOccluded: Bool
        var eyeOccluded: Bool
        var mouthOccluded: Bool
    }
    struct FaceAttributesAccessory: Codable {
        var type: String
        var confidence: Double
    }
    struct FaceAttributesAccessoryBlur: Codable {
        var blurLevel: String
        var value: Double
    }
    struct FaceAttributesExposure: Codable {
        var exposureLevel: String
        var value: Double
    }
    struct FaceAttributesNoise: Codable {
        var noiseLevel: String
        var value: Double
    }
    struct FaceLandmark: Codable {
        var x: Double
        var y: Double
    }
    var faceId: String
    var faceRectangle: FaceRectangle
    var faceAttributes: FaceAttributes
    var faceLandmarks: FaceLandmarks
    
}


