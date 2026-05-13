{config, ...}: let
  githubTokenPath = config.programs.onepassword-secrets.secretPaths.githubReadOnlyToken;
in {
  programs.onepassword-secrets = {
    enable = true;
    secrets.githubReadOnlyToken = {
      reference = "op://Private/secrets/github read-only token";
      path = ".config/opencode/github-read-only-token";
      mode = "0600";
    };
  };

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
