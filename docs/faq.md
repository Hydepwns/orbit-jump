# frequently asked questions

## gameplay

### how do i jump between planets?

click and drag from your current planet to aim your jump. the further you drag, the more power you'll use. release to launch! the trajectory preview helps you plan your jump.

### what are the glowing rings for?

rings are collectibles that serve multiple purposes:
- increase your score
- provide resources for upgrades
- unlock new abilities
- create satisfying chain combos

### how does the warp drive work?

once unlocked, the warp drive allows instant travel between discovered planets:
1. press w or click the warp button
2. select a discovered planet
3. confirm if you have enough energy

the warp system learns your habits and reduces costs for frequently traveled routes.

### why do some jumps cost less energy over time?

the adaptive learning system recognizes patterns in your gameplay:
- frequently used routes become cheaper
- emergency situations trigger compassion mode
- skill improvements reduce overall costs
- exploration of new areas is incentivized

### what are the different planet types?

- **normal planets** - standard gravity and size
- **dense planets** - stronger gravity, harder to escape
- **gas giants** - massive with wide gravity wells
- **asteroid clusters** - small with weak gravity
- **special planets** - unique properties and rewards

## technical

### what are the system requirements?

minimum:
- any system that runs löve2d 11.0+
- 100mb free disk space
- opengl 2.1 support

recommended:
- 2gb ram for smooth performance
- dedicated graphics for particle effects

### how do i install the game?

1. install löve2d for your platform
2. download orbit jump
3. run with `love .` in the game directory

see [getting started](getting-started.md) for detailed instructions.

### why is the game running slowly?

try these performance optimizations:
- reduce window size in conf.lua
- disable particle effects
- ensure no other heavy applications running
- update graphics drivers

### can i play with a controller?

currently, orbit jump is designed for mouse/touch input. controller support is planned for future updates.

### does the game save my progress?

yes! the game automatically saves:
- player statistics and achievements
- discovered planets
- upgrade progress
- warp route memory
- preference settings

saves are stored locally and persist between sessions.

## development

### how can i contribute?

we welcome contributions! see [contributing](contributing.md) for guidelines. areas where help is appreciated:
- bug fixes and performance improvements
- new planet types and mechanics
- ui/ux enhancements
- documentation improvements
- translations

### what technology stack is used?

- **engine**: löve2d (lua-based game framework)
- **language**: lua 5.3+
- **architecture**: modular ecs-inspired design
- **testing**: custom framework with 95%+ coverage
- **performance**: zero-allocation hot paths

### how is the adaptive ai implemented?

the learning systems use:
- pattern recognition for player behavior
- statistical analysis of gameplay metrics
- emotional state inference
- dynamic difficulty adjustment
- persistent memory across sessions

see [analytics system](systems/analytics.md) for details.

### why lua instead of a compiled language?

lua offers:
- rapid iteration during development
- excellent löve2d integration
- surprisingly good performance
- easy modding potential
- clean, readable code

performance-critical sections are heavily optimized.

## troubleshooting

### the game won't start

1. verify löve2d is installed correctly
2. check you're in the game directory
3. ensure all files were extracted
4. try running `love --version` to test löve2d

### i can't see my mouse cursor

the game uses a custom cursor. if it's not visible:
- check if cursor is outside game window
- try windowed mode instead of fullscreen
- update graphics drivers

### my progress was lost

save files are stored in:
- **windows**: %appdata%/LOVE/orbit-jump/
- **macos**: ~/Library/Application Support/LOVE/orbit-jump/
- **linux**: ~/.local/share/love/orbit-jump/

backup these files to preserve progress.

### the warp drive won't unlock

the warp drive unlocks after:
- discovering 10+ planets
- achieving certain progression milestones
- completing specific challenges

keep exploring and it will unlock naturally!

## community

### where can i report bugs?

please report bugs on our [github issues](https://github.com/Hydepwns/orbit-jump/issues) page with:
- detailed description
- steps to reproduce
- system information
- screenshots if applicable

### is there a discord or community?

not yet, but we're considering it based on player interest. for now, github discussions is the best place for community interaction.

### will there be multiplayer?

orbit jump is designed as a single-player experience focused on personal progression and mastery. multiplayer would require fundamental architecture changes.

### are there plans for mobile versions?

the game already supports touch input and runs on mobile devices with löve2d. official app store releases may come in the future.

### can i stream or make videos of the game?

absolutely! we encourage content creation. no special permission needed. we'd love to see your gameplay videos and speedruns.

## miscellaneous

### who created orbit jump?

orbit jump is an open-source project with contributors from around the world. see the credits for a full list of contributors.

### what inspired the game?

the game draws inspiration from:
- classic gravity-based games
- orbital mechanics simulations
- adaptive ai research
- emotional game design principles

### why is it called orbit jump?

the name reflects the core mechanic - jumping between orbital bodies using gravitational physics. simple, descriptive, memorable!

### is the source code available?

yes! orbit jump is fully open source under the mit license. you can view, modify, and contribute to the code on [github](https://github.com/Hydepwns/orbit-jump).

### how can i support the project?

- contribute code or documentation
- report bugs and suggest features
- share the game with friends
- create content about the game
- give us a star on github!