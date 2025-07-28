# RouteX Release Workflow Guide

This guide explains how to trigger the release workflow to create DMG files and publish them to GitHub releases.

## 🚀 How to Trigger the Release Workflow

### Method 1: Automatic Release (Recommended)

Create a new release by pushing a tag:

```bash
# Create a new version tag
git tag v1.0.0

# Push the tag to trigger the workflow
git push origin v1.0.0
```

This will automatically:
1. Build the universal binary (Apple Silicon + Intel)
2. Create the app bundle with proper icons
3. Create both DMG and ZIP files
4. Create a GitHub release with both files attached
5. Generate automatic release notes

### Method 2: Manual Trigger

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select **Build and Release** workflow
4. Click **Run workflow**
5. Choose the branch (usually `main`)
6. Click **Run workflow**

This creates a development build with timestamp versioning.

## 📦 What Gets Created

### For Tagged Releases (v1.0.0, v1.1.0, etc.)
- **DMG File**: `RouteX-v1.0.0.dmg` - Professional installer disk image
- **ZIP File**: `RouteX.zip` - Simple archive that extracts to `RouteX.app/`
- **GitHub Release**: Published with both files attached
- **Release Notes**: Automatically generated from commits

### For Manual Triggers
- **DMG File**: `RouteX-dev-20250127-143022.dmg` (timestamped)
- **ZIP File**: `RouteX.zip`
- **Artifacts**: Uploaded to Actions tab for download

## 🎯 DMG vs ZIP Files

### DMG File (Recommended)
- **Professional appearance**: Looks like official macOS installers
- **Easy installation**: Users just drag RouteX to Applications
- **Standard format**: What users expect from macOS apps
- **Better for distribution**: More professional for releases

### ZIP File (Alternative)
- **Simple extraction**: Users extract and get `RouteX.app/`
- **Cross-platform**: Works on any system that can extract ZIP
- **Smaller file size**: Usually smaller than DMG
- **Easy to test**: Quick extraction for testing

## 🔧 Workflow Features

### Universal Binary
- **Apple Silicon (M1/M2/M3)**: Native ARM64 performance
- **Intel Macs**: x86_64 compatibility
- **Single file**: Works on both architectures

### App Bundle Structure
```
RouteX.app/
├── Contents/
│   ├── MacOS/
│   │   └── RouteX (universal binary)
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── AppIcon.icns
│   └── Info.plist
```

### Automatic Features
- **Version detection**: From git tags or timestamps
- **Icon creation**: Converts PNG icons to .icns format
- **DMG verification**: Ensures DMG file integrity
- **Checksums**: SHA256 hashes for security verification

## 📋 Release Process Steps

### 1. Prepare for Release
```bash
# Ensure all changes are committed
git add .
git commit -m "Prepare for v1.0.0 release"

# Push to main branch
git push origin main
```

### 2. Create Release
```bash
# Create and push tag
git tag v1.0.0
git push origin v1.0.0
```

### 3. Monitor Progress
1. Go to **Actions** tab in GitHub
2. Watch the **Build and Release** workflow
3. Check for any build errors
4. Wait for completion (usually 5-10 minutes)

### 4. Verify Release
1. Go to **Releases** tab in GitHub
2. Check that both DMG and ZIP files are attached
3. Verify the release notes are accurate
4. Test the DMG file on a clean system

## 🛠️ Troubleshooting

### Common Issues

**Build Fails**
- Check Swift version compatibility
- Ensure all dependencies are available
- Verify the build.sh script has execute permissions

**DMG Creation Fails**
- Check available disk space
- Verify app bundle structure is correct
- Ensure hdiutil is available (should be on macOS)

**Release Not Created**
- Verify the tag follows `v*` pattern (v1.0.0, v2.1.0, etc.)
- Check GitHub token permissions
- Ensure workflow file is in `.github/workflows/`

### Debugging Steps

1. **Check Workflow Logs**
   - Go to Actions tab
   - Click on the failed workflow
   - Review the step-by-step logs

2. **Test Locally**
   ```bash
   # Test the build script locally
   ./build.sh
   
   # Test DMG creation
   hdiutil create -volname "RouteX Test" -srcfolder build/RouteX.app -ov -format UDZO RouteX-test.dmg
   ```

3. **Verify Dependencies**
   - Swift 6.1 or later
   - Xcode Command Line Tools
   - macOS 12.0+ (for GitHub Actions)

## 📈 Best Practices

### Version Naming
- Use semantic versioning: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Avoid pre-release tags unless testing: `v1.0.0-beta`
- Use descriptive commit messages for better release notes

### Release Notes
- The workflow generates notes automatically from commits
- Add detailed descriptions in the release body
- Include installation instructions
- List system requirements

### Testing
- Test DMG files on clean macOS systems
- Verify both Apple Silicon and Intel compatibility
- Check that app icons display correctly
- Test administrator privilege prompts

## 🔗 Useful Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Releases API](https://docs.github.com/en/rest/releases)
- [macOS DMG Creation](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html)
- [RouteX Repository](https://github.com/awgh/routex)

## 🎯 Quick Commands

```bash
# Create a new release
git tag v1.0.0
git push origin v1.0.0

# Create a patch release
git tag v1.0.1
git push origin v1.0.1

# Create a minor release
git tag v1.1.0
git push origin v1.1.0

# Create a major release
git tag v2.0.0
git push origin v2.0.0
```

---

Your RouteX release workflow is now ready! Users can easily download and install your app using either the professional DMG installer or the simple ZIP archive. 