# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.x Editor Plugin that provides a chat interface with the Claude 3.5 Sonnet API directly within the Godot Editor. The plugin adds a dock panel to the editor where users can send messages to Claude and receive responses.

## Architecture

### Core Components

**plugin.gd** - EditorPlugin entry point
- Registers the plugin and creates project settings for the API key
- Instantiates and adds the dock window to the editor interface (`DOCK_SLOT_RIGHT_UL`)
- The API key is stored in ProjectSettings at `plugins/claude_api/api_key`

**dock_window.gd** - Main UI logic and API communication
- Handles the chat interface UI (input field, output field, status label, buttons)
- Makes HTTP POST requests to `https://api.anthropic.com/v1/messages`
- Uses the Claude 3.5 Sonnet model (`claude-3-5-sonnet-20241022`) with max_tokens of 1024
- Requires three headers: `x-api-key`, `Content-Type: application/json`, and `anthropic-version: 2023-06-01`
- Parses JSON response and extracts text from `content[0].text`

**dock_window.tscn** - Scene file defining the dock UI layout
- VBoxContainer with TextEdit for input, HBoxContainer with buttons, status Label, and TextEdit for output
- HTTPRequest node for API calls
- Signal connections wire up button presses and request completion

### Key Technical Details

- All scripts use `@tool` directive to run in the editor
- The plugin uses Godot's HTTPRequest node for asynchronous API calls
- API key validation happens at request time, not plugin initialization
- The dock window path is hardcoded as `res://claude/addons/claude_3.5_sonnet_chat_api/dock_window.tscn` in plugin.gd:7

## Testing and Development

This is an editor plugin, so testing must be done within the Godot Editor:

1. Open the parent Godot project containing this addon
2. Enable the plugin in Project Settings → Plugins
3. Set your Claude API key in Project Settings → Plugins → Claude API → API Key
4. The dock panel should appear in the upper-right dock slot
5. Test by entering a message and clicking "Send to Claude"

## API Configuration

The plugin requires a valid Anthropic API key from https://console.anthropic.com/settings/keys. The API key must be funded to work. Store the API key in the project settings, not in the code.
