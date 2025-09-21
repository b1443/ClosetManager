#!/bin/bash

echo "🧥 ClothingDetectorApp Setup Script"
echo "=================================="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Xcode found"

# Check Xcode version
xcode_version=$(xcodebuild -version | head -n1)
echo "📱 $xcode_version"

# Open the project
echo "🚀 Opening ClothingDetectorApp in Xcode..."
open ClothingDetectorApp.xcodeproj

echo ""
echo "📋 Next Steps:"
echo "1. Select your development team in project settings"
echo "2. Choose a target device (iPhone simulator or physical device)"
echo "3. Press Cmd+R to build and run"
echo ""
echo "💡 Tips:"
echo "- Test camera functionality on a physical device"
echo "- The AI detection is currently using placeholder logic"
echo "- Check README.md for ML model integration instructions"
echo ""
echo "✨ Happy coding!"
