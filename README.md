# yvpsdk-swift

## Getting started

1. Register your app with YouVersion Platform, and acquire an app key.
2. In your Xcode project, on the File menu, choose "Add Package Dependencies".
3. Type `https://github.com/youversion/yvp-swift-sdk.git` into the search field.
4. Select `yvp-swift-sdk` from the search results.
5. For the "Dependency Rule", select `Up to Next Major Version`. (Or, if you're in YOLO mode, `Branch` and then `main`.)
6. Ensure your project is selected next to `Add to Project`.
7. Click `Add Package`.
8. On the Package Products dialog, add `YouVersionPlatform` to your target and click `Add Package`.

## Displaying Scripture in SwiftUI

Create an init() function for your app if you don't already have one, and specify your app key there, like this:
```
import YouVersionPlatform

@main
struct yourApp: App {
    init() {
        YouVersionPlatform.configure(appKey: "YOUR_APP_KEY_HERE")
    }
    var body: some Scene {...
```

And now to display a single verse or verse range, this is all it takes:
```
import YouVersionPlatform

struct DemoView: View {
    @StateObject private var version: BibleVersion
    
    init () {
        _version = StateObject(wrappedValue: BibleVersion(111).readied())
    }

    var body: some View {
        if let ref = version.usfm("JHN.3.16-17") {
            BibleTextView(ref)
        }
    }
}
```

If you're displaying a longer passage of scripture than a single verse, 
you should wrap BibleTextView inside a normal SwiftUI ScrollView.

### In case you're interested:

The function `.readied()` causes the YouVersionPlatform SDK to fetch metadata about 
the given Bible version from the server. That happens in a background task. 
Once that finishes, the `version.usfm()` call will return a valid BibleReference
object, which then allows the `BibleTextView` to be displayed.

When BibleTextView is rendered, it will fetch the necessary Bible text 
from the YouVersion server as needed, and display it as soon as it can.
It will also maintain a limited-size local cache of the Bible data for speed.

## Implementing Login

To the view where you want to add a "Log In with YouVersion" button, add this:
```
import YouVersionPlatform
```

Add a helper class, which tells iOS where to display the system's login sheet.
(See [here](https://developer.apple.com/documentation/authenticationservices/authenticating-a-user-through-a-web-service) for more details.)
```
import AuthenticationServices

class ContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
```

In the header of your SwiftUI view, store a strong reference to the ContextProvider:
```
@State private var contextProvider = ContextProvider() // Store a strong reference
```

Finally, inside your SwiftUI view, add the button and start the login process when it is tapped:
```
    LoginWithYouVersionButton() {
        YouVersionPlatform.login(
            contextProvider: contextProvider,
            required: [.bibles],
            optional: [.highlights]
        ) { result in
            switch result {
            case .success(let info):
                print(info)
                // The user is logged in and you have a LAT (a limited access token)!
                // Now you can use the LAT in YouVersion Platform API calls.
                // You should save the LAT locally so the user doesn't have to log in again next time.
                // You may examine the "permissions" parameter to see what the user approved;
                // e.g. perhaps they didn't grant access for your app to see their highlights.
            case .failure(let error):
                print(error)
            }
        } 
    }
```

## How to fetch data for the logged-in user

Once you have a LAT (see above), you can use it like this:
```
private func loadUI(lat: String) {
    Task {
        do {
            let info = try await YouVersionPlatform.fetchUserInfo(lat: lat)
            self.userWelcome = "Welcome, \(info.firstName)!"
        } catch {
            // handle the error
        }
        do {
            let votd = try await YouVersionPlatform.fetchVerseOfTheDay(lat: lat, translation: 1)
            self.votdTitle = "\(votd.reference) (\(votd.translation))"
            self.votdText = votd.text
            self.votdCopyright = votd.copyright
        } catch {
            // handle the error
        }
    }
}
```
