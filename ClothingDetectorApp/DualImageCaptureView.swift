import SwiftUI
import PhotosUI

struct DualImageCaptureView: View {
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageType: ImageType = .front
    @State private var showingImageEditor = false
    @State private var imageToEdit: UIImage?
    @State private var editedImage: UIImage?
    @State private var showingActionSheet = false
    @State private var showingPhotoPicker = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var currentStep = 1
    @State private var showingCompletionAlert = false
    
    enum ImageType {
        case front, back
        
        var title: String {
            switch self {
            case .front: return "Front View"
            case .back: return "Back View"
            }
        }
        
        var description: String {
            switch self {
            case .front: return "Capture the front of the clothing item"
            case .back: return "Capture the back of the clothing item"
            }
        }
        
        var icon: String {
            switch self {
            case .front: return "camera.fill"
            case .back: return "camera.rotate.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Indicator
                ProgressIndicatorView(currentStep: currentStep, totalSteps: 2)
                
                // Instructions
                VStack(spacing: 8) {
                    Text("Capture Both Views")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Take or select photos of both the front and back of your clothing item for better organization.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Image Capture Cards
                VStack(spacing: 16) {
                    ImageCaptureCard(
                        imageType: .front,
                        image: frontImage,
                        isCompleted: frontImage != nil,
                        onTap: { 
                            selectedImageType = .front
                            showImageSourceOptions()
                        },
                        onEdit: {
                            if let image = frontImage {
                                selectedImageType = .front
                                editImage(image)
                            }
                        }
                    )
                    
                    ImageCaptureCard(
                        imageType: .back,
                        image: backImage,
                        isCompleted: backImage != nil,
                        onTap: {
                            selectedImageType = .back
                            showImageSourceOptions()
                        },
                        onEdit: {
                            if let image = backImage {
                                selectedImageType = .back
                                editImage(image)
                            }
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if frontImage != nil && backImage != nil {
                        Button("Both Images Captured!") {
                            showingCompletionAlert = true
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .green))
                        .disabled(true)
                    } else {
                        VStack(spacing: 8) {
                            if frontImage == nil {
                                Button("Capture Front View First") {
                                    selectedImageType = .front
                                    showImageSourceOptions()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else if backImage == nil {
                                Button("Now Capture Back View") {
                                    selectedImageType = .back
                                    showImageSourceOptions()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            
                            Button("Skip Back View") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Capture Images")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(frontImage == nil)
            )
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Add \(selectedImageType.title)"),
                buttons: [
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text("Choose from Photos")) {
                        showingPhotoPicker = true
                    },
                    .cancel()
                ]
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(image: imageBinding(for: selectedImageType))
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $photoPickerItems,
            maxSelectionCount: 1,
            matching: .images
        )
        .sheet(isPresented: $showingImageEditor) {
            if let imageToEdit = imageToEdit {
                ImageEditingView(
                    originalImage: .constant(imageToEdit),
                    editedImage: Binding(
                        get: { editedImage ?? imageToEdit },
                        set: { newValue in
                            editedImage = newValue
                            setImage(newValue, for: selectedImageType)
                        }
                    )
                )
            }
        }
        .alert("Success!", isPresented: $showingCompletionAlert) {
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Both front and back images have been captured successfully!")
        }
        .onChange(of: photoPickerItems) { _, newItems in
            guard let item = newItems.first else { return }
            
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            setImage(uiImage, for: selectedImageType)
                            updateProgress()
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
            photoPickerItems = []
        }
        .onChange(of: frontImage) { _, _ in updateProgress() }
        .onChange(of: backImage) { _, _ in updateProgress() }
    }
    
    private func showImageSourceOptions() {
        showingActionSheet = true
    }
    
    private func editImage(_ image: UIImage) {
        imageToEdit = image
        editedImage = image
        showingImageEditor = true
    }
    
    private func imageBinding(for type: ImageType) -> Binding<UIImage?> {
        switch type {
        case .front:
            return $frontImage
        case .back:
            return $backImage
        }
    }
    
    private func setImage(_ image: UIImage, for type: ImageType) {
        switch type {
        case .front:
            frontImage = image
        case .back:
            backImage = image
        }
    }
    
    private func updateProgress() {
        withAnimation {
            if frontImage != nil && backImage != nil {
                currentStep = 2
            } else if frontImage != nil || backImage != nil {
                currentStep = 1
            } else {
                currentStep = 1
            }
        }
    }
}

struct ImageCaptureCard: View {
    let imageType: DualImageCaptureView.ImageType
    let image: UIImage?
    let isCompleted: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack {
            if let image = image {
                // Image Preview
                VStack(spacing: 12) {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                        
                        // Success overlay
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .font(.title2)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    
                    VStack(spacing: 8) {
                        Text(imageType.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            Button("Retake") {
                                onTap()
                            }
                            .buttonStyle(SecondaryButtonStyle(compact: true))
                            
                            Button("Edit") {
                                onEdit()
                            }
                            .buttonStyle(PrimaryButtonStyle(compact: true))
                        }
                    }
                }
            } else {
                // Empty State
                Button(action: onTap) {
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                            
                            VStack(spacing: 12) {
                                Image(systemName: imageType.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                
                                VStack(spacing: 4) {
                                    Text(imageType.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(imageType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        
                        Text("Tap to Add Image")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color(.systemGray4))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut, value: currentStep)
                    
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color(.systemGray4))
                            .frame(width: 30, height: 2)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    let compact: Bool
    
    init(color: Color = .blue, compact: Bool = false) {
        self.color = color
        self.compact = compact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, compact ? 16 : 24)
            .padding(.vertical, compact ? 8 : 12)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(compact ? 8 : 12)
            .frame(maxWidth: compact ? nil : .infinity)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let compact: Bool
    
    init(compact: Bool = false) {
        self.compact = compact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 16, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, compact ? 16 : 24)
            .padding(.vertical, compact ? 8 : 12)
            .background(Color.blue.opacity(configuration.isPressed ? 0.2 : 0.1))
            .cornerRadius(compact ? 8 : 12)
            .frame(maxWidth: compact ? nil : .infinity)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    DualImageCaptureView(
        frontImage: .constant(nil),
        backImage: .constant(nil)
    )
}