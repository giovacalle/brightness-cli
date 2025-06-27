# Brightness CLI

A command-line utility for macOS that allows you to retrieve and set the brightness of connected displays, including both built-in and external monitors.

_Note: This tool works just on Apple Silicon Macs._

## Features

- **Display Detection**: Automatically detects all connected displays (built-in and external)
- **Brightness Retrieval**: Get current brightness levels for all supported displays
- **Brightness Control**: Set brightness levels for specific displays
- **JSON Output**: Display information is output in JSON format for easy parsing
- **External Monitor Support**: Works with external monitors via DDC (Display Data Channel) protocol
- **Apple Silicon Compatibility**: Optimized for Apple Silicon Macs

## Requirements

- macOS 13.0 or later
- Swift 5.7 or later
- Xcode command line tools

## Installation

### Building from Source

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd brightness-cli
   ```

2. Build the project:

   ```bash
   swift build -c release
   ```

3. The executable will be available at `.build/release/brightness-cli`

4. (Optional) Copy to a directory in your PATH:
   ```bash
   cp .build/release/brightness-cli /usr/local/bin/
   ```

## Usage

### Detect Connected Displays

To list all connected displays with their current brightness levels:

```bash
brightness-cli
# or explicitly
brightness-cli detect-displays
```

Example output:

```json
[
  {
    "id": 69733378,
    "name": "Built-in Display",
    "isBuiltIn": true,
    "brightness": 0.75,
    "isSupported": true
  },
  {
    "id": 724238340,
    "name": "External Monitor",
    "isBuiltIn": false,
    "brightness": 0.5,
    "isSupported": true
  }
]
```

### Set Display Brightness

To set the brightness of a specific display:

```bash
brightness-cli set-brightness <display-id> <brightness-value>
```

- `display-id`: The ID of the display (obtained from the detect-displays command)
- `brightness-value`: A float value between 0.0 (minimum) and 1.0 (maximum)

Example:

```bash
# Set brightness to 75% for display with ID 69733378
brightness-cli set-brightness 69733378 0.75

# Set brightness to 25% for display with ID 724238340
brightness-cli set-brightness 724238340 0.25
```

### Help

Get help for the main command:

```bash
brightness-cli --help
```

Get help for specific subcommands:

```bash
brightness-cli detect-displays --help
brightness-cli set-brightness --help
```

## Technical Details

### Display Types

- **Built-in Displays**: Uses the private DisplayServices framework for precise brightness control
- **External Displays**: Uses DDC (Display Data Channel) protocol via the AppleSiliconDDC library

### Supported External Monitors

The tool works with external monitors that support DDC communication. Most modern monitors connected via:

- DisplayPort
- USB-C/Thunderbolt

_Note: HDMI connections may have limited or no DDC support depending on the monitor and connection_

### Dependencies

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser): For CLI argument parsing
- [AppleSiliconDDC](https://github.com/waydabber/AppleSiliconDDC): For external display brightness control on Apple Silicon

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Credits

Special thanks to the [AppleSiliconDDC](https://github.com/waydabber/AppleSiliconDDC) repository, without which this project would not be possible. The ability to control external monitor brightness on Apple Silicon Macs is entirely dependent on this excellent library.
