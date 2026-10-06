---
name: kabuken-setup
description: Guide the user through connecting the Kabuken MCP server in Claude Code, claude.ai, Claude Desktop or Claude mobile, choosing between OAuth sign-in and an API key. Use when the user asks to set up, connect, authenticate, or troubleshoot the Kabuken MCP server.
---

# Kabuken MCP setup

Kabuken exposes Japanese EDINET/XBRL financial data over a single remote MCP
server at `https://kabuken.intellics.ai/mcp`. This plugin already declares
that server in `.mcp.json`, so once the plugin is enabled, Claude Code
attempts to connect automatically.

If the user has no Kabuken account yet, direct them to
`https://kabuken.intellics.ai` to sign up first.

## Step 1: Check connection status (Claude Code)

Run `/mcp` inside Claude Code. If `kabuken` shows `connected`, sign-in is
already done and no further action is needed. If it shows `needs
authentication`, continue to Step 2.

## Step 2: Authenticate with OAuth (preferred)

Kabuken supports OAuth 2.0 Authorization Code with PKCE. This is the
preferred sign-in method: there is no key to copy or store.

### Claude Code

1. If the plugin is not enabled, add the server from the shell first:
   `claude mcp add --transport http kabuken https://kabuken.intellics.ai/mcp`.
2. Run `/mcp`, select `kabuken`, and follow the browser prompt to sign in.
3. Claude Code stores the tokens securely and refreshes them automatically.
   Use "Clear authentication" in the `/mcp` menu to revoke access.

### claude.ai, Claude Desktop and Claude mobile

1. Open Customize, then Connectors, then select Add custom connector.
2. Enter the URL `https://kabuken.intellics.ai/mcp` and add the connector.
3. Select Connect and sign in to Kabuken in the browser window.

## Step 3: Authenticate with an API key (fallback, Claude Code only)

Use this only if OAuth sign-in is unavailable in the user's environment
(for example, a headless CI run with no browser and no interactive
terminal).

1. The user gets a `kbk_...` API key from the "MCP API keys" section of
   their account page at `https://kabuken.intellics.ai/account`.
2. Add the server with the key as a bearer header, under a different local
   name so it doesn't collide with the OAuth entry this plugin ships:
   ```
   claude mcp add --transport http kabuken-apikey https://kabuken.intellics.ai/mcp \
     --header "Authorization: Bearer <their kbk_ key>"
   ```
3. Never print, log, or commit the key. Treat it like any other credential.

## Step 4: Plans

Some tools are available on paid plans. Plan details: https://kabuken.intellics.ai/pricing

If a tool returns a message that it is available on other plans, this is
expected, not an error. Share the plan details link above.

## Step 5: Confirm

Use `search_companies` with a well-known name (for example, "Toyota") to
confirm the connection actually returns data, not just a "connected"
status.
