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
                        // Rotate Section
                        EditingSectionView(title: "Rotate", icon: "rotate.right") {
                            VStack {
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let editedImage = self.processImage(self.originalImage)
            
            DispatchQueue.main.async {
                self.currentImage = editedImage
                self.isProcessing = false
            }
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        var processedImage = ciImage
        
        // Apply filters
        if let brightnessFilter = CIFilter(name: "CIColorControls") {
            brightnessFilter.setValue(processedImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
            brightnessFilter.setValue(contrast, forKey: kCIInputContrastKey)
            brightnessFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            
            if let outputImage = brightnessFilter.outputImage {
                processedImage = outputImage
            }
        }
        
        // Apply rotation
        if rotationAngle != 0 {
            let radians = rotationAngle * .pi / 180
            processedImage = processedImage.transformed(by: CGAffineTransform(rotationAngle: radians))
        }
        
        // Convert back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func resetToOriginal() {
        withAnimation {
            rotationAngle = 0
            brightness = 0
            contrast = 1
            saturation = 1
            currentImage = originalImage
        }
    }
}

struct CropView: View {
    let image: UIImage
    @Binding var cropRect: CGRect
    let onCropComplete: (UIImage) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var lastDragValue = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Crop overlay
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .background(
                        Rectangle()
                            .fill(Color.clear)
                            .border(Color.blue, width: 2)
                    )
                    .frame(
                        width: geometry.size.width * cropRect.width,
                        height: geometry.size.height * cropRect.height
                    )
                    .position(
                        x: geometry.size.width * (cropRect.minX + cropRect.width / 2),
                        y: geometry.size.height * (cropRect.minY + cropRect.height / 2)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newX = cropRect.minX + (value.translation.width - lastDragValue.width) / geometry.size.width
                                let newY = cropRect.minY + (value.translation.height - lastDragValue.height) / geometry.size.height
                                
                                cropRect = CGRect(
                                    x: max(0, min(1 - cropRect.width, newX)),
                                    y: max(0, min(1 - cropRect.height, newY)),
                                    width: cropRect.width,
                                    height: cropRect.height
                                )
                            }
                            .onEnded { value in
                                lastDragValue = value.translation
                            }
                    )
                
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
    
    private func cropImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(
            width: image.size.width * cropRect.width,
            height: image.size.height * cropRect.height
        ))
        
        let croppedImage = renderer.image { context in
            let drawRect = CGRect(
                x: -image.size.width * cropRect.minX,
                y: -image.size.height * cropRect.minY,
                width: image.size.width,
                height: image.size.height
            )
            image.draw(in: drawRect)
        }
        
        onCropComplete(croppedImage)
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