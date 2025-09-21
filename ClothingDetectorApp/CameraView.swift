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
                        Color.black.opacity(0.3)
                            .cornerRadius(15)
                        
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing clothing...")
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                                .padding(.top)
                        }
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Detection Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Label("Type: \(result.type.rawValue)", systemImage: "tag")
                                Label("Material: \(result.material.rawValue)", systemImage: "textformat")
                                Label("Color: \(result.color)", systemImage: "paintbrush")
                                Label("Confidence: \(Int(result.confidence * 100))%", systemImage: "gauge")
                            }
                            .font(.subheadline)
                            
                            Spacer()
                            
                            Text(result.type.icon)
                                .font(.system(size: 40))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
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
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        clothingDetector.analyzeClothing(image: image) { result in
            DispatchQueue.main.async {
                self.detectionResult = result
                self.isAnalyzing = false
            }
        }
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
    }
}

struct AddItemSheet: View {
    let image: UIImage?
    let detectionResult: ClothingDetectionResult?
    
    @Binding var customItemName: String
    @Binding var selectedType: ClothingType
    @Binding var selectedMaterial: ClothingMaterial
    @Binding var selectedColor: String
    
    let onSave: (ClothingItem) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $customItemName)
                    
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
                }
                
                if let image = image {
                    Section(header: Text("Photo")) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
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
                    let item = ClothingItem(
                        name: customItemName.isEmpty ? "Untitled Item" : customItemName,
                        type: selectedType,
                        material: selectedMaterial,
                        color: selectedColor.isEmpty ? "Unknown" : selectedColor,
                        image: image
                    )
                    onSave(item)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(customItemName.isEmpty)
            )
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(ClosetManager())
}
