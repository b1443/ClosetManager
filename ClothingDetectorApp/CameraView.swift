import SwiftUI
import UIKit

class ItemFormData: ObservableObject {
    @Published var customItemName = ""
    @Published var selectedType: ClothingType = .unknown
    @Published var selectedMaterial: ClothingMaterial = .unknown
    @Published var selectedColor = ""
    @Published var selectedBrand = ""
    @Published var selectedSize: ClothingSize? = nil
    @Published var purchasePrice = ""
    @Published var purchaseDate = Date()
    @Published var selectedStore = ""
    @Published var selectedSeason: Season? = nil
    @Published var selectedOccasion: Occasion? = nil
    @Published var notes = ""
    @Published var selectedCondition: Condition = .good
    @Published var tags = ""
    
    func reset() {
        customItemName = ""
        selectedType = .unknown
        selectedMaterial = .unknown
        selectedColor = ""
        selectedBrand = ""
        selectedSize = nil
        purchasePrice = ""
        purchaseDate = Date()
        selectedStore = ""
        selectedSeason = nil
        selectedOccasion = nil
        notes = ""
        selectedCondition = .good
        tags = ""
    }
    
    func setupFrom(result: ClothingDetectionResult) {
        customItemName = "\(result.color) \(result.material.rawValue) \(result.type.rawValue)"
        selectedType = result.type
        selectedMaterial = result.material
        selectedColor = result.color
    }
}

struct CameraView: View {
    @EnvironmentObject var closetManager: ClosetManager
    @StateObject private var clothingDetector = ClothingDetector()
    
    // Core image state
    @State private var selectedImage: UIImage?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var detectionResult: ClothingDetectionResult?
    @State private var isAnalyzing = false
    
    // UI state
    @State private var showingCameraPicker = false
    @State private var showingPhotoLibraryPicker = false
    @State private var showingDualImageCapture = false
    @State private var showingAddItemSheet = false
    @State private var showingImageEditor = false
    @State private var showingError = false
    
    // Form data - consolidated into a single state object would be better
    @StateObject private var itemForm = ItemFormData()
    
    // Error handling
    @State private var errorMessage: String?
    @State private var imageToEdit: UIImage?
    @State private var editedImage: UIImage?
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                ImageDisplayView(selectedImage: selectedImage, isAnalyzing: isAnalyzing)
            
                ActionButtonsView(
                    showingDualImageCapture: $showingDualImageCapture,
                    showingCameraPicker: $showingCameraPicker,
                    showingPhotoLibraryPicker: $showingPhotoLibraryPicker
                )
                
                editImageButton
                
                if let result = detectionResult {
                    DetectionResultsView(result: result)
                }
            
                if frontImage != nil || backImage != nil {
                    DualImagesDisplayView(frontImage: frontImage, backImage: backImage)
                }
            
                if shouldShowAddButton {
                    AddToClosetButton {
                        setupAddItemSheet()
                        showingAddItemSheet = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var editImageButton: some View {
        if selectedImage != nil && detectionResult == nil && !isAnalyzing {
            Button(action: {
                imageToEdit = selectedImage
                showingImageEditor = true
            }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                    Text("Edit Image")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var shouldShowAddButton: Bool {
        (selectedImage != nil && detectionResult != nil) || frontImage != nil
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Camera")
                .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCameraPicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingPhotoLibraryPicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingDualImageCapture) {
            DualImageCaptureView(
                frontImage: $frontImage,
                backImage: $backImage
            )
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddItemSheet(
                image: selectedImage,
                frontImage: frontImage,
                backImage: backImage,
                formData: itemForm,
                onSave: { item in
                    closetManager.addClothingItem(item)
                    resetForm()
                }
            )
        }
        .sheet(isPresented: $showingImageEditor) {
            if let imageToEdit = imageToEdit {
                ImageEditingViewWrapper(
                    originalImage: imageToEdit,
                    onComplete: { edited in
                        if let edited = edited {
                            selectedImage = edited
                            analyzeImage(edited)
                        }
                        showingImageEditor = false
                        self.imageToEdit = nil
                        editedImage = nil
                    }
                )
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let newValue = newValue {
                analyzeImage(newValue)
            }
        }
        .onChange(of: frontImage) { oldValue, newValue in
            if let newValue = newValue {
                // Prioritize front image for AI analysis
                selectedImage = newValue
                analyzeImage(newValue)
            }
        }
        .alert("Analysis Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
            Button("Retry") {
                showingError = false
                if let image = selectedImage {
                    analyzeImage(image)
                }
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isAnalyzing = true
        
        // Timeout for analysis (15 seconds)
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                self.showError("Analysis timed out. Please try again.")
            }
        }
        
        clothingDetector.analyzeClothing(image: image) { result in
            DispatchQueue.main.async {
                timeoutTimer.invalidate()
                self.isAnalyzing = false
                
                // Check if analysis was successful
                if result.confidence > 0.1 {
                    self.detectionResult = result
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                } else {
                    self.showError("Could not analyze this image. Please try a clearer photo of clothing.")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        
        // Error haptic feedback
        let errorFeedback = UINotificationFeedbackGenerator()
        errorFeedback.notificationOccurred(.error)
    }
    
    private func setupAddItemSheet() {
        guard let result = detectionResult else { return }
        itemForm.setupFrom(result: result)
    }
    
    private func resetForm() {
        selectedImage = nil
        frontImage = nil
        backImage = nil
        detectionResult = nil
        itemForm.reset()
    }
}

struct AddItemSheet: View {
    let image: UIImage?
    let frontImage: UIImage?
    let backImage: UIImage?
    @ObservedObject var formData: ItemFormData
    
    let onSave: (ClothingItem) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Item Name", text: $formData.customItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Type", selection: $formData.selectedType) {
                        ForEach(ClothingType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.rawValue)").tag(type)
                        }
                    }
                    
                    Picker("Material", selection: $formData.selectedMaterial) {
                        ForEach(ClothingMaterial.allCases, id: \.self) { material in
                            Text(material.rawValue).tag(material)
                        }
                    }
                    
                    TextField("Color", text: $formData.selectedColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Brand & Size
                Section(header: Text("Brand & Size")) {
                    TextField("Brand (optional)", text: $formData.selectedBrand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Size", selection: $formData.selectedSize) {
                        Text("Not Specified").tag(nil as ClothingSize?)
                        ForEach(ClothingSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size as ClothingSize?)
                        }
                    }
                }
                
                // Purchase Information
                Section(header: Text("Purchase Information")) {
                    TextField("Price (optional)", text: $formData.purchasePrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Purchase Date", selection: $formData.purchaseDate, displayedComponents: .date)
                    
                    TextField("Store (optional)", text: $formData.selectedStore)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Category & Usage
                Section(header: Text("Category & Usage")) {
                    Picker("Season", selection: $formData.selectedSeason) {
                        Text("Not Specified").tag(nil as Season?)
                        ForEach(Season.allCases, id: \.self) { season in
                            Text("\(season.icon) \(season.rawValue)").tag(season as Season?)
                        }
                    }
                    
                    Picker("Occasion", selection: $formData.selectedOccasion) {
                        Text("Not Specified").tag(nil as Occasion?)
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            Text("\(occasion.icon) \(occasion.rawValue)").tag(occasion as Occasion?)
                        }
                    }
                    
                    Picker("Condition", selection: $formData.selectedCondition) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            Text("\(condition.icon) \(condition.rawValue)").tag(condition)
                        }
                    }
                }
                
                // Notes & Tags
                Section(header: Text("Notes & Tags")) {
                    TextField("Notes (optional)", text: $formData.notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    TextField("Tags (comma-separated)", text: $formData.tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .help("Example: work, casual, favorite")
                }
                
                // Photo Preview
                if frontImage != nil || backImage != nil || image != nil {
                    Section(header: Text("Photos")) {
                        HStack(spacing: 12) {
                            if let front = frontImage ?? image {
                                Image(uiImage: front)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 120)
                                    .cornerRadius(10)
                            }
                            if let back = backImage {
                                Image(uiImage: back)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 120)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let item = createClothingItem()
                    onSave(item)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(formData.customItemName.isEmpty)
            )
        }
    }
    
    private func createClothingItem() -> ClothingItem {
        let priceValue = Double(formData.purchasePrice) ?? 0
        let tagsArray = formData.tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        return ClothingItem(
            name: formData.customItemName.isEmpty ? "Untitled Item" : formData.customItemName,
            type: formData.selectedType,
            material: formData.selectedMaterial,
            color: formData.selectedColor.isEmpty ? "Unknown" : formData.selectedColor,
            frontImage: frontImage ?? image,
            backImage: backImage,
            brand: formData.selectedBrand.isEmpty ? nil : formData.selectedBrand,
            size: formData.selectedSize,
            purchasePrice: priceValue,
            purchaseDate: formData.purchaseDate,
            store: formData.selectedStore.isEmpty ? nil : formData.selectedStore,
            season: formData.selectedSeason,
            occasion: formData.selectedOccasion,
            notes: formData.notes.isEmpty ? nil : formData.notes,
            condition: formData.selectedCondition,
            tags: tagsArray
        )
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let icon: String
    let confidence: Float
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text("\(title):")
                .fontWeight(.medium)
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Spacer()
        }
        .font(.subheadline)
    }
}

struct ConfidenceIndicator: View {
    let confidence: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(confidence > Float(index) * 0.2 ? .green : .gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Helper Views
struct HeaderView: View {
    var body: some View {
        VStack {
            Text("Add New Clothing")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Take a photo or select from library to detect clothing details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
}

struct ImageDisplayView: View {
    let selectedImage: UIImage?
    let isAnalyzing: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
                .frame(height: 300)
                .overlay(
                    Group {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                        } else {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No image selected")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
            
            if isAnalyzing {
                Color.black.opacity(0.4)
                    .cornerRadius(15)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.8)
                    
                    VStack(spacing: 4) {
                        Text("Analyzing clothing...")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .font(.headline)
                        
                        Text("Using AI to detect type, material & color")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal)
    }
}

struct ActionButtonsView: View {
    @Binding var showingDualImageCapture: Bool
    @Binding var showingCameraPicker: Bool
    @Binding var showingPhotoLibraryPicker: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Dual Image Capture
            Button(action: {
                showingDualImageCapture = true
            }) {
                HStack {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Capture Front & Back")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Recommended for best organization")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    showingCameraPicker = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Camera")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingPhotoLibraryPicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Photos")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct DetectionResultsView: View {
    let result: ClothingDetectionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Analysis Complete")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                ResultRow(title: "Type", value: result.type.rawValue, icon: "tag", confidence: result.confidence)
                ResultRow(title: "Material", value: result.material.rawValue, icon: "textformat", confidence: result.confidence)
                ResultRow(title: "Color", value: result.color, icon: "paintbrush", confidence: result.confidence)
                
                // Confidence indicator
                HStack {
                    Image(systemName: "gauge")
                        .foregroundColor(.blue)
                    Text("Confidence: \(Int(result.confidence * 100))%")
                        .fontWeight(.medium)
                    Spacer()
                    ConfidenceIndicator(confidence: result.confidence)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6).opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
}

struct DualImagesDisplayView: View {
    let frontImage: UIImage?
    let backImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Captured Images")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 16) {
                // Front Image
                VStack {
                    if let frontImage = frontImage {
                        Image(uiImage: frontImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .font(.caption)
                                    .offset(x: 45, y: -45)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Text("Front")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    Text("Front View")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                // Back Image
                VStack {
                    if let backImage = backImage {
                        Image(uiImage: backImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .font(.caption)
                                    .offset(x: 45, y: -45)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera.rotate")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Text("Back")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    Text("Back View")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6).opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AddToClosetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Add to Closet")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

struct ImageEditingViewWrapper: View {
    let originalImage: UIImage
    let onComplete: (UIImage?) -> Void
    
    @State private var workingImage: UIImage
    @State private var editedResult: UIImage
    
    init(originalImage: UIImage, onComplete: @escaping (UIImage?) -> Void) {
        self.originalImage = originalImage
        self.onComplete = onComplete
        self._workingImage = State(initialValue: originalImage)
        self._editedResult = State(initialValue: originalImage)
    }
    
    var body: some View {
        ImageEditingView(
            originalImage: $workingImage,
            editedImage: $editedResult
        )
        .onDisappear {
            // When the editing view is dismissed, pass back the result
            onComplete(editedResult != originalImage ? editedResult : nil)
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(ClosetManager())
}
