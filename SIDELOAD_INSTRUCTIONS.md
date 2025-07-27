# RouteX Sideload Instructions

## ⚠️ Important Security Notice

RouteX requires administrator privileges to modify network routing tables. This is a powerful capability that can affect your system's network connectivity. Please understand the implications before installing.

### What RouteX Does
- **Reads** your current network routing table
- **Modifies** network routes (adds, edits, deletes)
- **Requires** administrator privileges for route modifications
- **Runs** system commands (`/sbin/route`, `/usr/sbin/netstat`)

### Security Considerations
- RouteX is **not code-signed** by Apple (adhoc signature)
- You'll need to **trust the developer** (awgh@awgh.org)
- The app requires **administrator privileges** to function
- **Incorrect routing** can disrupt network connectivity
- **Always test** route changes in a safe environment first

## Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download** the latest release from GitHub:
   - Go to [RouteX Releases](https://github.com/awgh/RouteX/releases)
   - Download the `.dmg` file for your macOS version

2. **Mount and Install**:
   ```bash
   # Mount the DMG
   hdiutil attach RouteX-v1.0.dmg
   
   # Copy to Applications
   cp -r "/Volumes/RouteX v1.0/RouteX.app" /Applications/
   
   # Unmount
   hdiutil detach "/Volumes/RouteX v1.0"
   ```

3. **Trust the Developer**:
   - Go to **System Preferences** → **Security & Privacy** → **General**
   - Click **"Open Anyway"** when prompted about RouteX
   - Or run: `sudo spctl --master-disable` (temporarily)

### Method 2: Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/awgh/RouteX.git
   cd RouteX
   ```

2. **Build the app**:
   ```bash
   ./build.sh
   ```

3. **Install the built app**:
   ```bash
   cp -r build/RouteX.app /Applications/
   ```

## First Launch

### 1. Grant Administrator Privileges
When you first launch RouteX, you'll be prompted for administrator credentials:
- Enter your macOS administrator password
- Click **"OK"** to grant privileges

### 2. Trust the App
If macOS blocks the app:
- Go to **System Preferences** → **Security & Privacy** → **General**
- Click **"Open Anyway"** next to RouteX
- Or use Terminal: `sudo xattr -rd com.apple.quarantine /Applications/RouteX.app`

### 3. Verify Installation
- Launch RouteX from Applications
- The app should display your current network routes
- Try adding a test route to verify functionality

## Troubleshooting

### "App is damaged" Error
```bash
# Remove quarantine attribute
sudo xattr -rd com.apple.quarantine /Applications/RouteX.app

# Or disable Gatekeeper temporarily
sudo spctl --master-disable
```

### "Access denied" Errors
- Ensure you're providing administrator credentials
- Check that the app has proper permissions
- Verify your user account has admin privileges

### Network Issues After Route Changes
1. **Don't panic** - most issues are reversible
2. **Use RouteX** to delete problematic routes
3. **Restart networking** if needed:
   ```bash
   sudo ifconfig en0 down && sudo ifconfig en0 up
   ```
4. **As a last resort**, restart your Mac

### App Won't Launch
1. **Check Console.app** for error messages
2. **Verify permissions**: `ls -la /Applications/RouteX.app`
3. **Reinstall** the app if necessary
4. **Check macOS version** (requires 12.0+)

## Security Best Practices

### Before Using RouteX
1. **Backup** your current routing table:
   ```bash
   netstat -rn > ~/Desktop/routes_backup.txt
   ```
2. **Understand** what each route does
3. **Test** in a safe environment first
4. **Document** your changes

### While Using RouteX
1. **Verify** route destinations before adding
2. **Use** descriptive names for routes
3. **Test** connectivity after changes
4. **Keep** a record of modifications

### After Making Changes
1. **Verify** network connectivity
2. **Test** critical applications
3. **Document** successful configurations
4. **Monitor** for any issues

## Verification Commands

### Check App Integrity
```bash
# Verify code signature
codesign -dv /Applications/RouteX.app

# Check for malware (optional)
spctl --assess --verbose /Applications/RouteX.app
```

### Verify Network Routes
```bash
# View current routes
netstat -rn

# Check specific route
route get 8.8.8.8
```

### Test RouteX Functionality
1. **Add a test route** (e.g., to a local network)
2. **Verify** it appears in `netstat -rn`
3. **Delete** the test route
4. **Confirm** it's removed

## Support and Reporting Issues

### Getting Help
- **GitHub Issues**: [Report bugs](https://github.com/awgh/RouteX/issues)
- **Email**: awgh@awgh.org
- **Documentation**: [README.md](README.md)

### When Reporting Issues
Include:
- **macOS version** (System Information → Software)
- **RouteX version** (About RouteX)
- **Steps to reproduce**
- **Console.app logs** (if relevant)
- **Network configuration** (anonymized)

### Privacy and Data
- RouteX **does not** collect or transmit any data
- Route information **stays local** to your machine
- No analytics, tracking, or telemetry
- Source code is **open source** and auditable

## Legal and Licensing

### License
RouteX is licensed under the **GNU General Public License v3.0**
- **Free software**: You can use, modify, and distribute
- **Source available**: Full source code on GitHub
- **No warranty**: Use at your own risk

### Disclaimer
- **No warranty** of any kind
- **Use at your own risk**
- **Test thoroughly** before production use
- **Backup** important configurations

## Updates and Maintenance

### Checking for Updates
- **Watch** the GitHub repository for releases
- **Check** the releases page regularly
- **Follow** the developer on GitHub

### Updating RouteX
1. **Download** the new version
2. **Replace** the old app in Applications
3. **Grant** permissions again if needed
4. **Test** functionality

### Uninstalling
```bash
# Remove the app
rm -rf /Applications/RouteX.app

# Clean up preferences (optional)
defaults delete com.routex.app
```

---

**Remember**: RouteX is a powerful networking tool. Use it responsibly and always test changes in a safe environment first. 