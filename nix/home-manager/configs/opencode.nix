{config, ...}: let
  githubTokenPath = "${config.home.homeDirectory}/.config/opencode/github_read_only_token";
in {
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    mcp.github = {
      type = "remote";
      url = "https://api.githubcopilot.com/mcp/readonly";
      oauth = false;
      headers = {
        Authorization = "Bearer {file:${githubTokenPath}}";
        X-MCP-Toolsets = "context,repos,issues,pull_requests,users";
        X-MCP-Readonly = "true";
      };
      enabled = true;
    };
  };
}
