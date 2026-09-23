---
description: Guide the user through connecting the Kabuken MCP server, choosing between OAuth sign-in and an API key, and explaining what each subscription tier unlocks. Use when the user asks to set up, connect, authenticate, or troubleshoot the Kabuken MCP server.
---

# Kabuken MCP setup

Kabuken exposes Japanese EDINET/XBRL financial data over a single remote MCP
server at `https://kabuken.intellics.ai/mcp`. This plugin already declares
that server in `.mcp.json`, so once the plugin is enabled, Claude Code
attempts to connect automatically.

## Step 1: Check connection status

Run `/mcp` inside Claude Code. If `kabuken` shows `connected`, sign-in is
already done and no further action is needed. If it shows `needs
authentication`, continue to Step 2.

## Step 2: Authenticate (OAuth, preferred)

Kabuken supports OAuth 2.0 Authorization Code with PKCE and is the preferred
sign-in method — no key to copy or store.

1. Run `/mcp` and select `kabuken`, then follow the browser prompt to sign
   in. Alternatively run `claude mcp login kabuken` from the shell.
2. If the user has no Kabuken account yet, direct them to
   `https://kabuken.intellics.ai` to sign up first — a BASIC-tier account is
   free and is enough to complete OAuth and try the discovery tools.
3. Tokens are stored securely by Claude Code and refreshed automatically.
   Use "Clear authentication" in the `/mcp` menu, or `claude mcp logout
   kabuken`, to revoke access.

## Step 3: Authenticate with an API key (fallback)

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

## Step 4: Explain the tiers if asked

| Tier | Price | Daily call limit | Tools |
|---|---|---|---|
| BASIC | Free | 50/day | 5: `search_companies`, `get_company`, `list_industries`, `get_risk_context`, `get_account_quota` |
| INVESTOR | ¥1,980/month (¥19,800/year) | 500/day | All 16 tools |
| MCP DEVELOPER | ¥4,980/month | 1,000/day | All 16 tools |

A BASIC account is free and sufficient to connect and explore company and
industry discovery. Calling one of the other 11 tools on a BASIC account
returns an upgrade message pointing to `https://kabuken.intellics.ai/pricing`
— this is expected, not an error, and the fix is to upgrade the account.

## Step 5: Confirm

Use `search_companies` with a well-known name (for example, "Toyota") to
confirm the connection actually returns data, not just a "connected"
status.
