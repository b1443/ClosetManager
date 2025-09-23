import SwiftUI

struct ClosetView: View {
    @EnvironmentObject var closetManager: ClosetManager
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var showingStatsSheet = false
    @State private var selectedItem: ClothingItem?
    
    // Enhanced filtering and sorting
    @State private var selectedSortOption: SortOption = .dateAdded
    @State private var sortAscending = false
    @State private var selectedTypeFilter: ClothingType? = nil
    @State private var selectedMaterialFilter: ClothingMaterial? = nil
    @State private var selectedColorFilter: String? = nil
    @State private var selectedSeasonFilter: Season? = nil
    @State private var selectedOccasionFilter: Occasion? = nil
    @State private var selectedConditionFilter: Condition? = nil
    @State private var selectedBrandFilter: String? = nil
    @State private var priceRangeMin: Double? = nil
    @State private var priceRangeMax: Double? = nil
    @State private var showingSortSheet = false
    
    // Batch operations
    @State private var isSelectionMode = false
    @State private var selectedItemIds: Set<UUID> = []
    @State private var showingBatchActionSheet = false
    
    // Settings
    @State private var showingSettings = false
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Date Added"
        case type = "Type"
        case material = "Material"
        case color = "Color"
        case price = "Price"
        case brand = "Brand"
    }
    
    var filteredAndSortedItems: [ClothingItem] {
        var items = closetManager.clothingItems
        
        // Apply text search first
        if !searchText.isEmpty {
            items = closetManager.searchClothingItems(query: searchText)
        }
        
        // Apply filters
        items = items.filter { item in
            // Type filter
            if let typeFilter = selectedTypeFilter, item.type != typeFilter {
                return false
            }
            
            // Material filter
            if let materialFilter = selectedMaterialFilter, item.material != materialFilter {
                return false
            }
            
            // Color filter
            if let colorFilter = selectedColorFilter, !item.color.lowercased().contains(colorFilter.lowercased()) {
                return false
            }
            
            // Season filter
            if let seasonFilter = selectedSeasonFilter, item.season != seasonFilter {
                return false
            }
            
            // Occasion filter
            if let occasionFilter = selectedOccasionFilter, item.occasion != occasionFilter {
                return false
            }
            
            // Condition filter
            if let conditionFilter = selectedConditionFilter, item.condition != conditionFilter {
                return false
            }
            
            // Brand filter
            if let brandFilter = selectedBrandFilter, item.brand?.lowercased() != brandFilter.lowercased() {
                return false
            }
            
            // Price range filter
            if let minPrice = priceRangeMin, let itemPrice = item.purchasePrice, itemPrice < minPrice {
                return false
            }
            if let maxPrice = priceRangeMax, let itemPrice = item.purchasePrice, itemPrice > maxPrice {
                return false
            }
            
            return true
        }
        
        // Apply sorting
        return items.sorted { item1, item2 in
            let result: Bool
            
            switch selectedSortOption {
            case .name:
                result = item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            case .dateAdded:
                result = item1.dateAdded < item2.dateAdded
            case .type:
                result = item1.type.rawValue.localizedCaseInsensitiveCompare(item2.type.rawValue) == .orderedAscending
            case .material:
                result = item1.material.rawValue.localizedCaseInsensitiveCompare(item2.material.rawValue) == .orderedAscending
            case .color:
                result = item1.color.localizedCaseInsensitiveCompare(item2.color) == .orderedAscending
            case .price:
                let price1 = item1.purchasePrice ?? 0
                let price2 = item2.purchasePrice ?? 0
                result = price1 < price2
            case .brand:
                let brand1 = item1.brand ?? ""
                let brand2 = item2.brand ?? ""
                result = brand1.localizedCaseInsensitiveCompare(brand2) == .orderedAscending
            }
            
            return sortAscending ? result : !result
        }
    }
    
    var selectedItems: [ClothingItem] {
        filteredAndSortedItems.filter { selectedItemIds.contains($0.id) }
    }
    
    var allItemsSelected: Bool {
        !filteredAndSortedItems.isEmpty && selectedItemIds.count == filteredAndSortedItems.count
    }
    
    var hasActiveFilters: Bool {
        selectedTypeFilter != nil || selectedMaterialFilter != nil || selectedColorFilter != nil ||
        selectedSeasonFilter != nil || selectedOccasionFilter != nil || selectedConditionFilter != nil ||
        selectedBrandFilter != nil || priceRangeMin != nil || priceRangeMax != nil
    }
    
    var availableBrands: [String] {
        Array(Set(closetManager.clothingItems.compactMap { $0.brand })).sorted()
    }
    
    var availableColors: [String] {
        Array(Set(closetManager.clothingItems.map { $0.color })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search clothing...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Button(action: {
                            showingSortSheet = true
                        }) {
                            HStack {
                                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                Image(systemName: "arrow.up.arrow.down")
                            }
                            .font(.title3)
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Active filters summary
                    if hasActiveFilters {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(getActiveFiltersArray(), id: \.self) { filter in
                                    Button(action: {
                                        removeFilter(filter)
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(filter)
                                                .font(.caption)
                                            Image(systemName: "xmark")
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                
                                Button("Clear All") {
                                    clearAllFilters()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                
                // Statistics Summary
                if !closetManager.clothingItems.isEmpty {
                    HStack {
                        VStack {
                            Text("\(closetManager.totalItemsCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("\(closetManager.itemsByType.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Types")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 30)
                        
                        VStack {
                            Text("\(closetManager.itemsByMaterial.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Materials")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingStatsSheet = true
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Clothing Items List
                if filteredAndSortedItems.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "tshirt")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(getEmptyStateMessage())
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text(getEmptyStateSubtitle())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    VStack {
                        List {
                            ForEach(filteredAndSortedItems) { item in
                                ClothingItemRow(
                                    item: item, 
                                    isSelected: selectedItemIds.contains(item.id),
                                    isSelectionMode: isSelectionMode
                                )
                                .onTapGesture {
                                    if isSelectionMode {
                                        toggleItemSelection(item)
                                    } else {
                                        selectedItem = item
                                    }
                                }
                            }
                            .onDelete(perform: isSelectionMode ? nil : closetManager.removeClothingItems)
                        }
                        .listStyle(PlainListStyle())
                        
                        // Batch Action Buttons
                        if isSelectionMode && !selectedItemIds.isEmpty {
                            VStack {
                                Divider()
                                
                                HStack(spacing: 20) {
                                    Button(action: {
                                        showingBatchActionSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "trash")
                                            Text("Delete (\(selectedItemIds.count))")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(10)
                                    }
                                    
                                    Button(action: {
                                        shareBatchItems()
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Export")
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()
                            }
                            .background(Color(.systemGray6))
                        }
                    }
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedItemIds.count) Selected" : "My Closet")
            .navigationBarItems(
                leading: isSelectionMode ? 
                    AnyView(Button(allItemsSelected ? "Deselect All" : "Select All") {
                        toggleSelectAll()
                    }) : 
                    AnyView(Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }),
                trailing: HStack {
                    if !closetManager.clothingItems.isEmpty {
                        if isSelectionMode {
                            Button("Cancel") {
                                exitSelectionMode()
                            }
                        } else {
                            Button("Select") {
                                enterSelectionMode()
                            }
                            
                            Menu {
                                Button(action: {
                                    shareClosetData()
                                }) {
                                    Label("Export Data", systemImage: "square.and.arrow.up")
                                }
                                
                                Button(action: {
                                    closetManager.clearAllItems()
                                }) {
                                    Label("Clear All", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showingFilterSheet) {
            AdvancedFilterSheet(
                selectedTypeFilter: $selectedTypeFilter,
                selectedMaterialFilter: $selectedMaterialFilter,
                selectedColorFilter: $selectedColorFilter,
                selectedSeasonFilter: $selectedSeasonFilter,
                selectedOccasionFilter: $selectedOccasionFilter,
                selectedConditionFilter: $selectedConditionFilter,
                selectedBrandFilter: $selectedBrandFilter,
                priceRangeMin: $priceRangeMin,
                priceRangeMax: $priceRangeMax,
                availableBrands: availableBrands,
                availableColors: availableColors
            )
        }
        .sheet(isPresented: $showingSortSheet) {
            SortSheet(
                selectedSortOption: $selectedSortOption,
                sortAscending: $sortAscending
            )
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsSheet()
                .environmentObject(closetManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(closetManager)
        }
        .sheet(item: $selectedItem) { item in
            ClothingDetailView(item: item)
        }
        .actionSheet(isPresented: $showingBatchActionSheet) {
            ActionSheet(
                title: Text("Delete \(selectedItemIds.count) items?"),
                message: Text("This action cannot be undone."),
                buttons: [
                    .destructive(Text("Delete")) {
                        deleteBatchItems()
                    },
                    .cancel()
                ]
            )
        }
        .overlay(
            // Undo notification
            VStack {
                Spacer()
                
                if closetManager.showingUndoMessage {
                    HStack {
                        Text("Item(s) deleted")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Undo") {
                            closetManager.undoDelete()
                        }
                        .foregroundColor(.yellow)
                        .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: closetManager.showingUndoMessage)
        )
    }
    
    // MARK: - Helper Functions
    private func getEmptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "No items found"
        } else if hasActiveFilters {
            return "No items match filters"
        } else {
            return "No clothing items yet"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        if !searchText.isEmpty {
            return "Try a different search term"
        } else if hasActiveFilters {
            return "Try adjusting your filters"
        } else {
            return "Add some clothes using the camera"
        }
    }
    
    private func getActiveFiltersArray() -> [String] {
        var filters: [String] = []
        
        if let type = selectedTypeFilter {
            filters.append("Type: \(type.rawValue)")
        }
        if let material = selectedMaterialFilter {
            filters.append("Material: \(material.rawValue)")
        }
        if let color = selectedColorFilter {
            filters.append("Color: \(color)")
        }
        if let season = selectedSeasonFilter {
            filters.append("Season: \(season.rawValue)")
        }
        if let occasion = selectedOccasionFilter {
            filters.append("Occasion: \(occasion.rawValue)")
        }
        if let condition = selectedConditionFilter {
            filters.append("Condition: \(condition.rawValue)")
        }
        if let brand = selectedBrandFilter {
            filters.append("Brand: \(brand)")
        }
        if let minPrice = priceRangeMin {
            filters.append("Min: $\(Int(minPrice))")
        }
        if let maxPrice = priceRangeMax {
            filters.append("Max: $\(Int(maxPrice))")
        }
        
        return filters
    }
    
    private func removeFilter(_ filterDescription: String) {
        if filterDescription.hasPrefix("Type:") {
            selectedTypeFilter = nil
        } else if filterDescription.hasPrefix("Material:") {
            selectedMaterialFilter = nil
        } else if filterDescription.hasPrefix("Color:") {
            selectedColorFilter = nil
        } else if filterDescription.hasPrefix("Season:") {
            selectedSeasonFilter = nil
        } else if filterDescription.hasPrefix("Occasion:") {
            selectedOccasionFilter = nil
        } else if filterDescription.hasPrefix("Condition:") {
            selectedConditionFilter = nil
        } else if filterDescription.hasPrefix("Brand:") {
            selectedBrandFilter = nil
        } else if filterDescription.hasPrefix("Min:") {
            priceRangeMin = nil
        } else if filterDescription.hasPrefix("Max:") {
            priceRangeMax = nil
        }
    }
    
    private func clearAllFilters() {
        selectedTypeFilter = nil
        selectedMaterialFilter = nil
        selectedColorFilter = nil
        selectedSeasonFilter = nil
        selectedOccasionFilter = nil
        selectedConditionFilter = nil
        selectedBrandFilter = nil
        priceRangeMin = nil
        priceRangeMax = nil
    }
    
    // MARK: - Batch Operations
    private func enterSelectionMode() {
        isSelectionMode = true
        selectedItemIds.removeAll()
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedItemIds.removeAll()
    }
    
    private func toggleSelectAll() {
        if allItemsSelected {
            selectedItemIds.removeAll()
        } else {
            selectedItemIds = Set(filteredAndSortedItems.map { $0.id })
        }
    }
    
    private func toggleItemSelection(_ item: ClothingItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
    }
    
    private func deleteBatchItems() {
        let itemsToDelete = selectedItems
        
        // Remove from closet manager (supports undo)
        closetManager.removeClothingItems(itemsToDelete)
        
        // Exit selection mode
        exitSelectionMode()
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func shareBatchItems() {
        let csvData = exportBatchItems()
        let activityVC = UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func exportBatchItems() -> String {
        var csvString = "Name,Type,Material,Color,Brand,Size,Price,Date Added\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for item in selectedItems {
            let dateString = dateFormatter.string(from: item.dateAdded)
            let brand = item.brand ?? "Unknown"
            let size = item.size?.rawValue ?? "Unknown"
            let price = item.purchasePrice != nil ? String(format: "%.2f", item.purchasePrice!) : "0.00"
            
            csvString += "\(item.name),\(item.type.rawValue),\(item.material.rawValue),\(item.color),\(brand),\(size),\(price),\(dateString)\n"
        }
        
        return csvString
    }
    
    private func shareClosetData() {
        let csvData = closetManager.exportClosetData()
        let activityVC = UIActivityViewController(activityItems: [csvData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct ClothingItemRow: View {
    let item: ClothingItem
    let isSelected: Bool
    let isSelectionMode: Bool
    
    init(item: ClothingItem, isSelected: Bool = false, isSelectionMode: Bool = false) {
        self.item = item
        self.isSelected = isSelected
        self.isSelectionMode = isSelectionMode
    }
    
    var body: some View {
        HStack {
            // Selection indicator
            if isSelectionMode {
                Button(action: {}) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Image or placeholder
            ZStack {
                Group {
                    if let image = item.frontImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Text(item.type.icon)
                                    .font(.title)
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Dual image indicator
                if item.hasBothImages {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.purple)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                } else if item.hasImages {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "photo")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text(item.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(item.material.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                    
                    if let size = item.size {
                        Text(size.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(item.color)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let price = item.purchasePrice, price > 0 {
                        Text(String(format: "$%.0f", price))
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Text(item.type.icon)
                    .font(.title2)
                
                Text(DateFormatter.shortDate.string(from: item.dateAdded))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

struct SortSheet: View {
    @Binding var selectedSortOption: ClosetView.SortOption
    @Binding var sortAscending: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sort By")) {
                    ForEach(ClosetView.SortOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.rawValue)
                            Spacer()
                            if selectedSortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSortOption = option
                        }
                    }
                }
                
                Section(header: Text("Sort Order")) {
                    HStack {
                        Text("Ascending")
                        Spacer()
                        if sortAscending {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sortAscending = true
                    }
                    
                    HStack {
                        Text("Descending")
                        Spacer()
                        if !sortAscending {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sortAscending = false
                    }
                }
            }
            .navigationTitle("Sort Options")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AdvancedFilterSheet: View {
    @Binding var selectedTypeFilter: ClothingType?
    @Binding var selectedMaterialFilter: ClothingMaterial?
    @Binding var selectedColorFilter: String?
    @Binding var selectedSeasonFilter: Season?
    @Binding var selectedOccasionFilter: Occasion?
    @Binding var selectedConditionFilter: Condition?
    @Binding var selectedBrandFilter: String?
    @Binding var priceRangeMin: Double?
    @Binding var priceRangeMax: Double?
    
    let availableBrands: [String]
    let availableColors: [String]
    
    @Environment(\.presentationMode) var presentationMode
    @State private var tempMinPrice: String = ""
    @State private var tempMaxPrice: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Categories")) {
                    // Type Filter
                    HStack {
                        Text("Type")
                        Spacer()
                        Menu {
                            Button("All Types") {
                                selectedTypeFilter = nil
                            }
                            ForEach(ClothingType.allCases, id: \.self) { type in
                                Button("\(type.icon) \(type.rawValue)") {
                                    selectedTypeFilter = type
                                }
                            }
                        } label: {
                            Text(selectedTypeFilter?.rawValue ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Material Filter
                    HStack {
                        Text("Material")
                        Spacer()
                        Menu {
                            Button("All Materials") {
                                selectedMaterialFilter = nil
                            }
                            ForEach(ClothingMaterial.allCases, id: \.self) { material in
                                Button(material.rawValue) {
                                    selectedMaterialFilter = material
                                }
                            }
                        } label: {
                            Text(selectedMaterialFilter?.rawValue ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Color Filter
                    HStack {
                        Text("Color")
                        Spacer()
                        Menu {
                            Button("All Colors") {
                                selectedColorFilter = nil
                            }
                            ForEach(availableColors, id: \.self) { color in
                                Button(color) {
                                    selectedColorFilter = color
                                }
                            }
                        } label: {
                            Text(selectedColorFilter ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Attributes")) {
                    // Season Filter
                    HStack {
                        Text("Season")
                        Spacer()
                        Menu {
                            Button("All Seasons") {
                                selectedSeasonFilter = nil
                            }
                            ForEach(Season.allCases, id: \.self) { season in
                                Button("\(season.icon) \(season.rawValue)") {
                                    selectedSeasonFilter = season
                                }
                            }
                        } label: {
                            Text(selectedSeasonFilter?.rawValue ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Occasion Filter
                    HStack {
                        Text("Occasion")
                        Spacer()
                        Menu {
                            Button("All Occasions") {
                                selectedOccasionFilter = nil
                            }
                            ForEach(Occasion.allCases, id: \.self) { occasion in
                                Button("\(occasion.icon) \(occasion.rawValue)") {
                                    selectedOccasionFilter = occasion
                                }
                            }
                        } label: {
                            Text(selectedOccasionFilter?.rawValue ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Condition Filter
                    HStack {
                        Text("Condition")
                        Spacer()
                        Menu {
                            Button("All Conditions") {
                                selectedConditionFilter = nil
                            }
                            ForEach(Condition.allCases, id: \.self) { condition in
                                Button("\(condition.icon) \(condition.rawValue)") {
                                    selectedConditionFilter = condition
                                }
                            }
                        } label: {
                            Text(selectedConditionFilter?.rawValue ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Brand Filter
                    HStack {
                        Text("Brand")
                        Spacer()
                        Menu {
                            Button("All Brands") {
                                selectedBrandFilter = nil
                            }
                            ForEach(availableBrands, id: \.self) { brand in
                                Button(brand) {
                                    selectedBrandFilter = brand
                                }
                            }
                        } label: {
                            Text(selectedBrandFilter ?? "All")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Price Range")) {
                    HStack {
                        Text("Min Price")
                        TextField("$0", text: $tempMinPrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Max Price")
                        TextField("No limit", text: $tempMaxPrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        selectedTypeFilter = nil
                        selectedMaterialFilter = nil
                        selectedColorFilter = nil
                        selectedSeasonFilter = nil
                        selectedOccasionFilter = nil
                        selectedConditionFilter = nil
                        selectedBrandFilter = nil
                        priceRangeMin = nil
                        priceRangeMax = nil
                        tempMinPrice = ""
                        tempMaxPrice = ""
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Advanced Filters")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Apply") {
                    // Apply price filters
                    priceRangeMin = Double(tempMinPrice)
                    priceRangeMax = Double(tempMaxPrice)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            tempMinPrice = priceRangeMin.map { String($0) } ?? ""
            tempMaxPrice = priceRangeMax.map { String($0) } ?? ""
        }
    }
}

struct StatsSheet: View {
    @EnvironmentObject var closetManager: ClosetManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("By Type")) {
                    ForEach(closetManager.itemsByType.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                        HStack {
                            Text("\(type.icon) \(type.rawValue)")
                            Spacer()
                            Text("\(count)")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section(header: Text("By Material")) {
                    ForEach(closetManager.itemsByMaterial.sorted(by: { $0.value > $1.value }), id: \.key) { material, count in
                        HStack {
                            Text(material.rawValue)
                            Spacer()
                            Text("\(count)")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section(header: Text("By Color")) {
                    ForEach(closetManager.itemsByColor.sorted(by: { $0.value > $1.value }), id: \.key) { color, count in
                        HStack {
                            Circle()
                                .fill(colorFromString(color))
                                .frame(width: 20, height: 20)
                            Text(color)
                            Spacer()
                            Text("\(count)")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "white": return .white
        case "black": return .black
        case "gray", "grey": return .gray
        case "brown": return .brown
        default: return .gray
        }
    }
}

struct ClothingDetailView: View {
    let item: ClothingItem
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImageIndex = 0
    @State private var showingFullScreenImage = false
    
    private var availableImages: [UIImage] {
        var images: [UIImage] = []
        if let frontImage = item.frontImage {
            images.append(frontImage)
        }
        if let backImage = item.backImage {
            images.append(backImage)
        }
        return images
    }
    
    private var imageLabels: [String] {
        var labels: [String] = []
        if item.frontImage != nil {
            labels.append("Front View")
        }
        if item.backImage != nil {
            labels.append("Back View")
        }
        return labels
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Images Section
                    if !availableImages.isEmpty {
                        VStack(spacing: 12) {
                            // Main Image Display
                            ZStack {
                                Image(uiImage: availableImages[selectedImageIndex])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(15)
                                    .onTapGesture {
                                        showingFullScreenImage = true
                                    }
                                
                                // Image counter overlay
                                if availableImages.count > 1 {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("\(selectedImageIndex + 1)/\(availableImages.count)")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.black.opacity(0.6))
                                                .cornerRadius(12)
                                                .padding(.trailing)
                                        }
                                        Spacer()
                                    }
                                    .padding(.top)
                                }
                            }
                            
                            // Image Type Label
                            if availableImages.count > 0 {
                                Text(imageLabels[selectedImageIndex])
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            // Image Navigation
                            if availableImages.count > 1 {
                                HStack(spacing: 20) {
                                    ForEach(0..<availableImages.count, id: \.self) { index in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedImageIndex = index
                                            }
                                        }) {
                                            VStack {
                                                Image(uiImage: availableImages[index])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(selectedImageIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                                                    )
                                                
                                                Text(imageLabels[index])
                                                    .font(.caption)
                                                    .foregroundColor(selectedImageIndex == index ? .blue : .secondary)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Text(item.type.icon)
                                        .font(.system(size: 80))
                                    Text("No Images")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .cornerRadius(15)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 15) {
                        Text(item.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Basic Information
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(title: "Type", value: item.type.rawValue, icon: "tag")
                            DetailRow(title: "Material", value: item.material.rawValue, icon: "textformat")
                            DetailRow(title: "Color", value: item.color, icon: "paintbrush")
                            
                            if let brand = item.brand {
                                DetailRow(title: "Brand", value: brand, icon: "building.2")
                            }
                            
                            if let size = item.size {
                                DetailRow(title: "Size", value: size.rawValue, icon: "ruler")
                            }
                            
                            DetailRow(title: "Condition", value: "\(item.condition.icon) \(item.condition.rawValue)", icon: "checkmark.seal")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Purchase Information
                    if item.purchasePrice != nil || item.store != nil {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Purchase Information")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                if let price = item.purchasePrice, price > 0 {
                                    DetailRow(title: "Price", value: String(format: "$%.2f", price), icon: "dollarsign.circle")
                                }
                                
                                if let purchaseDate = item.purchaseDate {
                                    DetailRow(title: "Purchase Date", value: DateFormatter.longDate.string(from: purchaseDate), icon: "calendar")
                                }
                                
                                if let store = item.store {
                                    DetailRow(title: "Store", value: store, icon: "bag")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Category Information
                    if item.season != nil || item.occasion != nil {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Category")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                if let season = item.season {
                                    DetailRow(title: "Season", value: "\(season.icon) \(season.rawValue)", icon: "thermometer")
                                }
                                
                                if let occasion = item.occasion {
                                    DetailRow(title: "Occasion", value: "\(occasion.icon) \(occasion.rawValue)", icon: "person.3")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Notes and Tags
                    if item.notes != nil || !item.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Additional Information")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                if let notes = item.notes {
                                    DetailRow(title: "Notes", value: notes, icon: "note.text")
                                }
                                
                                if !item.tags.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Image(systemName: "tag")
                                                .foregroundColor(.blue)
                                                .frame(width: 20)
                                            Text("Tags:")
                                                .fontWeight(.medium)
                                            Spacer()
                                        }
                                        
                                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                            ForEach(item.tags, id: \.self) { tag in
                                                Text(tag)
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    // Date Added
                    VStack(alignment: .leading, spacing: 15) {
                        Text("System Information")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        DetailRow(title: "Added", value: DateFormatter.longDate.string(from: item.dateAdded), icon: "calendar")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageViewer(
                images: availableImages,
                imageLabels: imageLabels,
                initialIndex: selectedImageIndex
            )
        }
    }
}

struct FullScreenImageViewer: View {
    let images: [UIImage]
    let imageLabels: [String]
    let initialIndex: Int
    
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(images: [UIImage], imageLabels: [String], initialIndex: Int) {
        self.images = images
        self.imageLabels = imageLabels
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: min(max(0, initialIndex), images.count - 1))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if !images.isEmpty {
                GeometryReader { geometry in
                    let image = images[currentIndex]
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = max(1.0, min(scale, 3.0))
                                    scale = lastScale
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(width: lastOffset.width + value.translation.width, height: lastOffset.height + value.translation.height)
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if images.count > 1 {
                        Text(imageLabels[currentIndex])
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                }
                .padding()
                
                Spacer()
                
                if images.count > 1 {
                    HStack {
                        Button(action: { withAnimation { currentIndex = max(0, currentIndex - 1) } }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        }
                        .disabled(currentIndex == 0)
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(images.count)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        Button(action: { withAnimation { currentIndex = min(images.count - 1, currentIndex + 1) } }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        }
                        .disabled(currentIndex == images.count - 1)
                    }
                    .padding()
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}

#Preview {
    ClosetView()
        .environmentObject(ClosetManager())
}
