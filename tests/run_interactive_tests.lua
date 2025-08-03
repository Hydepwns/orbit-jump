#!/usr/bin/env lua
-- Interactive Test Runner Launcher
-- Phase 5: Enhanced Developer Experience
-- Simple launcher for the interactive test runner
-- Add the tests directory to the Lua path
package.path = package.path .. ";tests/?.lua;tests/frameworks/?.lua"
-- Load the interactive test runner
local InteractiveRunner = require("interactive_test_runner")
-- Run the interactive test runner
InteractiveRunner.main(...)