//
//  CropView.swift
//  ImageCropEx
//
//  Created by YoonDaesung on 2/5/25.
//

import SwiftUI

struct CropView: View {
    
    let image: UIImage
    
    @State var imageViewSize: CGSize = .zero
    @Binding var cropArea: CGRect?
    @Binding var croppedImage: UIImage?
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(alignment: .topLeading) {
                    GeometryReader { geometry in
                        CropBox(rect: Binding(
                            get: {
                                if let existingCropArea = cropArea {
                                    return existingCropArea
                                } else {
                                    let cropWidth: CGFloat = 200
                                    let cropHeight: CGFloat = 200
                                    let x = (geometry.size.width - cropWidth) / 2
                                    let y = (geometry.size.height - cropHeight) / 2
                                    let newCropArea = CGRect(x: x, y: y, width: cropWidth, height: cropHeight)
                                    DispatchQueue.main.async {
                                        cropArea = newCropArea
                                    }
                                    return newCropArea
                                }
                            }, set: { newValue in
                                cropArea = newValue
                            }))
                        .onAppear {
                            self.imageViewSize = geometry.size
                        }
                        .onChange(of: geometry.size) {
                            self.imageViewSize = $0
                        }
                    }
                }
            
            Spacer()
                .frame(height: 30)
            
            HStack {
                Button(
                    action: {
                        self.crop(
                            image: image,
                            cropArea: cropArea ?? CGRect.zero,
                            imageViewSize: imageViewSize
                        )
                    },
                    label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                    }
                )
                
                Button(
                    action: {
                        self.reset()
                    }, label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.white)
                    }
                )
            }
            
            Spacer()
        }
        .background(Color.black)
    }
    
    private func crop(image: UIImage, cropArea: CGRect, imageViewSize: CGSize) {
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
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func reset() {
        DispatchQueue.main.async {
            withAnimation {
                self.cropArea = CGRect(origin: .zero, size: self.imageViewSize)
            }
        }
    }
    
}


