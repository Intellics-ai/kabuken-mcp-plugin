# Setting up the Kabuken MCP server

This plugin bundles a `.mcp.json` entry for the remote Kabuken MCP server at
`https://kabuken.intellics.ai/mcp`. Enabling the plugin registers the server;
you still need to authenticate once.

For an interactive walkthrough, ask Claude "set up Kabuken" — it will use
the `kabuken-setup` skill in this plugin (`skills/kabuken-setup/SKILL.md`).
The summary:

## Option A: OAuth 2.0 + PKCE (preferred)

1. Run `/mcp` in Claude Code, select `kabuken`, and follow the browser
   sign-in prompt. Without the plugin, add the server first:
   `claude mcp add --transport http kabuken https://kabuken.intellics.ai/mcp`.
2. No Kabuken account yet? Sign up at
   [kabuken.intellics.ai](https://kabuken.intellics.ai).
   Some tools are available on paid plans. Plan details: https://kabuken.intellics.ai/pricing

## Option B: API key (fallback)

Use this if OAuth isn't available in your environment (e.g. headless CI).

1. Get a `kbk_...` key from the MCP API keys section of your account page:
   [kabuken.intellics.ai/account](https://kabuken.intellics.ai/account).
2. Add the server with the key as a header, under a separate local name:
   ```
   claude mcp add --transport http kabuken-apikey https://kabuken.intellics.ai/mcp \
     --header "Authorization: Bearer <your kbk_ key>"
   ```

## ChatGPT (developer mode, beta)

1. Download the latest plugin package:
   [kabuken-plugin.zip](https://github.com/Intellics-ai/kabuken-mcp-plugin/releases/latest/download/kabuken-plugin.zip).
2. Open [chatgpt.com/plugins](https://chatgpt.com/plugins), select **+**, then
   **Create custom MCP server**.
3. Upload the ZIP.
4. Sign in with Google when ChatGPT asks you to connect Kabuken.

## Plans

Some tools are available on paid plans. Plan details: https://kabuken.intellics.ai/pricing

See the [README](./README.md) for the full tool list grouped by purpose.
