# LuaRocks Publishing Guide

This guide explains how to publish Orbit Jump to LuaRocks and manage releases.

## Prerequisites

1. **LuaRocks Account**: You need an account on [LuaRocks.org](https://luarocks.org)
2. **API Key**: Generate an API key from your LuaRocks account
3. **Git Repository**: Ensure your repository is public and accessible

## Package Structure

The Orbit Jump package includes:

- **Core Game Modules**: Game logic, state management, system orchestration
- **Game Systems**: Analytics, collision, emotion, performance, player systems
- **UI Components**: Screens, components, debug tools, tutorial systems
- **Utilities**: Math, rendering, data handling, hot reload
- **External Libraries**: JSON library
- **Documentation**: README, contributing guidelines, architecture docs
- **Tests**: Comprehensive test suite with multiple frameworks

## Files for Publishing

### Essential Files

- `orbit-jump-1.0.0-1.rockspec` - Package specification
- `main.lua` - Entry point
- `README.md` - Documentation
- `LICENSE` - MIT license
- `install.lua` - Installation script

### Core Modules

- `src/core/` - Core game systems
- `src/systems/` - Game features and mechanics
- `src/ui/` - User interface components
- `src/utils/` - Utility functions
- `libs/` - External libraries

## Publishing Process

### 1. Prepare the Package

```bash
# Validate package structure
lua scripts/publishing/test_package.lua

# Test local installation
luarocks build orbit-jump-1.0.0-2.rockspec --local
```

### 2. Create Release

```bash
# Create and push git tag
git tag v1.0.0
git push origin v1.0.0

# Ensure rockspec points to correct tag
# Update source URL in rockspec if needed
```

### 3. Upload to LuaRocks

```bash
# Upload the package
luarocks upload orbit-jump-1.0.0-2.rockspec

# You'll be prompted for:
# - Username
# - API key
# - Confirmation
```

### 4. Verify Installation

```bash
# Test installation from LuaRocks
luarocks install orbit-jump

# Run the game
love orbit-jump
```

## Version Management

### Version Format

- Format: `major.minor.patch-revision`
- Example: `1.0.0-1`, `1.1.0-1`, `1.0.1-1`

### Updating Versions

1. **Update rockspec file**:

   ```lua
   version = "1.0.1-1"  -- New version
   source = {
      url = "git+https://github.com/Hydepwns/orbit-jump.git",
      tag = "v1.0.1"    -- New tag
   }
   ```

2. **Create new git tag**:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

3. **Upload new version**:

   ```bash
   luarocks upload orbit-jump-1.0.1-1.rockspec
   ```

## Dependencies

The package requires:

- **Lua >= 5.3**: Core language support
- **LÖVE2D >= 11.0**: Game engine

## Testing Before Publishing

### Local Testing

```bash
# Build locally
luarocks build orbit-jump-1.0.0-2.rockspec --local

# Test installation
luarocks install orbit-jump --local

# Run tests
./run_tests.sh
```

### Package Validation

```bash
# Run validation script
lua scripts/publishing/test_package.lua

# Check all files exist
ls -la orbit-jump-1.0.0-2.rockspec LICENSE README.md main.lua
```

## Troubleshooting

### Common Issues

1. **Module not found errors**:
   - Check module paths in rockspec
   - Ensure all required files exist
   - Verify module naming consistency

2. **Dependency issues**:
   - Update dependency versions in rockspec
   - Test with minimal dependencies first

3. **Upload failures**:
   - Check API key validity
   - Ensure package name is unique
   - Verify rockspec syntax

### Validation Checklist

- [ ] All essential files present
- [ ] Rockspec syntax valid
- [ ] Module paths correct
- [ ] Dependencies specified
- [ ] Documentation complete
- [ ] License included
- [ ] Git tag created and pushed
- [ ] Local build successful
- [ ] Tests pass

## Maintenance

### Regular Updates

- Monitor for dependency updates
- Update documentation as needed
- Test with new LÖVE2D versions
- Maintain compatibility with Lua versions

### Deprecation

- Mark deprecated versions appropriately
- Provide migration guides
- Maintain backward compatibility when possible

## Resources

- [LuaRocks Documentation](https://github.com/luarocks/luarocks/wiki)
- [LuaRocks Package Guidelines](https://github.com/luarocks/luarocks/wiki/Creating-a-rock)
- [LÖVE2D Documentation](https://love2d.org/wiki/)
- [Lua Documentation](https://www.lua.org/manual/)

## Success! 🎉

Orbit Jump has been successfully published to LuaRocks!

- **Package URL**: https://luarocks.org/modules/hydepwns/orbit-jump
- **Current Version**: 1.0.0-2
- **Installation**: `luarocks install orbit-jump`
- **Status**: ✅ Published and verified

### Verification

The package has been tested and verified to work correctly:
- ✅ Package structure validated
- ✅ Dependencies resolved
- ✅ Installation successful
- ✅ Module loading confirmed

## Support

For issues with the package:

1. Check the [GitHub repository](https://github.com/Hydepwns/orbit-jump)
2. Review the documentation
3. Run the test suite
4. Create an issue with detailed information

---

**Note**: This guide is specific to Orbit Jump. For general LuaRocks publishing information, refer to the official LuaRocks documentation.
