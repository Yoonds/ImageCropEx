//
//  AnifaceCropView.swift
//  ImageCropEx
//
//  Created by YoonDaesung on 2/5/25.
//

import SwiftUI

struct AnifaceCropView: View {
    
    @StateObject var viewModel = CropViewModel()
    
    let image: UIImage
    
    @State var imageViewSize: CGSize = .zero
    @Binding var cropArea: CGRect?
    @Binding var croppedImage: UIImage?
    
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
                        viewModel.crop(
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
                        viewModel.reset()
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
    
}

private extension CropView {
    
    struct CropBox: View {
        
        @State private var initialRect: CGRect? = nil
        @State private var frameSize: CGSize = .zero
        @State private var draggedCorner: UIRectCorner? = nil
        
        @Binding public var rect: CGRect
        
        public let minSize: CGSize

        public init(
            rect: Binding<CGRect>,
            minSize: CGSize = .init(
                width: 100,
                height: 100
            )
        ) {
            self._rect = rect
            self.minSize = minSize
        }

        private var rectDrag: some Gesture {
            DragGesture()
                .onChanged { gesture in
                    if initialRect == nil {
                        initialRect = rect
                        draggedCorner = closestCorner(point: gesture.startLocation, rect: rect)
                    }
                    if let draggedCorner {
                        self.rect = dragResize(
                            initialRect: initialRect!,
                            draggedCorner: draggedCorner,
                            frameSize: frameSize,
                            translation: gesture.translation
                        )
                    } else {
                        self.rect = drag(
                            initialRect: initialRect!,
                            frameSize: frameSize,
                            translation: gesture.translation
                        )
                    }
                }
                .onEnded { gesture in
                    initialRect = nil
                    draggedCorner = nil
                }
        }

        public var body: some View {
            ZStack(alignment: .topLeading) {
                blur
                box
            }
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { self.frameSize = geometry.size }
                        .onChange(of: geometry.size) { self.frameSize = $0 }
                }
            }
        }

        private var blur: some View {
            Color.black.opacity(0.5)
                .overlay(alignment: .topLeading) {
                    Color.white
                        .frame(width: rect.width - 1, height: rect.height - 1)
                        .offset(x: rect.origin.x, y: rect.origin.y)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .drawingGroup()
                .blendMode(.multiply)
        }

        private var box: some View {
            ZStack {
                grid
                pins
            }
            .border(.white, width: 2)
            .background(Color.white.opacity(0.001))
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.origin.x, y: rect.origin.y)
            .gesture(rectDrag)
        }

        private var pins: some View {
            VStack {
                HStack {
                    pin(corner: .topLeft)
                    Spacer()
                    pin(corner: .topRight)
                }
                Spacer()
                HStack {
                    pin(corner: .bottomLeft)
                    Spacer()
                    pin(corner: .bottomRight)
                }
            }
        }

        private func pin(corner: UIRectCorner) -> some View {
            var offX = 1.0
            var offY = 1.0
            
            switch corner {
                case .topLeft:      offX = -1;  offY = -1
                case .topRight:                 offY = -1
                case .bottomLeft:   offX = -1
                case .bottomRight: break
                default: break
            }

            return Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .offset(x: offX * 4, y: offY * 4)
        }

        private var grid: some View {
            ZStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                    Spacer()
                    Rectangle()
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                    Spacer()
                }
                VStack {
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .foregroundColor(.white.opacity(0.5))
        }

        private func closestCorner(point: CGPoint, rect: CGRect, distance: CGFloat = 16) -> UIRectCorner? {
            let ldX = abs(rect.minX.distance(to: point.x)) < distance
            let rdX = abs(rect.maxX.distance(to: point.x)) < distance
            let tdY = abs(rect.minY.distance(to: point.y)) < distance
            let bdY = abs(rect.maxY.distance(to: point.y)) < distance

            guard (ldX || rdX) && (tdY || bdY) else { return nil }

            return if ldX && tdY { .topLeft }
            else if rdX && tdY { .topRight }
            else if ldX && bdY { .bottomLeft }
            else if rdX && bdY { .bottomRight }
            else { nil }
        }

        private func dragResize(initialRect: CGRect, draggedCorner: UIRectCorner, frameSize: CGSize, translation: CGSize) -> CGRect {
            var offX = 1.0
            var offY = 1.0

            switch draggedCorner {
            case .topLeft:      offX = -1;  offY = -1
            case .topRight:                 offY = -1
            case .bottomLeft:   offX = -1
            case .bottomRight: break
            default: break
            }

            let idealWidth = initialRect.size.width + offX * translation.width
            var newWidth = max(idealWidth, minSize.width)

            let maxHeight = frameSize.height - initialRect.minY
            let idealHeight = initialRect.size.height + offY * translation.height
            var newHeight = max(idealHeight, minSize.height)

            var newX = initialRect.minX
            var newY = initialRect.minY

            if offX < 0 {
                let widthChange = newWidth - initialRect.width
                newX = max(newX - widthChange, 0)
                newWidth = min(newWidth, initialRect.maxX)
            } else {
                newWidth = min(newWidth, frameSize.width - initialRect.minX)
            }

            if offY < 0 {
                let heightChange = newHeight - initialRect.height
                newY = max(newY - heightChange, 0)
                newHeight = min(initialRect.maxY, newHeight)
            } else {
                newHeight = min(newHeight, maxHeight)
            }

            return .init(origin: .init(x: newX, y: newY), size: .init(width: newWidth, height: newHeight))
        }

        private func drag(initialRect: CGRect, frameSize: CGSize, translation: CGSize) -> CGRect {
            let maxX = frameSize.width - initialRect.width
            let newX = min(max(initialRect.origin.x + translation.width, 0), maxX)
            let maxY = frameSize.height - initialRect.height
            let newY = min(max(initialRect.origin.y + translation.height, 0), maxY)

            return .init(origin: .init(x: newX, y: newY), size: initialRect.size)
        }
    }
    
}
