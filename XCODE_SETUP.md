# Xcode Manual Setup Guide
## RVU Tracker iOS - Required Manual Configuration Steps

This guide walks you through the Xcode configuration steps that couldn't be automated via command line.

---

## Step 1: Enable Apple Sign-In Capability

**Why:** Required for Apple Sign-In to work. Apple requires this capability to be explicitly enabled.

**Instructions:**

1. **Open the Project in Xcode:**
   ```bash
   cd /Users/ddctu/git/track_my_rvu_ios/track_my_rvu
   open track_my_rvu.xcodeproj
   ```

2. **Select the Project:**
   - In Xcode's left sidebar (Navigator), click on the **blue "track_my_rvu"** project file at the top

3. **Select the Target:**
   - In the main editor, make sure the **"track_my_rvu"** target is selected (not the project)
   - You should see tabs: General, Signing & Capabilities, Resource Tags, Info, Build Settings, etc.

4. **Go to Signing & Capabilities Tab:**
   - Click on the **"Signing & Capabilities"** tab

5. **Add Sign in with Apple Capability:**
   - Click the **"+ Capability"** button in the top left
   - Type "Sign in with Apple" in the search field
   - Double-click **"Sign in with Apple"** to add it
   - You should now see "Sign in with Apple" listed in your capabilities

6. **Verify:**
   - The capability should show up with no errors
   - If you see a red error, you may need to configure your Team in the "Signing" section first
   - Make sure "Automatically manage signing" is checked in the Signing section

**Expected Result:** "Sign in with Apple" capability appears in your project with no errors.

---

## Step 2: Add GoogleSignIn-iOS Package (Swift Package Manager)

**Why:** Needed for Google Sign-In functionality. This is the official Google SDK.

**Instructions:**

1. **Open Package Dependencies:**
   - In Xcode's top menu, go to **File → Add Package Dependencies...**
   - Or select your project in Navigator, then go to the **"Package Dependencies"** tab

2. **Add Google Sign-In Package:**
   - In the search bar (top right), paste this URL:
     ```
     https://github.com/google/GoogleSignIn-iOS
     ```
   - Press Enter/Return

3. **Select Version:**
   - Dependency Rule: **"Up to Next Major Version"**
   - Version: **7.0.0** (or latest version shown)
   - Click **"Add Package"**

4. **Choose Package Products:**
   - You'll see a list of package products
   - Check **"GoogleSignIn"** (the main library)
   - Uncheck "GoogleSignInSwift" (optional, we'll use the main one)
   - Make sure it's being added to the **"track_my_rvu"** target
   - Click **"Add Package"**

5. **Wait for Package to Download:**
   - Xcode will download and integrate the package
   - This may take 1-2 minutes
   - Watch the progress in the top bar

6. **Verify:**
   - Go to Project Navigator → track_my_rvu project → Package Dependencies tab
   - You should see "GoogleSignIn" listed
   - The package should show as "Up to Date"

**Expected Result:** GoogleSignIn-iOS package is added and shows "Up to Date" status.

---

## Step 3: Configure Google OAuth Client ID

**Why:** Google Sign-In requires a valid OAuth client ID from Google Cloud Console.

**Instructions:**

### 3a. Get Google OAuth Client ID (if you don't have one)

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/

2. **Create or Select a Project:**
   - Click on the project dropdown at the top
   - Either select your existing project or click **"New Project"**
   - Name it: "RVU Tracker" or similar
   - Click **"Create"**

3. **Enable Google Sign-In API:**
   - Go to **APIs & Services → Library**
   - Search for "Google Sign-In API" or "Google Identity"
   - Click on it and click **"Enable"**

4. **Create OAuth Consent Screen:**
   - Go to **APIs & Services → OAuth consent screen**

   **If you see "External" or "Internal" options:**
   - Select **"External"** (for personal Google accounts)
   - Or **"Internal"** (if you have Google Workspace)

   **If you DON'T see these options:**
   - The consent screen might already exist - skip to filling in the details below
   - Or click **"CONFIGURE CONSENT SCREEN"** or **"EDIT APP"** if you see those buttons

   **Fill in required fields:**
   - App name: **RVU Tracker**
   - User support email: select your email from dropdown
   - App logo: (optional - skip for now)
   - Application home page: (optional - skip for now)
   - Authorized domains: (optional - skip for now)
   - Developer contact information: your email

   - Click **"Save and Continue"** through the steps
   - On "Scopes" screen: click **"Save and Continue"** (no scopes needed for basic sign-in)
   - On "Test users" screen: (optional) or click **"Save and Continue"**
   - On "Summary" screen: click **"Back to Dashboard"**

5. **Create OAuth Client ID:**
   - Go to **APIs & Services → Credentials**
   - Click **"+ Create Credentials"** → **"OAuth client ID"**
   - Application type: **"iOS"**
   - Name: "RVU Tracker iOS"
   - Bundle ID: **`com.trackmyrvu.ios`** (must match your Xcode bundle ID)
   - Click **"Create"**

6. **Copy the Client ID:**
   - You'll see a dialog with your OAuth client ID
   - Copy the **Client ID** (looks like: `123456789-abc123.apps.googleusercontent.com`)
   - Save it somewhere safe - you'll need it next

### 3b. Add Client ID to Constants.swift

1. **Open Constants.swift in Xcode:**
   - Navigate to: `track_my_rvu/Utilities/Constants.swift`
   - Find the line with `googleClientID`

2. **Replace the Placeholder:**
   ```swift
   // Replace this line:
   static let googleClientID = "YOUR_GOOGLE_CLIENT_ID_HERE"

   // With your actual client ID:
   static let googleClientID = "123456789-abc123.apps.googleusercontent.com"
   ```

3. **Save the File:**
   - Press **⌘S** to save

**Expected Result:** Constants.swift contains your real Google OAuth client ID.

---

## Step 4: Add Google Sign-In URL Scheme to Info.plist

**Why:** iOS needs to know which URL schemes your app can handle for OAuth callbacks.

**Instructions:**

1. **Open Info.plist (Modern Xcode - Info.plist is hidden):**

   **Method A - Via Info Tab (RECOMMENDED):**
   - In Xcode Navigator (left sidebar), click the **blue "track_my_rvu"** project file at the top
   - Make sure the **"track_my_rvu"** target is selected (under TARGETS, not PROJECT)
   - Click the **"Info"** tab at the top
   - You'll see a list of properties - this IS your Info.plist!

   **Method B - Create/Show Info.plist file (if needed):**
   - The Info.plist might be auto-generated by Xcode
   - Check if "Generate Info.plist File" is enabled in Build Settings
   - If you need the actual file, you can find it in the build folder after building

2. **Add URL Types (in the Info tab you just opened):**

   **Look for "URL Types" section:**
   - Scroll down in the Info tab
   - Look for a section called **"URL Types"**

   **If you DON'T see "URL Types":**
   - At the bottom of the list, click the **"+"** button to add a new row
   - In the dropdown that appears, type: **"URL types"**
   - Or scroll through the dropdown to find "URL Types" and select it

3. **Expand URL Types and add a new URL Type:**
   - Click the small **arrow/triangle** next to "URL Types" to expand it
   - You should see **"URL Types (Array)"**
   - Click the **"+"** button to add **"Item 0"**

4. **Add URL Schemes to Item 0:**
   - Expand **"Item 0"** by clicking its arrow
   - You'll see fields like "Document Role", "URL identifier", etc.
   - Look for **"URL Schemes"** (if not there, click + to add it)
   - Expand **"URL Schemes"**
   - Click the **"+"** to add **"Item 0"** under URL Schemes
   - In the **Value** field for this Item 0, enter your **reversed client ID**

5. **Get Your Reversed Client ID:**
   - Take your Google Client ID: `123456789-abc123.apps.googleusercontent.com`
   - Reverse it: `com.googleusercontent.apps.abc123-123456789`
   - Enter this as the URL scheme

**Example:**
```
URL types (Array)
  └── Item 0 (Dictionary)
       └── URL Schemes (Array)
            └── Item 0 (String): com.googleusercontent.apps.abc123-123456789
```

6. **Verify:**
   - The URL scheme should be the **reversed** version of your client ID
   - No spaces, no typos
   - Should start with `com.googleusercontent.apps.`

**Expected Result:** Info.plist contains the Google Sign-In URL scheme.

---

## Step 5: Update Google Sign-In Implementation

**Why:** Now that the SDK is installed, we can implement real Google Sign-In.

**Instructions:**

1. **Open AuthViewModel.swift:**
   - Navigate to: `track_my_rvu/ViewModels/AuthViewModel.swift`
   - Find the `signInWithGoogle()` method

2. **Add Google Sign-In Import:**
   - At the top of the file, add:
   ```swift
   import GoogleSignIn
   ```

3. **Update signInWithGoogle() Method:**
   - Replace the placeholder implementation with:
   ```swift
   func signInWithGoogle() {
       isLoading = true
       errorMessage = nil

       guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
             let rootViewController = windowScene.windows.first?.rootViewController else {
           errorMessage = "Unable to get root view controller"
           isLoading = false
           return
       }

       let config = GIDConfiguration(clientID: Constants.Auth.googleClientID)
       GIDSignIn.sharedInstance.configuration = config

       GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
           guard let self = self else { return }

           Task { @MainActor in
               if let error = error {
                   self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                   self.isLoading = false
                   return
               }

               guard let signInResult = signInResult else {
                   self.errorMessage = "Google Sign-In returned no result"
                   self.isLoading = false
                   return
               }

               let user = signInResult.user
               guard let idToken = user.idToken?.tokenString else {
                   self.errorMessage = "Failed to get ID token"
                   self.isLoading = false
                   return
               }

               // TODO: Send idToken to backend for verification
               // For now, create a mock user
               let mockUser = User(
                   id: user.userID ?? UUID().uuidString,
                   email: user.profile?.email ?? "user@gmail.com",
                   name: user.profile?.name,
                   provider: .google
               )

               await self.handleSuccessfulSignIn(token: idToken, user: mockUser)
           }
       }
   }
   ```

4. **Save the File:**
   - Press **⌘S** to save

**Expected Result:** Google Sign-In now uses the real GoogleSignIn SDK.

---

## Step 6: Set App Display Name

**Why:** Make the app show as "RVU Tracker" on the home screen instead of "track_my_rvu".

**Instructions:**

1. **Option A - Via Info.plist:**
   - Open Info.plist
   - Find or add key: **"Bundle display name"** (or `CFBundleDisplayName`)
   - Set value to: **"RVU Tracker"**

2. **Option B - Via Build Settings:**
   - Select project → target → Build Settings tab
   - Search for: **"Product Name"**
   - Set to: **"RVU Tracker"**

**Expected Result:** App displays as "RVU Tracker" when installed.

---

## Step 7: Build and Test

**Instructions:**

1. **Select a Simulator:**
   - In Xcode's top bar, click the device selector
   - Choose: **iPhone 15 Pro** (or any iPhone simulator with iOS 17.0+)

2. **Build the Project:**
   - Press **⌘B** to build
   - Wait for build to complete
   - Check for any errors in the bottom panel

3. **Run the App:**
   - Press **⌘R** to build and run
   - The simulator should launch
   - You should see the **SignInView** with both sign-in buttons

4. **Test Apple Sign-In:**
   - Click **"Sign in with Apple"** button
   - In the simulator, you may need to configure Apple ID:
     - Go to Settings → Sign in to your iPhone
     - Use a test Apple ID (or create one)
   - Alternatively, the simulator will show a test authentication flow

5. **Test Google Sign-In:**
   - Click **"Sign in with Google"** button
   - A browser-based Google authentication should appear
   - Sign in with your Google account
   - After successful sign-in, you should be taken to the main app

6. **Test Sign-Out:**
   - Navigate to the **Profile** tab
   - Tap **"Sign Out"**
   - You should be returned to the SignInView

**Expected Result:**
- ✅ App builds without errors
- ✅ Sign-in screen appears with both buttons
- ✅ Apple Sign-In works (or shows simulator test flow)
- ✅ Google Sign-In shows authentication flow
- ✅ After sign-in, main app tabs appear
- ✅ Sign-out returns to sign-in screen

---

## Troubleshooting

### Issue: "Sign in with Apple" button doesn't work
**Solution:**
- Make sure the capability is added in Signing & Capabilities
- Check that you're using a simulator with iOS 13.0+
- Try using a real device with a test Apple ID

### Issue: Google Sign-In shows "Invalid Client ID"
**Solution:**
- Verify the client ID in Constants.swift matches Google Cloud Console
- Make sure you created an **iOS** OAuth client (not Web or Android)
- Double-check the bundle ID matches: `com.trackmyrvu.ios`

### Issue: Google Sign-In doesn't open browser
**Solution:**
- Verify URL scheme in Info.plist is correct (reversed client ID)
- Make sure GoogleSignIn package was added correctly
- Clean build folder: **Product → Clean Build Folder** (⌘⇧K)

### Issue: Build errors after adding GoogleSignIn
**Solution:**
- Try removing and re-adding the package
- Make sure you're targeting iOS 17.0+
- Update to latest Xcode version if needed

---

## Next Steps After Manual Setup

Once all manual steps are complete:

1. **Commit the changes:**
   ```bash
   git add .
   git commit -m "Configure Xcode: Apple Sign-In capability, Google SDK, and URL schemes"
   ```

2. **Test thoroughly:**
   - Test on multiple simulators
   - Test on a real device if available
   - Verify sign-in/sign-out flow works

3. **Backend Integration:**
   - Create `/api/auth/apple` endpoint on your backend
   - Create `/api/auth/google` endpoint
   - Replace mock authentication with real API calls

4. **Continue to Milestone 3:**
   - Data Layer & Local Storage
   - Swift Data models for Visit and Procedure
   - HCPCS code cache implementation

---

## Checklist

- [ ] Apple Sign-In capability enabled
- [ ] GoogleSignIn-iOS package added via SPM
- [ ] Google OAuth client ID obtained from Google Cloud Console
- [ ] Google client ID added to Constants.swift
- [ ] Google Sign-In URL scheme added to Info.plist
- [ ] Google Sign-In implementation updated in AuthViewModel.swift
- [ ] App display name set to "RVU Tracker"
- [ ] Project builds successfully (⌘B)
- [ ] App runs on simulator (⌘R)
- [ ] Apple Sign-In tested
- [ ] Google Sign-In tested
- [ ] Sign-out tested
- [ ] Changes committed to Git

---

**Questions?** If you run into any issues during these steps, let me know which step you're on and what error you're seeing!
