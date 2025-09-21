import SwiftUI

struct ClosetView: View {
    @EnvironmentObject var closetManager: ClosetManager
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var showingFilterSheet = false
    @State private var showingStatsSheet = false
    @State private var selectedItem: ClothingItem?
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case type = "Type"
        case material = "Material"
        case color = "Color"
    }
    
    var filteredItems: [ClothingItem] {
        if searchText.isEmpty {
            return closetManager.clothingItems
        } else {
            return closetManager.searchClothingItems(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search clothing...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
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
                if filteredItems.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "tshirt")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No clothing items yet" : "No items found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "Add some clothes using the camera" : "Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            ClothingItemRow(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                        .onDelete(perform: closetManager.removeClothingItems)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("My Closet")
            .navigationBarItems(
                trailing: HStack {
                    if !closetManager.clothingItems.isEmpty {
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
            )
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(selectedFilter: $selectedFilter)
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsSheet()
                .environmentObject(closetManager)
        }
        .sheet(item: $selectedItem) { item in
            ClothingDetailView(item: item)
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
    
    var body: some View {
        HStack {
            // Image or placeholder
            Group {
                if let image = item.image {
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
    }
}

struct FilterSheet: View {
    @Binding var selectedFilter: ClosetView.FilterType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ClosetView.FilterType.allCases, id: \.self) { filter in
                    HStack {
                        Text(filter.rawValue)
                        Spacer()
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filter
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Filter By")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let image = item.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(15)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Text(item.type.icon)
                                        .font(.system(size: 80))
                                    Text("No Image")
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
