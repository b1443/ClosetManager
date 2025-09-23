import Foundation
import SwiftUI

class ClosetManager: ObservableObject {
    @Published var clothingItems: [ClothingItem] = []
    @Published var showingUndoMessage = false
    
    // Backup and sync states
    @Published var iCloudSyncEnabled = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var backupProgress: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    private let clothingItemsKey = "ClothingItems"
    private let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    private let lastSyncDateKey = "LastSyncDate"
    private var recentlyDeletedItems: [(item: ClothingItem, index: Int)] = []
    private var undoTimer: Timer?
    
    // iCloud sync properties
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default
    private let fileManager = FileManager.default
    private var iCloudDocumentsURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    init() {
        loadClothingItems()
        loadSyncPreferences()
        setupiCloudSync()
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
        
        // Start timer to hide undo message
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.showingUndoMessage = false
                self.recentlyDeletedItems.removeAll()
            }
        }
    }
    
    func removeClothingItems(_ items: [ClothingItem]) {
        // Store deleted items for undo functionality
        recentlyDeletedItems.removeAll()
        
        for item in items {
            if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
                recentlyDeletedItems.append((item: item, index: index))
                clothingItems.remove(at: index)
            }
        }
        
        saveClothingItems()
        
        // Show undo option
        showingUndoMessage = true
        
        // Start timer to hide undo message
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.showingUndoMessage = false
                self.recentlyDeletedItems.removeAll()
            }
        }
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
    
    // MARK: - Sync Preferences
    private func loadSyncPreferences() {
        iCloudSyncEnabled = userDefaults.bool(forKey: iCloudSyncEnabledKey)
        lastSyncDate = userDefaults.object(forKey: lastSyncDateKey) as? Date
    }
    
    private func saveSyncPreferences() {
        userDefaults.set(iCloudSyncEnabled, forKey: iCloudSyncEnabledKey)
        if let lastSyncDate = lastSyncDate {
            userDefaults.set(lastSyncDate, forKey: lastSyncDateKey)
        }
    }
    
    // MARK: - iCloud Sync Setup
    private func setupiCloudSync() {
        if iCloudSyncEnabled {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(iCloudStoreDidChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: ubiquitousStore
            )
            
            // Check if iCloud is available
            if let _ = iCloudDocumentsURL {
                syncWithiCloud()
            } else {
                syncStatus = .error("iCloud is not available")
            }
        }
    }
    
    @objc private func iCloudStoreDidChange() {
        DispatchQueue.main.async {
            self.syncFromiCloud()
        }
    }
    
    // MARK: - iCloud Sync Methods
    func enableiCloudSync(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        saveSyncPreferences()
        
        if enabled {
            setupiCloudSync()
        } else {
            NotificationCenter.default.removeObserver(self)
            syncStatus = .idle
        }
    }
    
    func syncWithiCloud() {
        guard iCloudSyncEnabled, let iCloudURL = iCloudDocumentsURL else {
            syncStatus = .error("iCloud sync not enabled or unavailable")
            return
        }
        
        isSyncing = true
        syncStatus = .syncing
        backupProgress = 0.0
        
        Task {
            do {
                // Create iCloud directory if it doesn't exist
                if !fileManager.fileExists(atPath: iCloudURL.path) {
                    try fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
                }
                
                let backupURL = iCloudURL.appendingPathComponent("ClothingClosetBackup.json")
                
                await MainActor.run {
                    self.backupProgress = 0.25
                }
                
                // Export current data
                let backupData = try await exportFullBackup()
                
                await MainActor.run {
                    self.backupProgress = 0.75
                }
                
                // Write to iCloud
                try backupData.write(to: backupURL)
                
                // Update sync metadata
                ubiquitousStore.set(Date(), forKey: "lastSyncDate")
                ubiquitousStore.set(clothingItems.count, forKey: "itemCount")
                ubiquitousStore.synchronize()
                
                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.saveSyncPreferences()
                    self.backupProgress = 1.0
                    self.syncStatus = .success
                    self.isSyncing = false
                }
                
            } catch {
                await MainActor.run {
                    self.syncStatus = .error("Sync failed: \(error.localizedDescription)")
                    self.isSyncing = false
                }
            }
        }
    }
    
    private func syncFromiCloud() {
        guard iCloudSyncEnabled, let iCloudURL = iCloudDocumentsURL else { return }
        
        let backupURL = iCloudURL.appendingPathComponent("ClothingClosetBackup.json")
        
        guard fileManager.fileExists(atPath: backupURL.path) else { return }
        
        Task {
            do {
                let data = try Data(contentsOf: backupURL)
                await importFullBackup(data: data)
            } catch {
                await MainActor.run {
                    self.syncStatus = .error("Import from iCloud failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Export Methods
    func exportFullBackup() async throws -> Data {
        let backupData = BackupData(
            version: "1.0",
            exportDate: Date(),
            itemCount: clothingItems.count,
            items: clothingItems
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backupData)
    }
    
    func exportToJSON() async -> String {
        do {
            let data = try await exportFullBackup()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error exporting data: \(error.localizedDescription)"
        }
    }
    
    func exportToCSV() -> String {
        var csvString = "Name,Type,Material,Color,Brand,Size,Price,Store,Season,Occasion,Condition,Tags,Date Added\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for item in clothingItems {
            let dateString = dateFormatter.string(from: item.dateAdded)
            let brand = item.brand ?? ""
            let size = item.size?.rawValue ?? ""
            let price = item.purchasePrice.map { String($0) } ?? ""
            let store = item.store ?? ""
            let season = item.season?.rawValue ?? ""
            let occasion = item.occasion?.rawValue ?? ""
            let tags = item.tags.joined(separator: ";")
            
            csvString += "\"\(item.name)\",\"\(item.type.rawValue)\",\"\(item.material.rawValue)\",\"\(item.color)\",\"\(brand)\",\"\(size)\",\"\(price)\",\"\(store)\",\"\(season)\",\"\(occasion)\",\"\(item.condition.rawValue)\",\"\(tags)\",\"\(dateString)\"\n"
        }
        
        return csvString
    }
    
    // MARK: - Import Methods
    func importFullBackup(data: Data) async {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backupData = try decoder.decode(BackupData.self, from: data)
            
            await MainActor.run {
                // Merge or replace based on user preference
                self.clothingItems = backupData.items
                self.saveClothingItems()
                self.lastSyncDate = Date()
                self.saveSyncPreferences()
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    func importFromJSON(jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        
        Task {
            await importFullBackup(data: data)
        }
        
        return true
    }
    
    func importFromCSV(csvString: String) -> Bool {
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else { return false }
        
        var importedItems: [ClothingItem] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 4 else { continue }
            
            // Parse CSV components (simplified version)
            let name = components[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let typeString = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let materialString = components[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let color = components[3].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            
            // Map strings to enums
            guard let type = ClothingType.allCases.first(where: { $0.rawValue == typeString }),
                  let material = ClothingMaterial.allCases.first(where: { $0.rawValue == materialString }) else {
                continue
            }
            
            let item = ClothingItem(
                name: name,
                type: type,
                material: material,
                color: color
            )
            
            importedItems.append(item)
        }
        
        DispatchQueue.main.async {
            self.clothingItems.append(contentsOf: importedItems)
            self.saveClothingItems()
        }
        
        return true
    }
    
    // MARK: - Backup Management
    func createLocalBackup() async -> URL? {
        do {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let backupURL = documentsPath.appendingPathComponent("ClothingClosetBackup_\(Date().timeIntervalSince1970).json")
            
            let data = try await exportFullBackup()
            try data.write(to: backupURL)
            
            return backupURL
        } catch {
            await MainActor.run {
                self.syncStatus = .error("Local backup failed: \(error.localizedDescription)")
            }
            return nil
        }
    }
    
    func restoreFromLocalBackup(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            Task {
                await importFullBackup(data: data)
            }
        } catch {
            syncStatus = .error("Restore failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Conflict Resolution
    func resolveConflicts(localItems: [ClothingItem], remoteItems: [ClothingItem]) -> [ClothingItem] {
        var mergedItems: [UUID: ClothingItem] = [:]
        
        // Add local items first
        for item in localItems {
            mergedItems[item.id] = item
        }
        
        // Add remote items, keeping newer versions
        for remoteItem in remoteItems {
            if let localItem = mergedItems[remoteItem.id] {
                // Keep the item with the later date (more recent)
                if remoteItem.dateAdded > localItem.dateAdded {
                    mergedItems[remoteItem.id] = remoteItem
                }
            } else {
                mergedItems[remoteItem.id] = remoteItem
            }
        }
        
        return Array(mergedItems.values).sorted { $0.dateAdded < $1.dateAdded }
    }
}

// MARK: - Backup Data Structure
struct BackupData: Codable {
    let version: String
    let exportDate: Date
    let itemCount: Int
    let items: [ClothingItem]
}
