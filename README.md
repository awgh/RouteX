# RouteX - Because Apple's Route Flags Are Weird

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange)](https://swift.org/)
[![License](https://img.shields.io/badge/License-GPL%20v3-green)](LICENSE)

RouteX is a graphical interface for people who can't be bothered to learn Apple's non-standard route flags. Because honestly, who can remember two different sets of flags for a command with the same name? And don't even get me started on the bizarre CIDR shorthand or "invisible" routes.

This app gives you a nice, clickable interface to manage your network routes without having to memorize macOS's quirky command-line syntax. Perfect for network administrators who prefer GUIs over man pages, and power users who just want to get things done without the terminal gymnastics.

## Features

### 🚀 Core Route Management
- **Add, Edit, Delete Routes**: Complete route lifecycle management with elevated privileges
- **Route Type Control**: Explicit selection between Auto, Network, and Host routes
- **Smart Destination Interpretation**: Automatic handling of macOS routing shorthand and CIDR notation
- **Real-time Validation**: Input validation with helpful error messages and suggestions

### 🎯 Advanced Routing Features
- **Route Flags Support**:
  - **Static (S)**: Manually configured routes
  - **Reject (R)**: Emit ICMP unreachable when matched
  - **Blackhole (b)**: Silently discard packets  
  - **Link Info (L)**: Validly translates protocol address to link address
- **Advanced Metrics**: MTU, hop count, RTT, RTT variance, send/receive pipe, SS threshold
- **Interface Scope**: Route traffic through specific network interfaces
- **Gateway Types**: IP addresses, interface names, and MAC addresses

### 🔍 Phantom Route Discovery
- **Blackhole/Reject Detection**: Automatically discovers routes that don't appear in `netstat`
- **Persistent Tracking**: Maintains cache of phantom routes across app restarts
- **Visual Indicators**: Orange eye-slash icon (👁️‍🗨️) for phantom routes in the route list

### 🧠 Smart Input Handling
- **macOS Shorthand Support**: 
  - `"172.1"` → `"172.0.0.1"` (host) or `"172.1.0.0/16"` (network)
  - `"192.168"` → `"192.168.0.0/16"` (network)
- **CIDR Notation**: Full support including shorthand (`"172.16.42/24"`)
- **Special Cases**: `/32` CIDR treated as host route, others as network routes

### 🛡️ Safety & Validation
- **Mutual Exclusion Checking**: Prevents conflicting flag combinations (e.g., Blackhole + Reject)
- **Route Editability**: Only user-manageable routes can be modified (system routes protected)
- **Input Sanitization**: IPv6 zone identifier handling and address validation

### 🎨 Modern UI
- **SwiftUI Interface**: Native macOS design with proper spacing and typography
- **Advanced Options Panel**: Collapsible section for power-user features
- **Search & Filter**: Find routes by destination, gateway, or interface
- **Route Specificity Sorting**: Most specific routes displayed first
- **Status Indicators**: Clear visual feedback for route types and states

## Installation

### Requirements
- **macOS 12.0 or later**
- **Administrator privileges** (required for route modification)

### Build from Source
```bash
git clone https://github.com/yourusername/routex.git
cd routex
./build.sh
```

The built application will be located at `build/RouteX.app`

### Running
1. Open `RouteX.app`
2. Grant administrator privileges when prompted for route modifications
3. Start managing your network routes!

## Usage Guide

### Adding a Route

1. **Click "Add Route"** to open the route creation dialog
2. **Configure Basic Settings**:
   - **Destination**: Enter IP address, network, or use macOS shorthand
   - **Gateway**: IP address, interface name (e.g., `en0`), or MAC address
   - **Interface**: Select specific interface or leave blank for automatic
   - **Route Type**: Choose Auto, Network, or Host

3. **Advanced Options** (optional):
   - **Route Flags**: Select Blackhole, Reject, or Link Info as needed
   - **Metrics**: Configure MTU, hop count, RTT values, etc.

4. **Click "Add Route"** and provide administrator credentials

### Route Types Explained

| Type | Description | Use Case |
|------|-------------|----------|
| **Auto** | RouteX determines type based on destination format | General use, recommended |
| **Network** | Forces network route (`-net` flag) | Routing to subnets/networks |
| **Host** | Forces host route (`-host` flag) | Routing to specific hosts |

### Route Flags Guide

| Flag | Symbol | Description | Command |
|------|--------|-------------|---------|
| **Static** | S | Manually configured route | `-static` |
| **Reject** | R | Send ICMP unreachable | `-reject` |
| **Blackhole** | b | Silently drop packets | `-blackhole` |
| **Link Info** | L | Link-level information | `-llinfo` |

### Destination Format Examples

| Input | Host Route Result | Network Route Result |
|-------|------------------|---------------------|
| `172.1` | `172.0.0.1/32` | `172.1.0.0/16` |
| `192.168.1` | `192.168.0.1/32` | `192.168.1.0/24` |
| `172.16.42/24` | Invalid | `172.16.42.0/24` |
| `10.0.0.1/32` | `10.0.0.1/32` | `10.0.0.1/32` (special case) |
| `10.0.0.1` | `10.0.0.1/32` | `10.0.0.1/32` |

## Technical Details

### Build System
RouteX uses **Swift Package Manager** for building and testing:
- **Build Command**: `swift build -c release`
- **Test Command**: `swift test`
- **Package Structure**: Standard Swift Package Manager layout
- **Dependencies**: Managed through `Package.swift`

### System Integration
RouteX integrates with macOS routing using:
- **Route Commands**: `/sbin/route add/delete/get`
- **Network Status**: `/usr/sbin/netstat -rn` 
- **Elevated Execution**: `osascript` with administrator privileges
- **Interface Detection**: `/sbin/ifconfig`

### Route Command Generation
Commands are generated with proper flag ordering:
```bash
/sbin/route add -net -blackhole 192.168.97.0 192.168.1.1
```

### Phantom Route Discovery
Some routes (blackhole, reject) don't appear in `netstat` but exist in the kernel:
- **Detection**: Uses `route get <destination>` to find hidden routes
- **Caching**: Stores phantom destinations in `UserDefaults`
- **Visual Feedback**: Special UI indicators for phantom routes

### Data Persistence
- **Route Cache**: Phantom route destinations cached across sessions
- **User Preferences**: Route type preferences and UI state
- **No Route Storage**: Routes are managed entirely by macOS kernel

## Troubleshooting

### Common Issues

**"Access denied" errors**
- Ensure you're providing administrator credentials when prompted
- RouteX requires elevated privileges to modify system routing table

**Routes not appearing after creation**
- Check if route has blackhole/reject flags (appears as phantom route with eye-slash icon)
- Verify destination format is correct
- Use "Refresh" to reload route list

**Input validation errors**
- Review destination format (use examples above)
- Check for conflicting flag combinations (Blackhole + Reject)
- Ensure gateway format matches selected type (IP/Interface/MAC)

### Debug Information
For technical support, check Console.app for RouteX debug output when creating routes.

## Architecture

### Key Components
- **RouteManager**: Core routing logic and system integration
- **RouteModel**: Data structures and route interpretation
- **AddRouteView**: Route creation/editing interface
- **ContentView**: Main route list and management
- **CustomTooltip**: Enhanced help system

### Build Scripts
- **`build.sh`**: Swift Package Manager build script with app bundle creation
- **`run_tests.sh`**: Test runner using Swift Package Manager
- **GitHub Actions**: Automated CI/CD with Swift Package Manager

### Design Principles
- **Safety First**: Protect system routes from accidental modification
- **User-Friendly**: Hide complexity while providing power-user features
- **macOS Native**: Follow Apple's design guidelines and system integration patterns
- **Robust Validation**: Prevent invalid configurations before they reach the system

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to RouteX.

## License

RouteX is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

## Acknowledgments

- **macOS Routing Documentation**: References from [AnalysisMan's macOS routing guide](https://www.analysisman.com/2020/11/macos-staticroutes.html)
- **Enterprise Routing**: Inspired by enterprise firewall routing interfaces like [Sophos Firewall](https://docs.sophos.com/nsg/sophos-firewall/21.0/help/en-us/webhelp/onlinehelp/AdministratorHelp/Routing/StaticRouting/RoutingUnicastRouteAdd/index.html)
- **SwiftUI Community**: For modern macOS app development patterns

---

**⚠️ Important**: RouteX modifies your system's routing table. Always test route changes in a safe environment before applying them to production systems. Incorrect routing configurations can disrupt network connectivity. 