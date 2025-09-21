# ClothingDetectorApp

A sophisticated iOS app that uses AI to detect clothing items from photos and organize them in a digital closet.

## Features

- **AI-Powered Detection**: Uses Core ML and Vision framework to identify clothing type, material, and color
- **Camera Integration**: Take photos directly in the app or select from photo library
- **Digital Closet**: Store and organize your clothing items with metadata
- **Smart Search**: Search through your closet by name, type, material, or color
- **Statistics**: View analytics about your clothing collection
- **Data Export**: Export your closet data as CSV

## Architecture

### Core Components

1. **ClothingDetector**: AI-powered analysis using Vision and Core ML
2. **ClosetManager**: Data persistence and management
3. **CameraView**: Photo capture and image processing
4. **ClosetView**: Browse and manage clothing items

### Data Models

- **ClothingItem**: Core data model with type, material, color, and image
- **ClothingType**: Comprehensive enum of clothing categories
- **ClothingMaterial**: Fabric and material classification

## AI/ML Implementation

### Current Implementation

The app currently uses a simplified approach for demonstration:

1. **Type Detection**: Uses Vision framework with placeholder logic
2. **Color Analysis**: Dominant color extraction from pixel data
3. **Material Prediction**: Basic texture analysis (placeholder)

### Production Improvements

To make this production-ready, you'll need to:

1. **Train Custom Models**:
   ```bash
   # Use Create ML or TensorFlow to train models on clothing datasets
   # Datasets: Fashion-MNIST, DeepFashion, Clothing1M
   ```

2. **Core ML Model Integration**:
   - Replace placeholder model in `ClothingDetector.swift`
   - Add actual `.mlmodel` files to the project
   - Train separate models for type, material, and advanced color analysis

3. **Dataset Recommendations**:
   - **Fashion-MNIST**: Basic clothing type classification
   - **DeepFashion**: Advanced fashion attribute detection
   - **Clothing1M**: Large-scale clothing categorization
   - **Fashion-Gen**: Material and texture classification

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- macOS Monterey+

### Installation

1. **Clone the project**:
   ```bash
   cd ~/ClothingDetectorApp
   ```

2. **Open in Xcode**:
   ```bash
   open ClothingDetectorApp.xcodeproj
   ```

3. **Configure signing**:
   - Select your development team in project settings
   - Update bundle identifier if needed

4. **Build and run**:
   - Select target device or simulator
   - Press Cmd+R to build and run

### Camera Permissions

The app requires camera access for photo capture. The usage description is already configured in the project settings.

## ML Model Integration

### Adding Your Own Models

1. **Prepare your Core ML model**:
   ```python
   # Example using Core ML Tools
   import coremltools as ct
   
   # Convert your trained model to Core ML format
   model = ct.convert(your_trained_model)
   model.save('ClothingClassifier.mlmodel')
   ```

2. **Add to Xcode project**:
   - Drag `.mlmodel` file into Xcode project
   - Ensure it's added to target

3. **Update ClothingDetector.swift**:
   ```swift
   private func createClothingClassificationModel() -> MLModel {
       guard let modelURL = Bundle.main.url(forResource: "YourModel", withExtension: "mlmodelc"),
             let model = try? MLModel(contentsOf: modelURL) else {
           fatalError("Failed to load model")
       }
       return model
   }
   ```

### Model Training Resources

1. **Create ML** (Recommended for iOS):
   ```swift
   // Use Create ML for on-device training
   import CreateML
   
   let classifier = try MLImageClassifier(trainingData: trainingData)
   try classifier.write(to: URL(fileURLWithPath: "ClothingClassifier.mlmodel"))
   ```

2. **TensorFlow + Core ML Tools**:
   ```python
   import tensorflow as tf
   import coremltools as ct
   
   # Train TensorFlow model
   model = tf.keras.Sequential([...])
   model.compile(...)
   model.fit(...)
   
   # Convert to Core ML
   coreml_model = ct.convert(model)
   coreml_model.save('ClothingClassifier.mlmodel')
   ```

## Features in Detail

### Camera & Detection

- Real-time camera preview
- Photo capture with editing
- AI analysis with confidence scores
- Manual correction capabilities

### Digital Closet

- Grid and list view options
- Filtering by type, material, color
- Search functionality
- Detailed item views

### Data Management

- Local storage using UserDefaults
- Image compression for storage efficiency
- CSV export for backup
- Statistics and analytics

## Future Enhancements

1. **Advanced ML Features**:
   - Style recognition
   - Brand detection
   - Outfit suggestion algorithms
   - Seasonal recommendations

2. **Social Features**:
   - Share outfits
   - Fashion community
   - Style challenges

3. **Smart Organization**:
   - Automatic outfit creation
   - Weather-based suggestions
   - Wardrobe gap analysis

## Troubleshooting

### Common Issues

1. **Model Loading Errors**:
   - Ensure `.mlmodel` files are in bundle
   - Check model compatibility with iOS version

2. **Camera Not Working**:
   - Verify camera permissions
   - Test on physical device (simulator has limitations)

3. **Build Errors**:
   - Clean build folder (Cmd+Shift+K)
   - Check Swift version compatibility

### Performance Tips

- Image compression for faster processing
- Background processing for ML inference
- Efficient data structures for large collections

## Contributing

1. Fork the repository
2. Create feature branch
3. Implement improvements
4. Add tests if applicable
5. Submit pull request

## License

This project is for educational purposes. Please ensure you have appropriate licenses for any datasets or pre-trained models you use.

## Contact

For questions about implementation or AI model integration, please refer to Apple's Core ML documentation and Create ML tutorials.
