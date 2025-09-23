import Foundation
import UIKit

struct ClothingItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: ClothingType
    let material: ClothingMaterial
    let color: String
    let dateAdded: Date
    let frontImageData: Data?
    let backImageData: Data?
    
    // Additional garment information
    let brand: String?
    let size: ClothingSize?
    let purchasePrice: Double?
    let purchaseDate: Date?
    let store: String?
    let season: Season?
    let occasion: Occasion?
    let notes: String?
    let condition: Condition
    let tags: [String]
    
    // Computed properties for images
    var frontImage: UIImage? {
        guard let frontImageData = frontImageData else { return nil }
        return UIImage(data: frontImageData)
    }
    
    var backImage: UIImage? {
        guard let backImageData = backImageData else { return nil }
        return UIImage(data: backImageData)
    }
    
    // Legacy support - returns front image for backward compatibility
    var image: UIImage? {
        return frontImage
    }
    
    // Legacy support - returns front image data for backward compatibility  
    var imageData: Data? {
        return frontImageData
    }
    
    // Helper to check if item has any images
    var hasImages: Bool {
        return frontImageData != nil || backImageData != nil
    }
    
    // Helper to check if item has both images
    var hasBothImages: Bool {
        return frontImageData != nil && backImageData != nil
    }
    
    init(name: String, 
         type: ClothingType, 
         material: ClothingMaterial, 
         color: String, 
         frontImage: UIImage? = nil,
         backImage: UIImage? = nil,
         brand: String? = nil,
         size: ClothingSize? = nil,
         purchasePrice: Double? = nil,
         purchaseDate: Date? = nil,
         store: String? = nil,
         season: Season? = nil,
         occasion: Occasion? = nil,
         notes: String? = nil,
         condition: Condition = .good,
         tags: [String] = []) {
        self.name = name
        self.type = type
        self.material = material
        self.color = color
        self.dateAdded = Date()
        self.frontImageData = frontImage?.jpegData(compressionQuality: 0.8)
        self.backImageData = backImage?.jpegData(compressionQuality: 0.8)
        
        self.brand = brand
        self.size = size
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.store = store
        self.season = season
        self.occasion = occasion
        self.notes = notes
        self.condition = condition
        self.tags = tags
    }
    
    // Convenience initializer for backward compatibility with single image
    init(name: String, 
         type: ClothingType, 
         material: ClothingMaterial, 
         color: String, 
         image: UIImage? = nil,
         brand: String? = nil,
         size: ClothingSize? = nil,
         purchasePrice: Double? = nil,
         purchaseDate: Date? = nil,
         store: String? = nil,
         season: Season? = nil,
         occasion: Occasion? = nil,
         notes: String? = nil,
         condition: Condition = .good,
         tags: [String] = []) {
        self.init(
            name: name,
            type: type,
            material: material,
            color: color,
            frontImage: image,
            backImage: nil,
            brand: brand,
            size: size,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate,
            store: store,
            season: season,
            occasion: occasion,
            notes: notes,
            condition: condition,
            tags: tags
        )
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

enum ClothingSize: String, CaseIterable, Codable {
    // Letter sizes
    case xxs = "XXS"
    case xs = "XS"
    case s = "S"
    case m = "M"
    case l = "L"
    case xl = "XL"
    case xxl = "XXL"
    case xxxl = "XXXL"
    
    // Women's numeric sizes
    case size00 = "00"
    case size0 = "0"
    case size2 = "2"
    case size4 = "4"
    case size6 = "6"
    case size8 = "8"
    case size10 = "10"
    case size12 = "12"
    case size14 = "14"
    case size16 = "16"
    case size18 = "18"
    case size20 = "20"
    
    // Common shoe sizes
    case shoe5 = "5 (shoe)"
    case shoe5_5 = "5.5 (shoe)"
    case shoe6 = "6 (shoe)"
    case shoe6_5 = "6.5 (shoe)"
    case shoe7 = "7 (shoe)"
    case shoe7_5 = "7.5 (shoe)"
    case shoe8 = "8 (shoe)"
    case shoe8_5 = "8.5 (shoe)"
    case shoe9 = "9 (shoe)"
    case shoe9_5 = "9.5 (shoe)"
    case shoe10 = "10 (shoe)"
    case shoe10_5 = "10.5 (shoe)"
    case shoe11 = "11 (shoe)"
    case shoe11_5 = "11.5 (shoe)"
    case shoe12 = "12 (shoe)"
    
    case oneSize = "One Size"
    case custom = "Custom"
}

enum Season: String, CaseIterable, Codable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case allSeason = "All Season"
    
    var icon: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .fall: return "🍂"
        case .winter: return "❄️"
        case .allSeason: return "🌍"
        }
    }
}

enum Occasion: String, CaseIterable, Codable {
    case casual = "Casual"
    case work = "Work"
    case formal = "Formal"
    case party = "Party"
    case sport = "Sport"
    case sleep = "Sleep"
    case beach = "Beach"
    case travel = "Travel"
    case date = "Date"
    case wedding = "Wedding"
    
    var icon: String {
        switch self {
        case .casual: return "👕"
        case .work: return "💼"
        case .formal: return "🤵"
        case .party: return "🎉"
        case .sport: return "🏃"
        case .sleep: return "🛌"
        case .beach: return "🏖️"
        case .travel: return "✈️"
        case .date: return "💕"
        case .wedding: return "💒"
        }
    }
}

enum Condition: String, CaseIterable, Codable {
    case new = "New"
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var icon: String {
        switch self {
        case .new: return "✨"
        case .excellent: return "⭐"
        case .good: return "👍"
        case .fair: return "👌"
        case .poor: return "👎"
        }
    }
    
    var color: String {
        switch self {
        case .new: return "green"
        case .excellent: return "blue"
        case .good: return "orange"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
}
