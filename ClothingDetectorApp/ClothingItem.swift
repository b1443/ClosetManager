import Foundation
import UIKit

struct ClothingItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: ClothingType
    let material: ClothingMaterial
    let color: String
    let dateAdded: Date
    let imageData: Data?
    
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    init(name: String, type: ClothingType, material: ClothingMaterial, color: String, image: UIImage? = nil) {
        self.name = name
        self.type = type
        self.material = material
        self.color = color
        self.dateAdded = Date()
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }
}

enum ClothingType: String, CaseIterable, Codable {
    case shirt = "Shirt"
    case pants = "Pants"
    case jacket = "Jacket"
    case dress = "Dress"
    case skirt = "Skirt"
    case shorts = "Shorts"
    case sweater = "Sweater"
    case hoodie = "Hoodie"
    case jeans = "Jeans"
    case blazer = "Blazer"
    case tShirt = "T-Shirt"
    case blouse = "Blouse"
    case coat = "Coat"
    case vest = "Vest"
    case cardigan = "Cardigan"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .shirt, .tShirt, .blouse:
            return "👔"
        case .pants, .jeans:
            return "👖"
        case .jacket, .blazer, .coat:
            return "🧥"
        case .dress:
            return "👗"
        case .skirt:
            return "🩱"
        case .shorts:
            return "🩳"
        case .sweater, .hoodie, .cardigan:
            return "🧶"
        case .vest:
            return "🦺"
        case .unknown:
            return "👕"
        }
    }
}

enum ClothingMaterial: String, CaseIterable, Codable {
    case cotton = "Cotton"
    case polyester = "Polyester"
    case wool = "Wool"
    case silk = "Silk"
    case linen = "Linen"
    case denim = "Denim"
    case leather = "Leather"
    case cashmere = "Cashmere"
    case rayon = "Rayon"
    case nylon = "Nylon"
    case spandex = "Spandex"
    case acrylic = "Acrylic"
    case velvet = "Velvet"
    case corduroy = "Corduroy"
    case flannel = "Flannel"
    case jersey = "Jersey"
    case unknown = "Unknown"
}
