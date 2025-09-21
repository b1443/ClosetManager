import SwiftUI
import UIKit

struct CameraView: View {
    @EnvironmentObject var closetManager: ClosetManager
    @StateObject private var clothingDetector = ClothingDetector()
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imageSource: ImageSource = .camera
    @State private var detectionResult: ClothingDetectionResult?
    @State private var isAnalyzing = false
    @State private var showingAddItemSheet = false
    @State private var customItemName = ""
    @State private var selectedType: ClothingType = .unknown
    @State private var selectedMaterial: ClothingMaterial = .unknown
    @State private var selectedColor = ""
    
    // Additional garment information
    @State private var selectedBrand = ""
    @State private var selectedSize: ClothingSize? = nil
    @State private var purchasePrice = ""
    @State private var purchaseDate = Date()
    @State private var selectedStore = ""
    @State private var selectedSeason: Season? = nil
    @State private var selectedOccasion: Occasion? = nil
    @State private var notes = ""
    @State private var selectedCondition: Condition = .good
    @State private var tags = ""
    
    @State private var errorMessage: String?
    @State private var showingError = false
    
    enum ImageSource {
        case camera, photoLibrary
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
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
                
                // Image Display
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
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        imageSource = .camera
                        showingImagePicker = true
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
                        imageSource = .photoLibrary
                        showingImagePicker = true
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
                .padding(.horizontal)
                
                // Detection Results
                if let result = detectionResult {
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
                
                Spacer()
                
                // Add to Closet Button
                if selectedImage != nil && detectionResult != nil {
                    Button(action: {
                        setupAddItemSheet()
                        showingAddItemSheet = true
                    }) {
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
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: imageSource == .camera ? .camera : .photoLibrary)
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddItemSheet(
                image: selectedImage,
                detectionResult: detectionResult,
                customItemName: $customItemName,
                selectedType: $selectedType,
                selectedMaterial: $selectedMaterial,
                selectedColor: $selectedColor,
                selectedBrand: $selectedBrand,
                selectedSize: $selectedSize,
                purchasePrice: $purchasePrice,
                purchaseDate: $purchaseDate,
                selectedStore: $selectedStore,
                selectedSeason: $selectedSeason,
                selectedOccasion: $selectedOccasion,
                notes: $notes,
                selectedCondition: $selectedCondition,
                tags: $tags,
                onSave: { item in
                    closetManager.addClothingItem(item)
                    resetForm()
                }
            )
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let newValue = newValue {
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
        
        customItemName = "\(result.color) \(result.material.rawValue) \(result.type.rawValue)"
        selectedType = result.type
        selectedMaterial = result.material
        selectedColor = result.color
    }
    
    private func resetForm() {
        selectedImage = nil
        detectionResult = nil
        customItemName = ""
        selectedType = .unknown
        selectedMaterial = .unknown
        selectedColor = ""
        
        // Reset additional fields
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
}

struct AddItemSheet: View {
    let image: UIImage?
    let detectionResult: ClothingDetectionResult?
    
    @Binding var customItemName: String
    @Binding var selectedType: ClothingType
    @Binding var selectedMaterial: ClothingMaterial
    @Binding var selectedColor: String
    
    // Additional fields
    @Binding var selectedBrand: String
    @Binding var selectedSize: ClothingSize?
    @Binding var purchasePrice: String
    @Binding var purchaseDate: Date
    @Binding var selectedStore: String
    @Binding var selectedSeason: Season?
    @Binding var selectedOccasion: Occasion?
    @Binding var notes: String
    @Binding var selectedCondition: Condition
    @Binding var tags: String
    
    let onSave: (ClothingItem) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Item Name", text: $customItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ClothingType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.rawValue)").tag(type)
                        }
                    }
                    
                    Picker("Material", selection: $selectedMaterial) {
                        ForEach(ClothingMaterial.allCases, id: \.self) { material in
                            Text(material.rawValue).tag(material)
                        }
                    }
                    
                    TextField("Color", text: $selectedColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Brand & Size
                Section(header: Text("Brand & Size")) {
                    TextField("Brand (optional)", text: $selectedBrand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Size", selection: $selectedSize) {
                        Text("Not Specified").tag(nil as ClothingSize?)
                        ForEach(ClothingSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size as ClothingSize?)
                        }
                    }
                }
                
                // Purchase Information
                Section(header: Text("Purchase Information")) {
                    TextField("Price (optional)", text: $purchasePrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    TextField("Store (optional)", text: $selectedStore)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Category & Usage
                Section(header: Text("Category & Usage")) {
                    Picker("Season", selection: $selectedSeason) {
                        Text("Not Specified").tag(nil as Season?)
                        ForEach(Season.allCases, id: \.self) { season in
                            Text("\(season.icon) \(season.rawValue)").tag(season as Season?)
                        }
                    }
                    
                    Picker("Occasion", selection: $selectedOccasion) {
                        Text("Not Specified").tag(nil as Occasion?)
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            Text("\(occasion.icon) \(occasion.rawValue)").tag(occasion as Occasion?)
                        }
                    }
                    
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(Condition.allCases, id: \.self) { condition in
                            Text("\(condition.icon) \(condition.rawValue)").tag(condition)
                        }
                    }
                }
                
                // Notes & Tags
                Section(header: Text("Notes & Tags")) {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    TextField("Tags (comma-separated)", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .help("Example: work, casual, favorite")
                }
                
                // Photo Preview
                if let image = image {
                    Section(header: Text("Photo")) {
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 150)
                                .cornerRadius(10)
                            Spacer()
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
                    let priceValue = Double(purchasePrice.isEmpty ? "0" : purchasePrice)
                    let tagsArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    
                    let item = ClothingItem(
                        name: customItemName.isEmpty ? "Untitled Item" : customItemName,
                        type: selectedType,
                        material: selectedMaterial,
                        color: selectedColor.isEmpty ? "Unknown" : selectedColor,
                        image: image,
                        brand: selectedBrand.isEmpty ? nil : selectedBrand,
                        size: selectedSize,
                        purchasePrice: priceValue,
                        purchaseDate: purchaseDate,
                        store: selectedStore.isEmpty ? nil : selectedStore,
                        season: selectedSeason,
                        occasion: selectedOccasion,
                        notes: notes.isEmpty ? nil : notes,
                        condition: selectedCondition,
                        tags: tagsArray
                    )
                    onSave(item)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(customItemName.isEmpty)
            )
        }
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

#Preview {
    CameraView()
        .environmentObject(ClosetManager())
}
