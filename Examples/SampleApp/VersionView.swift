import SwiftUI
import YouVersionPlatform

struct VersionView: View {
    @State private var versionIdString = "0"
    @State private var version: BibleVersion?
    @State private var isLoading = false
    @EnvironmentObject var repository: BibleVersionRepository
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            if isTextFieldFocused {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
            }
            VStack {
                HStack {
                    TextField("Enter version ID", text: $versionIdString)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .focused($isTextFieldFocused)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(2)
                    } else {
                        Button("Get") {
                            updateVersion()
                        }
                    }
                }
                .padding()
                
                if let version {
                    VStack(spacing: 12) {
                        Text(version.localizedAbbreviation ?? "unknown")
                            .font(.headline)
                        
                        Text(version.copyrightLong?.text ?? "unknown")
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
    }
    
    private func updateVersion() {
        guard let versionId = Int(versionIdString) else {
            return
        }
        
        Task {
            isLoading = true
            do {
                version = try await repository.version(withId: versionId)
            } catch {
                version = nil
            }
            isLoading = false
        }
    }
}
