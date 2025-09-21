import Foundation
import SwiftUI

class ClosetManager: ObservableObject {
    @Published var clothingItems: [ClothingItem] = []
    @Published var showingUndoMessage = false
    
    private let userDefaults = UserDefaults.standard
    private let clothingItemsKey = "ClothingItems"
    private var recentlyDeletedItems: [(item: ClothingItem, index: Int)] = []
    private var undoTimer: Timer?
    
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
        // Store deleted items for undo functionality
        recentlyDeletedItems.removeAll()
        
        for index in offsets.sorted(by: >) {
            let item = clothingItems[index]
            recentlyDeletedItems.append((item: item, index: index))
            clothingItems.remove(at: index)
        }
        
        saveClothingItems()
        
        // Show undo option
        showingUndoMessage = true
        
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
            ClothingItem(
                name: "Blue Denim Jeans", 
                type: .jeans, 
                material: .denim, 
                color: "Blue",
                brand: "Levi's",
                size: .m,
                purchasePrice: 89.99,
                store: "Macy's",
                season: .allSeason,
                occasion: .casual,
                condition: .good,
                tags: ["casual", "everyday"]
            ),
            ClothingItem(
                name: "White Cotton T-Shirt", 
                type: .tShirt, 
                material: .cotton, 
                color: "White",
                brand: "Gap",
                size: .m,
                purchasePrice: 19.99,
                store: "Gap",
                season: .summer,
                occasion: .casual,
                condition: .excellent,
                tags: ["basic", "summer"]
            ),
            ClothingItem(
                name: "Black Wool Sweater", 
                type: .sweater, 
                material: .wool, 
                color: "Black",
                brand: "J.Crew",
                size: .l,
                purchasePrice: 120.00,
                store: "J.Crew",
                season: .winter,
                occasion: .work,
                condition: .good,
                tags: ["warm", "professional"]
            ),
            ClothingItem(
                name: "Red Silk Blouse", 
                type: .blouse, 
                material: .silk, 
                color: "Red",
                brand: "Banana Republic",
                size: .s,
                purchasePrice: 85.00,
                store: "Banana Republic",
                season: .spring,
                occasion: .work,
                condition: .excellent,
                tags: ["elegant", "office"]
            ),
            ClothingItem(
                name: "Gray Polyester Jacket", 
                type: .jacket, 
                material: .polyester, 
                color: "Gray",
                brand: "Nike",
                size: .m,
                purchasePrice: 95.50,
                store: "Nike Store",
                season: .fall,
                occasion: .sport,
                condition: .good,
                tags: ["athletic", "outdoor"]
            )
        ]
        
        clothingItems = sampleItems
        saveClothingItems()
    }
    
    func undoDelete() {
        // Restore recently deleted items
        for (item, index) in recentlyDeletedItems.sorted(by: { $0.index < $1.index }) {
            let insertIndex = min(index, clothingItems.count)
            clothingItems.insert(item, at: insertIndex)
        }
        
        recentlyDeletedItems.removeAll()
        showingUndoMessage = false
        undoTimer?.invalidate()
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
