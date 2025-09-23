import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var closetManager: ClosetManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportFormat: ExportFormat = .json
    @State private var showingBackupProgress = false
    @State private var showingFilePicker = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
        
        var utType: UTType {
            switch self {
            case .json: return UTType.json
            case .csv: return UTType.commaSeparatedText
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // iCloud Sync Section
                Section(header: Text("iCloud Sync")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Sync with iCloud")
                                .font(.headline)
                            Text("Keep your wardrobe synced across devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { closetManager.iCloudSyncEnabled },
                            set: { newValue in
                                closetManager.enableiCloudSync(newValue)
                            }
                        ))
                    }
                    
                    if closetManager.iCloudSyncEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                StatusIndicator(status: closetManager.syncStatus)
                            }
                            
                            if let lastSync = closetManager.lastSyncDate {
                                HStack {
                                    Text("Last sync:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if closetManager.isSyncing {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Syncing...")
                                            .font(.caption)
                                        Spacer()
                                        Text("\(Int(closetManager.backupProgress * 100))%")
                                            .font(.caption)
                                    }
                                    ProgressView(value: closetManager.backupProgress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                }
                            }
                            
                            Button("Sync Now") {
                                closetManager.syncWithiCloud()
                            }
                            .disabled(closetManager.isSyncing)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Backup Section
                Section(header: Text("Backup & Export")) {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            if let backupURL = await closetManager.createLocalBackup() {
                                shareBackup(url: backupURL)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(.green)
                            Text("Create Local Backup")
                            Spacer()
                            if closetManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(closetManager.isSyncing)
                }
                
                // Import Section
                Section(header: Text("Import & Restore")) {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.orange)
                            Text("Import Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.purple)
                            Text("Restore from Backup")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Statistics Section
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("\(closetManager.totalItemsCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text("Calculating...")
                            .foregroundColor(.secondary)
                            .task {
                                // This is a simplified approach for the preview
                                // In a real implementation, you'd want to store this in @State
                            }
                    }
                }
                
                // Danger Zone
                Section(header: Text("Danger Zone")) {
                    Button(action: {
                        showClearAllConfirmation()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(
                exportFormat: $exportFormat,
                onExport: { format in
                    exportData(format: format)
                }
            )
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportData(format: ExportFormat) {
        Task {
            let data: String
            let filename: String
            
            switch format {
            case .json:
                data = await closetManager.exportToJSON()
                filename = "ClothingCloset_\(Date().timeIntervalSince1970).json"
            case .csv:
                data = closetManager.exportToCSV()
                filename = "ClothingCloset_\(Date().timeIntervalSince1970).csv"
            }
            
            await MainActor.run {
                shareText(data, filename: filename)
            }
        }
    }
    
    private func shareText(_ text: String, filename: String) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func shareBackup(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                
                if url.pathExtension.lowercased() == "json" {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if closetManager.importFromJSON(jsonString: jsonString) {
                            showSuccess("Data imported successfully!")
                        } else {
                            showError("Failed to import JSON data")
                        }
                    }
                } else if url.pathExtension.lowercased() == "csv" {
                    if let csvString = String(data: data, encoding: .utf8) {
                        if closetManager.importFromCSV(csvString: csvString) {
                            showSuccess("Data imported successfully!")
                        } else {
                            showError("Failed to import CSV data")
                        }
                    }
                }
            } catch {
                showError("Failed to read file: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            showError("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func showSuccess(_ message: String) {
        alertMessage = message
        showingSuccessAlert = true
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingErrorAlert = true
    }
    
    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: "Clear All Data",
            message: "This will permanently delete all your clothing items. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            closetManager.clearAllItems()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
}

struct StatusIndicator: View {
    let status: ClosetManager.SyncStatus
    
    var body: some View {
        HStack(spacing: 4) {
            switch status {
            case .idle:
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.6)
                Text("Syncing")
                    .font(.caption)
                    .foregroundColor(.blue)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Synced")
                    .font(.caption)
                    .foregroundColor(.green)
            case .error(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct ExportSheet: View {
    @Binding var exportFormat: SettingsView.ExportFormat
    let onExport: (SettingsView.ExportFormat) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Export Format")) {
                    ForEach(SettingsView.ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Text(format.rawValue)
                            Spacer()
                            if exportFormat == format {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            exportFormat = format
                        }
                    }
                }
                
                Section {
                    Button("Export Data") {
                        onExport(exportFormat)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ClosetManager())
}