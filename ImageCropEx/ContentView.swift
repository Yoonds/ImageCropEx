//
//  ContentView.swift
//  ImageCropEx
//
//  Created by YoonDaesung on 2/5/25.
//

import SwiftUI

// 라이브러리 사용 부
struct ContentView: View {
    
    private var image = UIImage(named: "sample")!
    
    @State var isShowCropView: Bool = false
    @State var croppedImage: UIImage?
    @State var cropArea: CGRect?
    
    var body: some View {
        VStack {
            Button(action: {
                isShowCropView = true
            }, label: {
                if let croppedImage = croppedImage {
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                }
            })
        }
        .fullScreenCover(isPresented: $isShowCropView) {
            AnifaceCropView(
                image: image,
                cropArea: $cropArea,
                croppedImage: $croppedImage
            )
        }
    }
    
}
