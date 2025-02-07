//
//  CropViewModel.swift
//  ImageCropEx
//
//  Created by YoonDaesung on 2/7/25.
//

import Foundation
import SwiftUI

protocol CropViewModelable: ObservableObject {
    
    @MainActor func crop()
    @MainActor func reset()
    
}

class CropViewModel: CropViewModelable {
    
    @Published var imageViewSize: CGSize = .zero
    @Published var croppedImage: UIImage?
    @Published var cropArea: CGRect?
    
    func crop(image: UIImage, cropArea: CGRect, imageViewSize: CGSize) {
        let scaleX = image.size.width / imageViewSize.width * image.scale
        let scaleY = image.size.height / imageViewSize.height * image.scale
        let scaledCropArea = CGRect(
            x: cropArea.origin.x * scaleX,
            y: cropArea.origin.y * scaleY,
            width: cropArea.size.width * scaleX,
            height: cropArea.size.height * scaleY
        )
        
        guard let cutImageRef: CGImage = image.cgImage?.cropping(to: scaledCropArea) else {
            return
        }
        
        croppedImage = UIImage(cgImage: cutImageRef)
    }
    
    func reset() {
        withAnimation {
            self.cropArea = CGRect(origin: .zero, size: self.imageViewSize)
        }
    }
    
}

extension CropViewModel {
    
    private func bind() {
        
    }
    
}
