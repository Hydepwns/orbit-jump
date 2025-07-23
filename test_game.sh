#!/bin/sh
# Test game and capture initial errors
timeout 5 love . 2>&1 | head -100