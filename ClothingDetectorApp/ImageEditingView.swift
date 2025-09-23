import SwiftUI
import UIKit

struct ImageEditingView: View {
    @Binding var originalImage: UIImage
    @Binding var editedImage: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentImage: UIImage
    @State private var rotationAngle: Double = 0
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1
    @State private var cropOffset = CGSize.zero
    @State private var cropScale: CGFloat = 1.0
    @State private var showingCropView = false
    @State private var isProcessing = false
    @State private var isFlippedHorizontally = false
    @State private var isFlippedVertically = false
    
    // Crop-related states
    @State private var cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    @State private var dragOffset = CGSize.zero
    @State private var lastDragValue = CGSize.zero
    
    init(originalImage: Binding<UIImage>, editedImage: Binding<UIImage>) {
        self._originalImage = originalImage
        self._editedImage = editedImage
        self._currentImage = State(initialValue: originalImage.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Image Preview
                ZStack {
                    if showingCropView {
                        CropView(
                            image: currentImage,
                            cropRect: $cropRect,
                            onCropComplete: { croppedImage in
                                currentImage = croppedImage
                                showingCropView = false
                                applyAllEdits()
                            }
                        )
                    } else {
                        GeometryReader { geometry in
                            Image(uiImage: currentImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .rotationEffect(.degrees(rotationAngle))
                                .scaleEffect(x: isFlippedHorizontally ? -1 : 1, y: isFlippedVertically ? -1 : 1)
                                .brightness(brightness)
                                .contrast(contrast)
                                .saturation(saturation)
                                .clipped()
                        }
                    }
                    
                    if isProcessing {
                        Color.black.opacity(0.6)
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 400)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding()
                
                // Editing Tools
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Rotate & Flip Section
                        EditingSectionView(title: "Transform", icon: "rotate.right") {
                            VStack(spacing: 12) {
                                // Rotation Controls
                                HStack {
                                    Button("↺ 90°") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            rotationAngle -= 90
                                        }
                                        applyAllEdits()
                                    }
                                    .buttonStyle(EditingButtonStyle())
                                    
                                    Spacer()
                                    
                                    Button("↻ 90°") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            rotationAngle += 90
                                        }
                                        applyAllEdits()
                                    }
                                    .buttonStyle(EditingButtonStyle())
                                }
                                
                                Slider(value: $rotationAngle, in: -180...180, step: 1) {
                                    Text("Fine Rotation")
                                } minimumValueLabel: {
                                    Text("-180°").font(.caption)
                                } maximumValueLabel: {
                                    Text("180°").font(.caption)
                                }
                                .onChange(of: rotationAngle) { _, _ in
                                    applyAllEdits()
                                }
                                
                                // Flip Controls
                                HStack {
                                    Button("⇄ Flip H") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isFlippedHorizontally.toggle()
                                        }
                                        applyAllEdits()
                                    }
                                    .buttonStyle(EditingButtonStyle(color: isFlippedHorizontally ? .purple : .gray))
                                    
                                    Spacer()
                                    
                                    Button("⇅ Flip V") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isFlippedVertically.toggle()
                                        }
                                        applyAllEdits()
                                    }
                                    .buttonStyle(EditingButtonStyle(color: isFlippedVertically ? .purple : .gray))
                                }
                            }
                        }
                        
                        // Crop Section
                        EditingSectionView(title: "Crop", icon: "crop") {
                            Button("Crop Image") {
                                showingCropView = true
                            }
                            .buttonStyle(EditingButtonStyle(fullWidth: true))
                        }
                        
                        // Brightness Section
                        EditingSectionView(title: "Brightness", icon: "sun.max") {
                            VStack {
                                Slider(value: $brightness, in: -0.5...0.5, step: 0.01) {
                                    Text("Brightness")
                                } minimumValueLabel: {
                                    Image(systemName: "sun.min").font(.caption)
                                } maximumValueLabel: {
                                    Image(systemName: "sun.max").font(.caption)
                                }
                                .onChange(of: brightness) { _, _ in
                                    applyAllEdits()
                                }
                                
                                Text("\\(Int(brightness * 200))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Contrast Section
                        EditingSectionView(title: "Contrast", icon: "circle.lefthalf.filled") {
                            VStack {
                                Slider(value: $contrast, in: 0.5...2.0, step: 0.01) {
                                    Text("Contrast")
                                } minimumValueLabel: {
                                    Text("Low").font(.caption)
                                } maximumValueLabel: {
                                    Text("High").font(.caption)
                                }
                                .onChange(of: contrast) { _, _ in
                                    applyAllEdits()
                                }
                                
                                Text("\\(Int(contrast * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Saturation Section
                        EditingSectionView(title: "Saturation", icon: "paintpalette") {
                            VStack {
                                Slider(value: $saturation, in: 0...2.0, step: 0.01) {
                                    Text("Saturation")
                                } minimumValueLabel: {
                                    Text("B&W").font(.caption)
                                } maximumValueLabel: {
                                    Text("Vivid").font(.caption)
                                }
                                .onChange(of: saturation) { _, _ in
                                    applyAllEdits()
                                }
                                
                                Text("\\(Int(saturation * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Reset Section
                        EditingSectionView(title: "Reset", icon: "arrow.counterclockwise") {
                            Button("Reset All Changes") {
                                resetToOriginal()
                            }
                            .buttonStyle(EditingButtonStyle(fullWidth: true, color: .red))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    editedImage = currentImage
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            currentImage = originalImage
        }
    }
    
    private func applyAllEdits() {
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            let editedImage = await processImageAsync()
            await MainActor.run {
                self.currentImage = editedImage
                self.isProcessing = false
            }
        }
    }
    
    private static let sharedContext = CIContext(options: [.useSoftwareRenderer: false])
    
    private func processImageAsync() async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let ciImage = CIImage(image: self.originalImage) else {
                    continuation.resume(returning: self.originalImage)
                    return
                }
                
                var processedImage = ciImage
                
                // Combine all filters into one operation
                if brightness != 0 || contrast != 1 || saturation != 1 {
                    processedImage = processedImage.applyingFilter("CIColorControls", parameters: [
                        kCIInputBrightnessKey: self.brightness,
                        kCIInputContrastKey: self.contrast,
                        kCIInputSaturationKey: self.saturation
                    ])
                }
                
                // Apply transformations in one operation
                var transform = CGAffineTransform.identity
                if self.rotationAngle != 0 {
                    transform = transform.rotated(by: self.rotationAngle * .pi / 180)
                }
                if self.isFlippedHorizontally {
                    transform = transform.scaledBy(x: -1, y: 1)
                }
                if self.isFlippedVertically {
                    transform = transform.scaledBy(x: 1, y: -1)
                }
                if !transform.isIdentity {
                    processedImage = processedImage.transformed(by: transform)
                }
                
                guard let cgImage = Self.sharedContext.createCGImage(processedImage, from: processedImage.extent) else {
                    continuation.resume(returning: self.originalImage)
                    return
                }
                
                continuation.resume(returning: UIImage(cgImage: cgImage))
            }
        }
    }
    
    private func resetToOriginal() {
        withAnimation {
            rotationAngle = 0
            brightness = 0
            contrast = 1
            saturation = 1
            isFlippedHorizontally = false
            isFlippedVertically = false
            currentImage = originalImage
        }
        applyAllEdits()
    }
}

struct CropView: View {
    let image: UIImage
    @Binding var cropRect: CGRect
    let onCropComplete: (UIImage) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Background image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .background(
                        GeometryReader { imageGeometry in
                            Color.clear.onAppear {
                                imageSize = imageGeometry.size
                            }
                        }
                    )
                
                // Crop overlay with semi-transparent background
                ZStack {
                    // Dark overlay
                    Color.black.opacity(0.6)
                        .mask(
                            Rectangle()
                                .fill(Color.black)
                                .overlay(
                                    Rectangle()
                                        .frame(
                                            width: imageSize.width * cropRect.width,
                                            height: imageSize.height * cropRect.height
                                        )
                                        .position(
                                            x: imageSize.width * (cropRect.minX + cropRect.width / 2),
                                            y: imageSize.height * (cropRect.minY + cropRect.height / 2)
                                        )
                                        .blendMode(.destinationOut)
                                )
                        )
                    
                    // Crop rectangle
                    Rectangle()
                        .stroke(Color.white, lineWidth: 3)
                        .background(
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 1)
                                .background(Color.clear)
                        )
                        .frame(
                            width: imageSize.width * cropRect.width,
                            height: imageSize.height * cropRect.height
                        )
                        .position(
                            x: imageSize.width * (cropRect.minX + cropRect.width / 2),
                            y: imageSize.height * (cropRect.minY + cropRect.height / 2)
                        )
                        .scaleEffect(isDragging ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDragging)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let deltaX = value.translation.width / imageSize.width
                                    let deltaY = value.translation.height / imageSize.height
                                    
                                    let newX = max(0, min(1 - cropRect.width, cropRect.minX + deltaX))
                                    let newY = max(0, min(1 - cropRect.height, cropRect.minY + deltaY))
                                    
                                    cropRect = CGRect(
                                        x: newX,
                                        y: newY,
                                        width: cropRect.width,
                                        height: cropRect.height
                                    )
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                    
                    // Corner handles for resizing
                    ForEach(0..<4, id: \.self) { corner in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .position(cornerPosition(for: corner))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        resizeCropRect(corner: corner, translation: value.translation)
                                    }
                            )
                    }
                }
                
                // Crop controls
                VStack {
                    Spacer()
                    HStack {
                        Button("Cancel") {
                            // Reset or dismiss
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        Button("Crop") {
                            cropImage()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func cornerPosition(for corner: Int) -> CGPoint {
        let rect = CGRect(
            x: imageSize.width * cropRect.minX,
            y: imageSize.height * cropRect.minY,
            width: imageSize.width * cropRect.width,
            height: imageSize.height * cropRect.height
        )
        
        switch corner {
        case 0: // Top-left
            return CGPoint(x: rect.minX, y: rect.minY)
        case 1: // Top-right
            return CGPoint(x: rect.maxX, y: rect.minY)
        case 2: // Bottom-left
            return CGPoint(x: rect.minX, y: rect.maxY)
        case 3: // Bottom-right
            return CGPoint(x: rect.maxX, y: rect.maxY)
        default:
            return .zero
        }
    }
    
    private func resizeCropRect(corner: Int, translation: CGSize) {
        let minSize: CGFloat = 0.1 // Minimum 10% of image size
        let deltaX = translation.width / imageSize.width
        let deltaY = translation.height / imageSize.height
        
        var newRect = cropRect
        
        switch corner {
        case 0: // Top-left
            newRect.origin.x = min(cropRect.maxX - minSize, cropRect.minX + deltaX)
            newRect.origin.y = min(cropRect.maxY - minSize, cropRect.minY + deltaY)
            newRect.size.width = cropRect.maxX - newRect.minX
            newRect.size.height = cropRect.maxY - newRect.minY
        case 1: // Top-right
            newRect.origin.y = min(cropRect.maxY - minSize, cropRect.minY + deltaY)
            newRect.size.width = max(minSize, cropRect.width + deltaX)
            newRect.size.height = cropRect.maxY - newRect.minY
        case 2: // Bottom-left
            newRect.origin.x = min(cropRect.maxX - minSize, cropRect.minX + deltaX)
            newRect.size.width = cropRect.maxX - newRect.minX
            newRect.size.height = max(minSize, cropRect.height + deltaY)
        case 3: // Bottom-right
            newRect.size.width = max(minSize, cropRect.width + deltaX)
            newRect.size.height = max(minSize, cropRect.height + deltaY)
        default:
            break
        }
        
        // Ensure the crop rect stays within bounds
        newRect.origin.x = max(0, newRect.origin.x)
        newRect.origin.y = max(0, newRect.origin.y)
        newRect.size.width = min(1 - newRect.origin.x, newRect.size.width)
        newRect.size.height = min(1 - newRect.origin.y, newRect.size.height)
        
        cropRect = newRect
    }
    
    private func cropImage() {
        guard let cgImage = image.cgImage else {
            onCropComplete(image)
            return
        }
        
        let scale = image.scale
        let cropFrame = CGRect(
            x: CGFloat(cgImage.width) * cropRect.minX * scale,
            y: CGFloat(cgImage.height) * cropRect.minY * scale,
            width: CGFloat(cgImage.width) * cropRect.width * scale,
            height: CGFloat(cgImage.height) * cropRect.height * scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropFrame) else {
            onCropComplete(image)
            return
        }
        
        onCropComplete(UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation))
    }
}

struct EditingSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EditingButtonStyle: ButtonStyle {
    let fullWidth: Bool
    let color: Color
    
    init(fullWidth: Bool = false, color: Color = .blue) {
        self.fullWidth = fullWidth
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, fullWidth ? 20 : 16)
            .padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(8)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ImageEditingView(
        originalImage: .constant(UIImage(systemName: "photo")!),
        editedImage: .constant(UIImage(systemName: "photo")!)
    )
}