//
//  DataManager.swift
//  FaceSelectionSwift
//
//  Created by Pierce on 7/13/18.
//  Copyright © 2018 Pierce. All rights reserved.
//

import UIKit

protocol DataManagerDelegate: class {
    func faceDataLoaded(with faces: [Face])
    func imageLoaded(image: UIImage)
}

class DataManager {
    
    // Endpoints provided in documentation, and original Obj-C project.
    let jsonURLString = "https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family_faces.json"
    let imageURLString = "https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family.jpg"
    
    // DataManagerDelegate - always has a weak reference to avoid reciprocal references.
    weak var delegate: DataManagerDelegate?
    
    init() {
        // Fectch and save JSON and image when initialized.
        fetchJSON(from: jsonURLString)
        fetchImage(from: imageURLString)
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        // Asychronous fetch of data from url endpoint
        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            // Data loaded successfully, call completion handler.
            completion(data, response, error)
            }.resume()
    }
    func fetchJSON(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        getDataFromUrl(url: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            print(data)
            // Use Swift 4's awesome new JSONDecoder to parse JSON file.
            let decoder = JSONDecoder()
            do {
                let retrievedFaces = try decoder.decode([Face].self, from: data)
                // Dispatch delegate callback asynchronously to the main thread
                DispatchQueue.main.async {
                    self.delegate?.faceDataLoaded(with: retrievedFaces)
                }
                // fileName for the JSON to save in documents directory
                let jsonName = "face_metadata.json"
                let jsonPath = self.fileInDocumentsDirectory(jsonName)
                try? data.write(to: URL(fileURLWithPath: jsonPath), options: [.atomic])
                // Print to console to confirm the fetch and save
                print("JSON Fetched and saved at: \(jsonPath)")
            } catch  {
                print("failed to convert data")
            }
        }
    }
    func fetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        getDataFromUrl(url: url) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data, let image = UIImage(data: data) else { return }
            // Dispatch delegate callback asynchronously
            DispatchQueue.main.async {
                self.delegate?.imageLoaded(image: image)
            }
            // File name for image file to save in documents dir
            let imageName = "image.jpg"
            let imagePath = self.fileInDocumentsDirectory(imageName)
            self.saveImage(image, path: imagePath)
            // Print to console to confirm the fetch and save
            print("Image Fetched and saved at: \(imagePath)")
        }
    }
    func getDocumentsURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    func fileInDocumentsDirectory(_ filename: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL.path
    }
    
    func saveImage(_ image: UIImage, path: String ) {
        // if you want to save as JPEG
        if let jpgImageData = UIImageJPEGRepresentation(image, 1.0) {
            try? jpgImageData.write(to: URL(fileURLWithPath: path), options: [.atomic])
        }
    }
    
}
