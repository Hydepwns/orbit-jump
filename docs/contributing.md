# Contributing

## Development Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Hydepwns/orbit-jump.git
   cd orbit-jump
   ```

2. **Install LÖVE 2D:**

   ```bash
   # macOS
   brew install love
   
   # Linux
   sudo apt install love2d
   ```

3. **Run tests:**

   ```bash
   ./run_tests.sh
   ```

## Code Style

### Lua Conventions

- **Indentation**: 4 spaces
- **Naming**: `snake_case` for functions and variables
- **Constants**: `UPPER_SNAKE_CASE`
- **Modules**: PascalCase for module names

```lua
local function calculate_jump_power(base_power, multiplier)
    local GRAVITY_CONSTANT = 1000
    return base_power * multiplier
end
```

### File Organization

- One module per file
- Clear separation of concerns
- Facade pattern for public APIs

## Testing

### Requirements

- Unit tests for all public functions
- Integration tests for system interactions
- Performance tests for optimization claims

### Running Tests

```bash
./run_tests.sh unit          # Unit tests
./run_tests.sh integration   # Integration tests
./run_tests.sh performance   # Performance tests
```

## Architecture

### Guidelines

- Single responsibility per module
- Clear interfaces between systems
- Zero allocation in hot paths
- Graceful error handling

### Performance

- Object pooling for frequently created objects
- Profile before optimizing
- Monitor memory usage
