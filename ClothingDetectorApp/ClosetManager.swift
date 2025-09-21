import Foundation
import SwiftUI

class ClosetManager: ObservableObject {
    @Published var clothingItems: [ClothingItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let clothingItemsKey = "ClothingItems"
    
    init() {
        loadClothingItems()
    }
    
    func addClothingItem(_ item: ClothingItem) {
        clothingItems.append(item)
        saveClothingItems()
    }
    
    func removeClothingItem(_ item: ClothingItem) {
        clothingItems.removeAll { $0.id == item.id }
        saveClothingItems()
    }
    
    func removeClothingItems(at offsets: IndexSet) {
        clothingItems.remove(atOffsets: offsets)
        saveClothingItems()
    }
    
    func getClothingItems(by type: ClothingType? = nil) -> [ClothingItem] {
        if let type = type {
            return clothingItems.filter { $0.type == type }
        }
        return clothingItems
    }
    
    func getClothingItems(by material: ClothingMaterial? = nil) -> [ClothingItem] {
        if let material = material {
            return clothingItems.filter { $0.material == material }
        }
        return clothingItems
    }
    
    func getClothingItems(by color: String? = nil) -> [ClothingItem] {
        if let color = color {
            return clothingItems.filter { $0.color.lowercased() == color.lowercased() }
        }
        return clothingItems
    }
    
    func searchClothingItems(query: String) -> [ClothingItem] {
        let lowercasedQuery = query.lowercased()
        return clothingItems.filter { item in
            item.name.lowercased().contains(lowercasedQuery) ||
            item.type.rawValue.lowercased().contains(lowercasedQuery) ||
            item.material.rawValue.lowercased().contains(lowercasedQuery) ||
            item.color.lowercased().contains(lowercasedQuery)
        }
    }
    
    var totalItemsCount: Int {
        clothingItems.count
    }
    
    var itemsByType: [ClothingType: Int] {
        var counts: [ClothingType: Int] = [:]
        for item in clothingItems {
            counts[item.type, default: 0] += 1
        }
        return counts
    }
    
    var itemsByMaterial: [ClothingMaterial: Int] {
        var counts: [ClothingMaterial: Int] = [:]
        for item in clothingItems {
            counts[item.material, default: 0] += 1
        }
        return counts
    }
    
    var itemsByColor: [String: Int] {
        var counts: [String: Int] = [:]
        for item in clothingItems {
            counts[item.color, default: 0] += 1
        }
        return counts
    }
    
    private func saveClothingItems() {
        do {
            let data = try JSONEncoder().encode(clothingItems)
            userDefaults.set(data, forKey: clothingItemsKey)
        } catch {
            print("Error saving clothing items: \(error)")
        }
    }
    
    private func loadClothingItems() {
        guard let data = userDefaults.data(forKey: clothingItemsKey) else {
            // Load sample data for demo purposes
            loadSampleData()
            return
        }
        
        do {
            clothingItems = try JSONDecoder().decode([ClothingItem].self, from: data)
        } catch {
            print("Error loading clothing items: \(error)")
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Add some sample clothing items for demonstration
        let sampleItems = [
            ClothingItem(name: "Blue Denim Jeans", type: .jeans, material: .denim, color: "Blue"),
            ClothingItem(name: "White Cotton T-Shirt", type: .tShirt, material: .cotton, color: "White"),
            ClothingItem(name: "Black Wool Sweater", type: .sweater, material: .wool, color: "Black"),
            ClothingItem(name: "Red Silk Blouse", type: .blouse, material: .silk, color: "Red"),
            ClothingItem(name: "Gray Polyester Jacket", type: .jacket, material: .polyester, color: "Gray")
        ]
        
        clothingItems = sampleItems
        saveClothingItems()
    }
    
    func clearAllItems() {
        clothingItems.removeAll()
        saveClothingItems()
    }
    
    func exportClosetData() -> String {
        var csvString = "Name,Type,Material,Color,Date Added\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for item in clothingItems {
            let dateString = dateFormatter.string(from: item.dateAdded)
            csvString += "\(item.name),\(item.type.rawValue),\(item.material.rawValue),\(item.color),\(dateString)\n"
        }
        
        return csvString
    }
}
