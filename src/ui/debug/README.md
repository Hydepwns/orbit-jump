# UI Debug Tools

This directory contains advanced debugging tools for UI development and troubleshooting in Orbit Jump.

## Files

- **`ui_debug.lua`** - Basic UI debugging system
  - Element boundary visualization
  - Real-time positioning display
  - Toggle-able debug overlays
  
- **`ui_debug_enhanced.lua`** - Advanced debugging framework
  - Performance monitoring
  - Memory usage tracking
  - Multi-theme debug visualization
  - Screenshot generation
  - Automated validation rules
  - Interactive debugging tools

## Usage

### In-Game Debug Controls

- **F12** - Toggle UI debug visualization
- **F11** - Validate current layout
- **F10** - Cycle debug levels  
- **F9** - Switch debug themes
- **F8** - Take screenshot

### Programmatic Usage

```lua
local UIDebug = require("src.ui.debug.ui_debug_enhanced")

-- Initialize debug system
UIDebug.init()

-- Enable debug rendering
UIDebug.enabled = true
UIDebug.showBounds = true
UIDebug.showLabels = true

-- Validate element positioning
local issues = UIDebug.validateElement(elementData)

-- Take performance snapshot
UIDebug.capturePerformanceSnapshot()
```

## Features

### Visual Debugging
- Color-coded element boundaries
- Performance warning indicators
- Real-time metrics overlay
- Multiple debug themes

### Performance Monitoring
- Frame time tracking
- Memory usage analysis
- Bottleneck detection
- Performance regression alerts

### Validation Tools
- Layout rule validation
- Accessibility compliance checks
- Touch target size verification
- Responsive design testing

## Integration

These tools are automatically integrated with:
- Main UI system (`src.ui.ui_system`)
- Layout tests (`tests/ui/layout/`)
- Development workflows
- CI/CD testing pipeline

## Configuration

Debug behavior can be configured via:
- Environment variables
- Runtime configuration
- Development settings
- Per-test overrides