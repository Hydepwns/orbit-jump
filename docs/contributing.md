# Contributing

Thank you for your interest in contributing to Orbit Jump! This guide will help you get started.

## Development Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Hydepwns/orbit-jump.git
   cd orbit-jump
   ```

2. **Install dependencies:**

   ```bash
   # Install LÖVE 2D for testing
   # Install Lua 5.3+ for development tools
   ```

3. **Run tests to verify setup:**

   ```bash
   lua tests/run_modern_tests.lua
   ```

## Code Style

### Lua Conventions

- **Indentation**: 4 spaces (no tabs)
- **Naming**: `snake_case` for functions and variables
- **Constants**: `UPPER_SNAKE_CASE`
- **Modules**: PascalCase for module names

```lua
-- Good
local function calculate_jump_power(base_power, multiplier)
    local GRAVITY_CONSTANT = 1000
    return base_power * multiplier
end

-- Bad
local function calculateJumpPower(basePower,multiplier)
    local gravity_constant = 1000
    return basePower*multiplier
end
```

### File Organization

- **One module per file**
- **Clear separation of concerns**
- **Facade pattern for public APIs**
- **Internal modules in subdirectories**

### Documentation

- **Inline comments** for complex logic
- **Function documentation** for public APIs
- **Module headers** explaining purpose
- **No excessive commenting** for obvious code

## Architecture Guidelines

### Modular Design

- **Single responsibility** per module
- **Clear interfaces** between systems
- **Facade patterns** for backwards compatibility
- **Dependency injection** where possible

### Performance

- **Zero allocation** in hot paths
- **Object pooling** for frequently created objects
- **Circular buffers** for fixed-size collections
- **Profile before optimizing**

### Error Handling

- **Graceful degradation** for non-critical failures
- **Safe function calls** using Utils.ErrorHandler
- **Clear error messages** with context
- **Log errors** for debugging

## Testing Requirements

### Test Coverage

- **Unit tests** for all public functions
- **Integration tests** for system interactions
- **Performance tests** for optimization claims
- **Error handling tests** for failure scenarios

### Test Quality

- **Clear test names** describing what's being tested
- **Isolated tests** that don't depend on each other
- **Fast execution** (< 100ms per test)
- **Deterministic results** (no random failures)

### Writing Tests

```lua
local tests = {
    ["should calculate correct jump power"] = function()
        local result = PlayerAbilities.calculateJumpPower(300, 1.5)
        TestFramework.assert.assertEqual(450, result)
    end,
    
    ["should handle zero power gracefully"] = function()
        local result = PlayerAbilities.calculateJumpPower(0, 1.5)
        TestFramework.assert.assertEqual(0, result)
    end
}
```

## Pull Request Process

### Before Submitting

1. **Run all tests** and ensure they pass
2. **Check code style** using linting tools
3. **Update documentation** if needed
4. **Write descriptive commit messages**

### PR Requirements

- **Clear description** of changes
- **Link to related issues** if applicable
- **Screenshots/videos** for UI changes
- **Test evidence** for performance claims

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by maintainers
3. **Testing** of new features
4. **Documentation review** if applicable

## Issue Guidelines

### Bug Reports

- **Clear reproduction steps**
- **Expected vs actual behavior**
- **System information** (OS, LÖVE version)
- **Error messages** or logs if available

### Feature Requests

- **Use case description**
- **Proposed solution** (if you have ideas)
- **Alternatives considered**
- **Impact assessment** (breaking changes?)

### Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or improvement
- `documentation` - Documentation needs update
- `performance` - Performance-related issue
- `refactoring` - Code structure improvements

## Development Workflow

### Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/name` - Individual feature branches
- `bugfix/name` - Bug fix branches

### Commit Messages

```
type(scope): short description

Longer explanation if needed.

- Bullet points for multiple changes
- Reference issues with #123
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `perf`

## Code Review Checklist

### Functionality

- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled
- [ ] Error conditions are managed
- [ ] Performance is acceptable

### Code Quality

- [ ] Code follows style guidelines
- [ ] Functions are reasonably sized
- [ ] Names are descriptive
- [ ] Comments explain why, not what

### Testing

- [ ] Tests cover new functionality
- [ ] Tests pass consistently
- [ ] Performance tests validate claims
- [ ] Integration tests cover interactions

### Documentation

- [ ] Public APIs are documented
- [ ] Breaking changes are noted
- [ ] Examples are provided where helpful
- [ ] README is updated if needed

## Getting Help

- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and general discussion
- **Code Comments** - Inline documentation explains complex parts
- **Architecture Docs** - See `docs/architecture.md` for system design

## Recognition

Contributors are recognized in:

- **Git commit history** - Your commits remain attributed
- **Release notes** - Significant contributions are highlighted
- **Contributors file** - Major contributors are listed

## License

By contributing to Orbit Jump, you agree that your contributions will be licensed under the same license as the project.
