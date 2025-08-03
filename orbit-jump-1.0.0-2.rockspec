package = "orbit-jump"
version = "1.0.0-2"
source = {
   url = "git+https://github.com/Hydepwns/orbit-jump.git",
   tag = "v1.0.0"
}
description = {
   summary = "A gravity-based arcade game with realistic physics and adaptive systems",
   detailed = [[
Orbit Jump is a physics-based arcade game featuring realistic orbital mechanics,
planet hopping gameplay, and adaptive systems that learn from player behavior.

Key Features:
- Physics-based movement with realistic orbital mechanics
- Planet hopping gameplay across diverse worlds
- Adaptive systems that learn from your playstyle
- Cross-platform support (Desktop and Mobile)
- Comprehensive test suite and development tools
- Modular architecture with extensive documentation

The game is built with LÖVE2D and includes a complete development environment
with testing frameworks, performance monitoring, and debugging tools.

Requirements:
- Lua 5.3 or higher
- LÖVE2D 11.0 or higher (install separately via system package manager)
   ]],
   homepage = "https://github.com/Hydepwns/orbit-jump",
   license = "MIT",
   maintainer = "DROO <drew@axol.io>"
}
dependencies = {
   "lua >= 5.3"
}
build = {
   type = "builtin",
   modules = {
      -- Core game modules
      ["src.core.game"] = "src/core/game.lua",
      ["src.core.game_state"] = "src/core/game_state.lua",
      ["src.core.system_orchestrator"] = "src/core/system_orchestrator.lua",
      ["src.core.camera"] = "src/core/camera.lua",
      ["src.core.renderer"] = "src/core/renderer.lua",
      ["src.core.game_logic"] = "src/core/game_logic.lua",
      
      -- Game systems
      ["src.systems.achievement_system"] = "src/systems/achievement_system.lua",
      ["src.systems.analytics.behavior_tracker"] = "src/systems/analytics/behavior_tracker.lua",
      ["src.systems.analytics.feedback_analytics"] = "src/systems/analytics/feedback_analytics.lua",
      ["src.systems.analytics.insight_generator"] = "src/systems/analytics/insight_generator.lua",
      ["src.systems.analytics.pattern_analyzer"] = "src/systems/analytics/pattern_analyzer.lua",
      ["src.systems.artifact_system"] = "src/systems/artifact_system.lua",
      ["src.systems.collision_system"] = "src/systems/collision_system.lua",
      ["src.systems.cosmic_events"] = "src/systems/cosmic_events.lua",
      ["src.systems.daily_streak_system"] = "src/systems/daily_streak_system.lua",
      ["src.systems.dynamic_config_system"] = "src/systems/dynamic_config_system.lua",
      ["src.systems.emotion.emotion_core"] = "src/systems/emotion/emotion_core.lua",
      ["src.systems.emotion.emotion_analytics_optimized"] = "src/systems/emotion/emotion_analytics_optimized.lua",
      ["src.systems.emotion.feedback_renderer"] = "src/systems/emotion/feedback_renderer.lua",
      ["src.systems.enhanced_pullback_indicator"] = "src/systems/enhanced_pullback_indicator.lua",
      ["src.systems.feedback_system"] = "src/systems/feedback_system.lua",
      ["src.systems.feedback_forms_system"] = "src/systems/feedback_forms_system.lua",
      ["src.systems.feedback_integration_system"] = "src/systems/feedback_integration_system.lua",
      ["src.systems.global_events_system"] = "src/systems/global_events_system.lua",
      ["src.systems.leaderboard_system"] = "src/systems/leaderboard_system.lua",
      ["src.systems.map_system"] = "src/systems/map_system.lua",
      ["src.systems.mastery_system"] = "src/systems/mastery_system.lua",
      ["src.systems.mobile_accessibility"] = "src/systems/mobile_accessibility.lua",
      ["src.systems.mystery_box_system"] = "src/systems/mystery_box_system.lua",
      ["src.systems.particle_system"] = "src/systems/particle_system.lua",
      ["src.systems.performance.performance_system"] = "src/systems/performance/performance_system.lua",
      ["src.systems.performance.performance_ui"] = "src/systems/performance/performance_ui.lua",
      ["src.systems.performance.performance_metrics"] = "src/systems/performance/performance_metrics.lua",
      ["src.systems.performance_overlay"] = "src/systems/performance_overlay.lua",
      ["src.systems.planet_lore"] = "src/systems/planet_lore.lua",
      ["src.systems.player_system"] = "src/systems/player_system.lua",
      ["src.systems.player.player_movement"] = "src/systems/player/player_movement.lua",
      ["src.systems.player.player_state"] = "src/systems/player/player_state.lua",
      ["src.systems.player.player_abilities"] = "src/systems/player/player_abilities.lua",
      ["src.systems.player_analytics"] = "src/systems/player_analytics.lua",
      ["src.systems.prestige_system"] = "src/systems/prestige_system.lua",
      ["src.systems.progression_system"] = "src/systems/progression_system.lua",
      ["src.systems.random_events_system"] = "src/systems/random_events_system.lua",
      ["src.systems.resolution_manager"] = "src/systems/resolution_manager.lua",
      ["src.systems.ring_system"] = "src/systems/ring_system.lua",
      ["src.systems.ring_constellations"] = "src/systems/ring_constellations.lua",
      ["src.systems.ring_rarity_system"] = "src/systems/ring_rarity_system.lua",
      ["src.systems.rival_system"] = "src/systems/rival_system.lua",
      ["src.systems.save_system"] = "src/systems/save_system.lua",
      ["src.systems.session_stats_system"] = "src/systems/session_stats_system.lua",
      ["src.systems.streak_system"] = "src/systems/streak_system.lua",
      ["src.systems.streak.streak_logic"] = "src/systems/streak/streak_logic.lua",
      ["src.systems.streak.streak_effects"] = "src/systems/streak/streak_effects.lua",
      ["src.systems.touch_gesture_system"] = "src/systems/touch_gesture_system.lua",
      ["src.systems.touch.gesture_definitions"] = "src/systems/touch/gesture_definitions.lua",
      ["src.systems.touch.gesture_recognition"] = "src/systems/touch/gesture_recognition.lua",
      ["src.systems.touch.gesture_ui"] = "src/systems/touch/gesture_ui.lua",
      ["src.systems.touch.touch_gesture_system"] = "src/systems/touch/touch_gesture_system.lua",
      ["src.systems.upgrade_system"] = "src/systems/upgrade_system.lua",
      ["src.systems.warp_drive"] = "src/systems/warp_drive.lua",
      ["src.systems.warp.warp_core"] = "src/systems/warp/warp_core.lua",
      ["src.systems.warp.warp_energy"] = "src/systems/warp/warp_energy.lua",
      ["src.systems.warp.warp_memory"] = "src/systems/warp/warp_memory.lua",
      ["src.systems.warp.warp_navigation"] = "src/systems/warp/warp_navigation.lua",
      ["src.systems.warp_zones"] = "src/systems/warp_zones.lua",
      ["src.systems.weekly_challenges_system"] = "src/systems/weekly_challenges_system.lua",
      ["src.systems.world_generator"] = "src/systems/world_generator.lua",
      ["src.systems.xp_system"] = "src/systems/xp_system.lua",
      ["src.systems.xp.xp_definitions"] = "src/systems/xp/xp_definitions.lua",
      ["src.systems.xp.xp_logic"] = "src/systems/xp/xp_logic.lua",
      ["src.systems.xp.xp_ui"] = "src/systems/xp/xp_ui.lua",
      
      -- UI modules
      ["src.ui.components.button"] = "src/ui/components/button.lua",
      ["src.ui.components.layout"] = "src/ui/components/layout.lua",
      ["src.ui.components.notification"] = "src/ui/components/notification.lua",
      ["src.ui.components.progress_bar"] = "src/ui/components/progress_bar.lua",
      ["src.ui.debug.debug_config"] = "src/ui/debug/debug_config.lua",
      ["src.ui.debug.debug_logging"] = "src/ui/debug/debug_logging.lua",
      ["src.ui.debug.debug_performance"] = "src/ui/debug/debug_performance.lua",
      ["src.ui.debug.debug_rendering"] = "src/ui/debug/debug_rendering.lua",
      ["src.ui.debug.debug_validation"] = "src/ui/debug/debug_validation.lua",
      ["src.ui.debug.ui_debug_enhanced_new"] = "src/ui/debug/ui_debug_enhanced_new.lua",
      ["src.ui.enhanced_tutorial_system_new"] = "src/ui/enhanced_tutorial_system_new.lua",
      ["src.ui.feedback_ui"] = "src/ui/feedback_ui.lua",
      ["src.ui.lore_viewer"] = "src/ui/lore_viewer.lua",
      ["src.ui.pause_menu"] = "src/ui/pause_menu.lua",
      ["src.ui.screens.game_ui"] = "src/ui/screens/game_ui.lua",
      ["src.ui.screens.menu_ui"] = "src/ui/screens/menu_ui.lua",
      ["src.ui.settings_menu"] = "src/ui/settings_menu.lua",
      ["src.ui.tutorial.tutorial_modules"] = "src/ui/tutorial/tutorial_modules.lua",
      ["src.ui.tutorial.tutorial_rendering"] = "src/ui/tutorial/tutorial_rendering.lua",
      ["src.ui.tutorial.tutorial_state"] = "src/ui/tutorial/tutorial_state.lua",
      ["src.ui.ui_animation_system"] = "src/ui/ui_animation_system.lua",
      ["src.ui.ui_system"] = "src/ui/ui_system_refactored.lua",
      ["src.ui.ui_system_refactored"] = "src/ui/ui_system_refactored.lua",
      
      -- Utility modules
      ["src.utils.asset_loader"] = "src/utils/asset_loader.lua",
      ["src.utils.config"] = "src/utils/config.lua",
      ["src.utils.constants"] = "src/utils/constants.lua",
      ["src.utils.data.formatting"] = "src/utils/data/formatting.lua",
      ["src.utils.data.serialization"] = "src/utils/data/serialization.lua",
      ["src.utils.error_handler"] = "src/utils/error_handler.lua",
      ["src.utils.event_bus"] = "src/utils/event_bus.lua",
      ["src.utils.hot_reload"] = "src/utils/hot_reload.lua",
      ["src.utils.input.mobile_input"] = "src/utils/input/mobile_input.lua",
      ["src.utils.math.geometry"] = "src/utils/math/geometry.lua",
      ["src.utils.math.interpolation"] = "src/utils/math/interpolation.lua",
      ["src.utils.math.vector"] = "src/utils/math/vector.lua",
      ["src.utils.module_loader"] = "src/utils/module_loader.lua",
      ["src.utils.object_pool"] = "src/utils/object_pool.lua",
      ["src.utils.render_batch"] = "src/utils/render_batch.lua",
      ["src.utils.rendering.drawing"] = "src/utils/rendering/drawing.lua",
      ["src.utils.rendering.ui_components"] = "src/utils/rendering/ui_components.lua",
      ["src.utils.spatial_grid"] = "src/utils/spatial_grid.lua",
      ["src.utils.utils"] = "src/utils/utils.lua",
      ["src.utils.utils_new"] = "src/utils/utils_new.lua",
      
      -- Audio modules
      ["src.audio.sound_generator"] = "src/audio/sound_generator.lua",
      ["src.audio.sound_manager"] = "src/audio/sound_manager.lua",
      
      -- Performance modules
      ["src.performance.audio_streaming_system"] = "src/performance/audio_streaming_system.lua",
      ["src.performance.lod_system"] = "src/performance/lod_system.lua",
      ["src.performance.optimized_functions"] = "src/performance/optimized_functions.lua",
      ["src.performance.performance_monitor"] = "src/performance/performance_monitor.lua",
      ["src.performance.performance_system"] = "src/performance/performance_system.lua",
      ["src.performance.texture_atlas_system"] = "src/performance/texture_atlas_system.lua",
      
      -- Development modules
      ["src.dev.dev_tools"] = "src/dev/dev_tools.lua",
      ["src.dev.docs_generator"] = "src/dev/docs_generator.lua",
      
      -- External libraries
      ["libs.json"] = "libs/json.lua",
      
      -- Test modules (for development)
      ["tests.love2d_test_runner"] = "tests/love2d_test_runner.lua",
      ["tests.run_unified_tests_simple"] = "tests/run_unified_tests_simple.lua",
      
      -- Main entry point
      ["main"] = "main.lua"
   },
   copy_directories = {
      "assets",
      "docs",
      "examples",
      "scripts",
      "tests"
   }
} 