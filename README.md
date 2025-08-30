# Screenshot Sweeper

Screenshot Sweeper is a macOS menu bar app that automatically moves Desktop screenshots to the Trash or a specified folder on a scheduled basis. Keep your Desktop clean without manual file management.

## Features

- 🗓️ **Automated Cleanup**: Schedule daily screenshot cleanup at your preferred time
- 📁 **Flexible Destinations**: Move screenshots to Trash or any custom folder
- 🔍 **Smart Filtering**: Filter by screenshot filename prefix with case-sensitive options
- 🔒 **Secure Access**: Uses security-scoped bookmarks for safe folder access
- ⚡ **Menu Bar Integration**: Lightweight menu bar app with no dock presence
- 📊 **Usage Tracking**: Track cleanup history and file counts
- 🛡️ **Permission Handling**: Graceful permission error handling with clear user guidance

## System Requirements

- macOS 13.0 (Ventura) or later
- Desktop folder access permission (granted via System Settings)

## Installation

### From Releases
1. Download the latest release from the [Releases page](https://github.com/mauriceLC92/screenshot-sweeper/releases)
2. Extract the downloaded archive
3. Move Screenshot Sweeper.app to your Applications folder
4. Launch the app and grant necessary permissions

### Building from Source
See the [Development](#development) section below.

## Usage

### Initial Setup
1. Launch Screenshot Sweeper from Applications
2. Grant Desktop folder access when prompted:
   - Open **System Settings → Privacy & Security → Files and Folders**
   - Enable **Desktop** access for Screenshot Sweeper
3. Click the Screenshot Sweeper icon in your menu bar
4. Select **Preferences…** to configure your settings

### Configuration Options

#### Schedule Settings
- **Enable daily cleanup**: Toggle automatic cleanup on/off
- **Cleanup time**: Set your preferred daily cleanup time

#### File Filtering
- **Screenshot prefix**: Filter files by prefix (default: "Screenshot")
- **Case sensitivity**: Choose case-sensitive or insensitive matching

#### Destination Options
- **Move to Trash**: Default option, moves files to macOS Trash
- **Move to Folder**: Select a custom destination folder
  - Folder access is stored as security-scoped bookmarks
  - If access becomes invalid, you'll be prompted to reselect the folder

### Menu Bar Features
- **Clean Now**: Immediately run cleanup with current settings
- **Show matching files count**: See how many screenshots match your criteria
- **Last cleanup info**: View when cleanup last ran and files processed
- **Preferences**: Access all configuration options

## Development

### Prerequisites
- Xcode 15.0 or later
- macOS 13.0 SDK or later
- Active Apple Developer account (for code signing and distribution)

### Building and Running

```bash
# Clone the repository
git clone https://github.com/mauriceLC92/screenshot-sweeper.git
cd screenshot-sweeper

# Build the project
swift build

# Run the app
swift run
```

### Development Commands

```bash
# Build for release
swift build --configuration release

# Run tests
swift test
swift test --parallel                    # Run tests in parallel
swift test --filter NextRunCalculatorTests  # Run specific test class

# Package management
swift package resolve                    # Resolve dependencies
swift package clean                     # Clean build artifacts
swift package reset                     # Reset package state
```

### Project Architecture

Screenshot Sweeper follows an MVVM architecture with a clean separation of concerns:

- **Models**: `Settings` - Codable configuration with UserDefaults persistence
- **Services**: Core business logic (`CleanupService`, `FolderAccess`, `Scheduler`)
- **ViewModels**: `AppViewModel` - Central state management with `@Published` properties
- **Views**: SwiftUI components for menu bar and preferences interfaces
- **Utilities**: Helper functions like `NextRunCalculator` for scheduling logic

Key architectural patterns:
- Security-scoped bookmarks for sandboxed file access
- Custom `PreferencesWindowController` for window management
- Dynamic activation policy switching (`.accessory` ↔ `.regular`)
- Extensive logging and permission error handling

## Mac App Store Publishing

### Prerequisites Checklist

#### Developer Account Setup
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Xcode 15.0 or later installed
- [ ] Valid Developer ID certificates in Keychain Access
- [ ] App Store Connect access configured

#### Project Preparation
- [ ] Unique Bundle ID registered in Developer Portal
- [ ] App icons created in all required sizes (16x16 to 1024x1024)
- [ ] App screenshots prepared for Mac App Store
- [ ] Privacy policy created and hosted (if app handles user data)
- [ ] App description and metadata prepared

### Step-by-Step Publishing Guide

#### Phase 1: Xcode Project Configuration

1. **Create Xcode Project from Swift Package**
   ```bash
   # Convert Swift Package to Xcode project
   swift package generate-xcodeproj
   open ScreenshotSweeper.xcodeproj
   ```

2. **Configure Project Settings**
   - Set **Deployment Target** to macOS 13.0
   - Configure **Bundle ID** (e.g., `com.yourcompany.screenshotsweeper`)
   - Set **Version** and **Build** numbers
   - Configure **App Category** (Productivity or Utilities)

3. **Add Required Capabilities**
   - Enable **App Sandbox**
   - Enable **Hardened Runtime**
   - Add **File Access** capabilities

#### Phase 2: Entitlements Configuration

4. **Create Entitlements File**
   Create `ScreenshotSweeper.entitlements` with required permissions:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>com.apple.security.app-sandbox</key>
       <true/>
       <key>com.apple.security.files.user-selected.read-write</key>
       <true/>
       <key>com.apple.security.files.bookmarks.app-scope</key>
       <true/>
       <key>com.apple.security.files.bookmarks.document-scope</key>
       <true/>
   </dict>
   </plist>
   ```

#### Phase 3: App Store Connect Setup

5. **Create App Record**
   - Log in to [App Store Connect](https://appstoreconnect.apple.com)
   - Create new macOS app with your Bundle ID
   - Upload app icon (1024x1024 PNG)
   - Fill in app information and descriptions

6. **Configure App Metadata**
   - **App Name**: Screenshot Sweeper
   - **Subtitle**: Automated Desktop Screenshot Management
   - **Category**: Productivity or Utilities
   - **Keywords**: screenshot, cleanup, automation, desktop, organization
   - **Description**: Comprehensive app description highlighting features
   - **Screenshots**: Prepare screenshots showing menu bar interface and preferences

7. **Privacy and Compliance**
   - Answer privacy questionnaire
   - Upload privacy policy if required
   - Configure age rating
   - Set pricing (free or paid)

#### Phase 4: Build and Archive

8. **Prepare Release Build**
   - Select **Any Mac (Apple Silicon, Intel)** as destination
   - Choose **Product → Archive** in Xcode
   - Ensure no build errors or warnings

9. **Code Signing Verification**
   - Verify certificate is valid in Keychain Access
   - Check that provisioning profile matches Bundle ID
   - Confirm all entitlements are properly configured

#### Phase 5: App Store Submission

10. **Upload to App Store Connect**
    - In Xcode Organizer, select your archive
    - Click **Distribute App**
    - Choose **App Store Connect**
    - Select appropriate signing options
    - Upload and wait for processing

11. **Configure Version for Review**
    - Return to App Store Connect
    - Select your uploaded build
    - Configure version information
    - Add release notes
    - Submit for review

#### Phase 6: Review and Release

12. **App Review Process**
    - Typical review time: 1-3 business days
    - Monitor review status in App Store Connect
    - Respond to any review feedback promptly

13. **Release Management**
    - Upon approval, choose release timing:
      - **Automatic**: Releases immediately after approval
      - **Manual**: Release when you choose
    - Monitor initial user feedback and crash reports

### Common Review Issues and Solutions

#### Potential Rejection Reasons
- **Sandbox Violations**: Ensure all file access uses proper entitlements
- **UI Guidelines**: Menu bar apps should follow macOS design principles
- **Permission Handling**: Must gracefully handle denied permissions
- **Metadata Issues**: Screenshots and descriptions must accurately represent functionality

#### Best Practices
- Test thoroughly on clean macOS installations
- Verify all user-facing text is properly localized
- Ensure app works without internet connectivity
- Handle all error states gracefully with user-friendly messages
- Test permission flows extensively

### Post-Launch Maintenance

#### Version Updates
- Increment version numbers for each update
- Provide clear release notes
- Test updates don't break existing user configurations
- Monitor crash reports and user feedback

#### Ongoing Compliance
- Keep up with Apple's changing requirements
- Update certificates before expiration
- Respond to security vulnerability reports
- Maintain privacy policy accuracy

## Troubleshooting

### Common Issues

#### Files Not Being Moved
1. **Check Permissions**: 
   - System Settings → Privacy & Security → Files and Folders
   - Ensure Desktop access is enabled for Screenshot Sweeper

2. **Folder Access Issues**:
   - If using custom folder destination, reselect the folder in Preferences
   - Check that destination folder still exists and is accessible

3. **Screenshot Prefix Mismatch**:
   - Verify the prefix setting matches your actual screenshot files
   - Check case sensitivity setting

#### App Not Running Automatically
- Verify cleanup schedule is enabled in Preferences
- Check that cleanup time is set to desired hour
- App must remain running in menu bar for scheduled cleanup

#### High CPU Usage
- Check for large numbers of files on Desktop
- Consider filtering by more specific prefix
- Monitor Activity Monitor for unusual behavior

### Permission Errors

If you see permission-related errors:
1. Quit Screenshot Sweeper completely
2. Remove and re-add file access permissions in System Settings
3. Restart Screenshot Sweeper
4. Reselect destination folder if using custom folder option

### Getting Help

- **Issues and Bug Reports**: [GitHub Issues](https://github.com/mauriceLC92/screenshot-sweeper/issues)
- **Feature Requests**: Use GitHub Issues with "enhancement" label
- **General Questions**: Check existing issues or create a new discussion

## Contributing

Contributions are welcome! Please read our contributing guidelines and:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the existing code style
4. Add tests for new functionality
5. Ensure all tests pass (`swift test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Guidelines
- Follow Swift style guidelines
- Maintain MVVM architecture patterns
- Add comprehensive logging for debugging
- Handle all error cases gracefully
- Write unit tests for new utilities and services

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Swift and SwiftUI
- Uses security-scoped bookmarks for secure file access
- Follows macOS Human Interface Guidelines for menu bar apps