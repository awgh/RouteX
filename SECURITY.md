# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Model

### Permissions Required

RouteX requires the following system permissions to function:

1. **Administrator Privileges**
   - **Purpose**: Modify network routing tables
   - **Commands**: `/sbin/route add/delete`, `/usr/sbin/netstat`
   - **Scope**: System-wide network configuration
   - **Risk Level**: High (can affect network connectivity)

2. **Network Access**
   - **Purpose**: Read current routing table
   - **Commands**: `/usr/sbin/netstat -rn`
   - **Scope**: Read-only access to network configuration
   - **Risk Level**: Low (read-only)

3. **File System Access**
   - **Purpose**: Cache phantom route destinations
   - **Location**: `~/Library/Preferences/com.routex.app.plist`
   - **Scope**: User preferences only
   - **Risk Level**: Low (user data only)

### Code Signing

- **Signature Type**: Ad-hoc (self-signed)
- **Developer**: awgh@awgh.org
- **Notarization**: Not Apple notarized
- **Gatekeeper**: Will be blocked by default

**Why Ad-hoc Signing?**
- RouteX is open-source software
- No Apple Developer Program membership required
- Users can verify source code integrity
- Community-driven development model

### Security Considerations

#### What RouteX CAN Do
- ✅ Read your current network routing table
- ✅ Add new static routes to the kernel
- ✅ Delete user-created routes
- ✅ Modify route properties (gateway, interface, flags)
- ✅ Cache phantom route destinations locally

#### What RouteX CANNOT Do
- ❌ Access your personal files
- ❌ Send data over the network
- ❌ Access other applications
- ❌ Modify system routes (protected)
- ❌ Persist across reboots (routes are kernel-managed)
- ❌ Access your browsing history or personal data

#### What RouteX DOES NOT Do
- 📡 No network communication (except route commands)
- 📊 No analytics or telemetry
- 🔍 No data collection
- 🌐 No internet access
- 📱 No mobile device access

## Security Best Practices

### For Users

1. **Verify Source**
   ```bash
   # Clone from official repository
   git clone https://github.com/awgh/RouteX.git
   
   # Verify commit signatures (if available)
   git log --show-signature
   ```

2. **Build from Source**
   ```bash
   # Build locally to ensure integrity
   ./build.sh
   
   # Verify the build
   codesign -dv build/DerivedData/Build/Products/Release/RouteX.app
   ```

3. **Test in Safe Environment**
   - Use a test machine or VM
   - Backup current routing table
   - Test with non-critical routes first

4. **Monitor Network Changes**
   ```bash
   # Before making changes
   netstat -rn > ~/Desktop/routes_before.txt
   
   # After making changes
   netstat -rn > ~/Desktop/routes_after.txt
   
   # Compare changes
   diff routes_before.txt routes_after.txt
   ```

### For Developers

1. **Code Review**
   - All changes require pull request review
   - Security-sensitive code gets extra scrutiny
   - Automated security checks in CI/CD

2. **Dependency Management**
   - Minimal external dependencies
   - Regular dependency updates
   - Security vulnerability scanning

3. **Testing**
   - Unit tests for all route operations
   - Integration tests for system commands
   - Security-focused test cases

## Vulnerability Reporting

### How to Report

1. **Email**: awgh@awgh.org
2. **GitHub Issues**: [Security Issues](https://github.com/awgh/RouteX/issues)
3. **Private Disclosure**: Use GitHub's private reporting feature

### What to Include

- **Description**: Clear explanation of the vulnerability
- **Steps to Reproduce**: Detailed reproduction steps
- **Impact Assessment**: Potential security implications
- **Suggested Fix**: If you have ideas for remediation
- **Contact Information**: How to reach you for follow-up

### Response Timeline

- **Initial Response**: Within 48 hours
- **Assessment**: Within 1 week
- **Fix Development**: 1-4 weeks (depending on complexity)
- **Public Disclosure**: After fix is available

### Responsible Disclosure

- **No Public Disclosure**: Until fix is available
- **Credit**: Given to reporters in release notes
- **Coordination**: With affected users when necessary
- **Transparency**: Full disclosure after resolution

## Security Features

### Input Validation

1. **IP Address Validation**
   - IPv4 and IPv6 format checking
   - CIDR notation validation
   - Invalid address rejection

2. **Route Flag Validation**
   - Mutual exclusion checking
   - Valid flag combinations
   - System protection

3. **Gateway Validation**
   - IP address format
   - Interface name validation
   - MAC address format

### System Protection

1. **Route Editability**
   - Only user routes can be modified
   - System routes are protected
   - Kernel routes are preserved

2. **Privilege Escalation**
   - Minimal privilege usage
   - Temporary elevation only
   - Proper privilege cleanup

3. **Error Handling**
   - Graceful failure modes
   - User-friendly error messages
   - System state preservation

## Privacy

### Data Collection

**RouteX collects NO data:**
- ❌ No analytics
- ❌ No telemetry
- ❌ No crash reporting
- ❌ No usage statistics
- ❌ No personal information

### Local Storage

**Only stores:**
- ✅ Phantom route cache (UserDefaults)
- ✅ UI preferences (UserDefaults)
- ✅ Route type preferences (UserDefaults)

**Location:**
- `~/Library/Preferences/com.routex.app.plist`

**Content:**
- Phantom route destinations (IP addresses)
- UI state preferences
- No personal or sensitive data

### Network Communication

**RouteX makes NO network requests:**
- ❌ No HTTP/HTTPS requests
- ❌ No API calls
- ❌ No external services
- ❌ No cloud synchronization

**Only system commands:**
- ✅ `/sbin/route` (local)
- ✅ `/usr/sbin/netstat` (local)
- ✅ `/sbin/ifconfig` (local)

## Compliance

### Open Source Compliance

- **License**: GNU General Public License v3.0
- **Source Code**: Fully available on GitHub
- **Modifications**: Allowed under GPL v3
- **Distribution**: Free and open

### macOS Compliance

- **Sandboxing**: Not applicable (requires system access)
- **App Store**: Not distributed via App Store
- **Notarization**: Not required for sideloading
- **Gatekeeper**: User must explicitly allow

### Security Standards

- **OWASP**: Follows secure coding practices
- **CWE**: Avoids common vulnerability patterns
- **Secure by Default**: Minimal attack surface
- **Defense in Depth**: Multiple security layers

## Incident Response

### Security Incidents

1. **Detection**
   - Automated security scanning
   - Community bug reports
   - Security researcher disclosures

2. **Assessment**
   - Impact analysis
   - Affected user identification
   - Remediation planning

3. **Response**
   - Immediate fix development
   - User notification
   - Public disclosure

4. **Recovery**
   - Fix deployment
   - Verification testing
   - Documentation updates

### Communication

- **Users**: Via GitHub releases and issues
- **Security Researchers**: Direct email contact
- **Community**: Transparent disclosure process
- **Media**: Official statements when necessary

---

**Last Updated**: January 2025  
**Contact**: awgh@awgh.org  
**Repository**: https://github.com/awgh/RouteX 