# Developer Guide - ClothingDetectorApp

## Quick Start

1. **Open the project**:
   ```bash
   ./setup.sh
   ```
   or manually:
   ```bash
   open ClothingDetectorApp.xcodeproj
   ```

2. **Configure signing**:
   - In Xcode, select the project file
   - Go to "Signing & Capabilities"
   - Select your Apple Developer account
   - Update bundle identifier if needed

3. **Build and run**:
   - Choose target: iPhone simulator or physical device
   - Press `Cmd+R` to build and run

## Project Structure

```
ClothingDetectorApp/
├── ClothingDetectorApp/
│   ├── ClothingDetectorAppApp.swift     # App entry point
│   ├── ContentView.swift                # Main tab view
│   ├── CameraView.swift                 # Camera capture & detection
│   ├── ClosetView.swift                 # Closet management UI
│   ├── ClothingItem.swift               # Data models
│   ├── ClothingDetector.swift           # AI detection logic
│   ├── ClosetManager.swift              # Data persistence
│   ├── ImagePicker.swift                # Camera/photo utilities
│   └── Assets.xcassets/                 # App icons & images
├── README.md                            # Full documentation
├── DEVELOPER_GUIDE.md                   # This file
└── setup.sh                            # Quick setup script
```

## Key Features Implemented

### ✅ Camera Integration
- Photo capture from camera
- Photo selection from library
- Image editing capabilities
- Real-time preview

### ✅ AI Detection (Demo Version)
- Clothing type detection (basic heuristics)
- Color analysis (dominant color extraction)
- Material prediction (placeholder logic)
- Confidence scoring

### ✅ Digital Closet
- Store clothing items with metadata
- Search and filter functionality
- Statistics and analytics
- Data export (CSV format)

### ✅ Data Management
- Local persistence using UserDefaults
- Image compression and storage
- CRUD operations for clothing items

## Current AI Implementation

The app currently uses **placeholder AI logic** for demonstration:

1. **Type Detection**: Basic shape analysis (aspect ratio)
2. **Color Detection**: Dominant color extraction from pixels
3. **Material Detection**: Random selection from common materials

## Upgrading to Production AI

### Step 1: Prepare Training Data
```python
# Example dataset structure
datasets/
├── clothing_types/
│   ├── shirts/
│   ├── pants/
│   ├── dresses/
│   └── jackets/
├── materials/
│   ├── cotton/
│   ├── wool/
│   ├── silk/
│   └── denim/
└── colors/
    ├── red/
    ├── blue/
    └── black/
```

### Step 2: Train Core ML Models
```python
# Using Create ML
import CreateML

# Train clothing type classifier
let clothingData = try MLImageClassifier.DataSource.labeledDirectories(at: dataURL)
let clothingClassifier = try MLImageClassifier(trainingData: clothingData)

# Save model
try clothingClassifier.write(to: URL(fileURLWithPath: "ClothingTypeClassifier.mlmodel"))
```

### Step 3: Integration
1. Add `.mlmodel` files to Xcode project
2. Update `ClothingDetector.swift`:
   ```swift
   private func createClothingClassificationModel() -> MLModel {
       guard let modelURL = Bundle.main.url(forResource: "ClothingTypeClassifier", withExtension: "mlmodelc"),
             let model = try? MLModel(contentsOf: modelURL) else {
           fatalError("Failed to load model")
       }
       return model
   }
   ```

## Testing

### Simulator Testing
- Basic UI functionality
- Data persistence
- Search and filtering
- Photo library access

### Device Testing (Recommended)
- Camera functionality
- AI detection performance
- Real photo analysis
- Performance optimization

## Common Development Tasks

### Adding New Clothing Types
1. Update `ClothingType` enum in `ClothingItem.swift`
2. Add icon mapping in the `icon` property
3. Update detection logic in `ClothingDetector.swift`

### Adding New Materials
1. Update `ClothingMaterial` enum in `ClothingItem.swift`
2. Update material detection in `predictMaterialFromTexture()`

### Improving Color Detection
1. Enhance `extractDominantColor()` in `ClothingDetector.swift`
2. Add more sophisticated color naming in `colorNameFromRGB()`

### UI Customization
- Modify `CameraView.swift` for camera interface
- Update `ClosetView.swift` for closet browsing
- Customize colors in `Assets.xcassets`

## Performance Tips

1. **Image Processing**:
   - Resize images before AI processing
   - Use background queues for heavy operations
   - Implement image caching for better performance

2. **Data Management**:
   - Consider Core Data for large collections
   - Implement pagination for long lists
   - Use lazy loading for images

3. **AI Optimization**:
   - Use smaller model sizes for mobile
   - Implement model quantization
   - Cache prediction results

## Deployment Checklist

- [ ] Replace placeholder AI with trained models
- [ ] Test on multiple device sizes
- [ ] Optimize image storage and compression
- [ ] Add error handling for edge cases
- [ ] Implement proper loading states
- [ ] Add accessibility features
- [ ] Test camera permissions flow
- [ ] Validate data export functionality

## Troubleshooting

### Build Errors
```bash
# Clean build folder
Cmd+Shift+K in Xcode

# Or via command line
cd ~/ClothingDetectorApp
xcodebuild clean
```

### Camera Issues
- Test on physical device (simulator has limited camera support)
- Check camera permissions in device Settings
- Verify Info.plist camera usage description

### Model Loading Errors
- Ensure `.mlmodel` files are added to Xcode target
- Check model compatibility with iOS version
- Verify model file paths and names

## Next Steps

1. **Train Production Models**: Use fashion datasets to train actual AI models
2. **Add Advanced Features**: Outfit suggestions, style recommendations
3. **Improve UI/UX**: Better animations, improved layouts
4. **Add Social Features**: Sharing, community, style challenges
5. **Performance Optimization**: Faster processing, better storage

## Resources

- [Apple Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Create ML Tutorials](https://developer.apple.com/documentation/createml)
- [Fashion-MNIST Dataset](https://github.com/zalandoresearch/fashion-mnist)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

Happy coding! 🧥✨
