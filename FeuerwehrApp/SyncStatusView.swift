import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject private var cloudManager: CloudDataManager
    
    var body: some View {
        HStack(spacing: 8) {
            if cloudManager.isSyncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .frame(width: 20, height: 20)
                Text("Synchronisiere...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSync = cloudManager.lastSyncDate {
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
                Text("Aktualisiert \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.orange)
                Text("Nicht synchronisiert")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}