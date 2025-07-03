import SwiftUI
import YouVersionPlatform

struct ContentView: View {
    @State private var contextProvider = ContextProvider()
    @State private var accessToken: String?
    @State private var user: YouVersionUserInfo?
    
    var body: some View {
        VStack(spacing: 32) {
            if let user {
                Text("Signed in as \(user.firstName) \(user.lastName)")
                Button("Sign out") {
                    Task {
                        accessToken = nil
                    }
                }
            } else {
                Text("Signed out")
                
                LoginWithYouVersionButton {
                    Task {
                        do {
                            let result = try await YouVersionAPI.Users.logIn(
                                requiredPermissions: [.bibles],
                                optionalPermissions: [.highlights],
                                contextProvider: contextProvider
                            )
                            accessToken = result.accessToken
                            dump(result)
                            // The user is logged in and you have a LAT (a limited access token)!
                            // Now you can use the LAT in YouVersion Platform API calls.
                            // You should save the LAT locally so the user doesn't have to log in again next time.
                            // You may examine the "permissions" parameter to see what the user approved;
                            // e.g. perhaps they didn't grant access for your app to see their highlights.
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        .padding()
        .onChange(of: accessToken) {
            Task {
                await updateUser()
            }
        }
    }
    
    private func updateUser() async {
        if let accessToken {
            user = try? await YouVersionAPI.Users.userInfo(accessToken: accessToken)
        } else {
            user = nil
        }
        print("??? user name: \(user?.firstName) \(user?.lastName)")
    }
}

#Preview {
    ContentView()
}
