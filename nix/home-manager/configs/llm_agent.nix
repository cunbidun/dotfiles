{
  config,
  lib,
  pkgs,
  inputs,
  userdata,
  ...
}:
let
  configHome = config.xdg.configHome;
  cacheHome = config.xdg.cacheHome;
  githubTokenPath = "${configHome}/opencode/github_read_only_token";
  ninerouterTokenPath = "${configHome}/opencode/ninerouter_api_key";

  # The 9router LLM proxy on the home-server, addressed by its Tailscale
  # *Service* name rather than the device's — svc:ai-proxy is routed to
  # 127.0.0.1:20128 (hosts/home-server/tailscale-services.nix), so this survives
  # device renames. The previous `home-server.<tailnet>:20128` form pointed at
  # the device and broke the moment it was renamed.
  aiProxyBaseUrl = "https://ai-proxy.${userdata.tailnetDomain}/v1";
  # One model id, shared by codex and opencode so they never drift apart.
  aiProxyModel = "cx/gpt-5.6-sol";
  chromeBinary = "${pkgs.google-chrome}/bin/google-chrome-stable";
  chromeDevToolsProfile = "${cacheHome}/chrome-devtools-mcp/opencode-profile";
  codexChromeDevToolsProfile = "${cacheHome}/chrome-devtools-mcp/codex-profile";
  npx = "${pkgs.nodejs}/bin/npx";
  lspPath = pkgs.lib.makeBinPath [
    pkgs.nixd
    pkgs.pyright
    pkgs.lua-language-server
    pkgs.typescript
    pkgs.typescript-language-server
    pkgs.vscode-langservers-extracted
    pkgs.yaml-language-server
    pkgs.dockerfile-language-server
  ];
  mcpPath = pkgs.lib.makeBinPath [
    pkgs.nodejs
    pkgs.bash
    pkgs.coreutils
  ];
  codexToml = pkgs.formats.toml { };
  mattEngineeringSkills = [
    "ask-matt"
    "code-review"
    "codebase-design"
    "diagnosing-bugs"
    "domain-modeling"
    "grill-with-docs"
    "implement"
    "improve-codebase-architecture"
    "prototype"
    "resolving-merge-conflicts"
    "tdd"
    "to-issues"
    "to-prd"
    "triage"
  ];
  mattSkills =
    lib.genAttrs mattEngineeringSkills (
      name: "${inputs.mattpocock-skills}/skills/engineering/${name}"
    )
    // {
      grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
    };
  codexConfigFile = codexToml.generate "codex-config.toml" {
    model_provider = "9router";
    model = aiProxyModel;
    model_reasoning_effort = "high";
    personality = "pragmatic";

    model_providers."9router" = {
      name = "9router";
      base_url = aiProxyBaseUrl;
      env_key = "NINEROUTER_API_KEY";
    };

    features = {
      multi_agent = true;
      apps = true;
    };

    shell_environment_policy = {
      "inherit" = "all";
      ignore_default_excludes = true;
      experimental_use_profile = true;
    };

    projects."${config.home.homeDirectory}".trust_level = "trusted";
    projects."${configHome}".trust_level = "trusted";

    sandbox_workspace_write.network_access = true;

    mcp_servers."chrome-devtools" = {
      command = npx;
      args = [
        "-y"
        "chrome-devtools-mcp@latest"
        "--executable-path=${chromeBinary}"
        "--user-data-dir=${codexChromeDevToolsProfile}"
        "--no-usage-statistics"
        "--no-performance-crux"
        "--headless"
      ];
      env.PATH = mcpPath;
      startup_timeout_sec = 20;
      tool_timeout_sec = 60;
      enabled = true;
    };

    mcp_servers."nixos" = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-nixos" ];
      enabled = true;
    };

    mcp_servers."github" = {
      url = "https://api.githubcopilot.com/mcp/readonly";
      bearer_token_env_var = "GITHUB_COPILOT_MCP_TOKEN";
      enabled = true;
    };

    plugins = {
      "gmail@openai-curated".enabled = true;
      "github@openai-curated".enabled = true;
      "google-calendar@openai-curated".enabled = true;
      "google-drive@openai-curated".enabled = true;
      "slack@openai-curated".enabled = true;
    };

    tui.model_availability_nux."cx/gpt-5.6-sol" = 4;
  };
in
{
  home.packages = with pkgs; [
    nixd
    pyright
    lua-language-server
    typescript
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    dockerfile-language-server
    nodejs
    uv
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    permission = "allow";
    plugin = [ "${inputs.obra-superpowers}/.opencode/plugins/superpowers.js" ];

    # Route opencode through the same 9router proxy codex uses, via the
    # openai-compatible adapter. The key is read from its sops file with
    # opencode's `{file:…}` interpolation — the same mechanism as the github MCP
    # token below — so it is never baked into the world-readable nix store.
    model = "9router/${aiProxyModel}";
    provider."9router" = {
      npm = "@ai-sdk/openai-compatible";
      name = "9router";
      options = {
        baseURL = aiProxyBaseUrl;
        apiKey = "{file:${ninerouterTokenPath}}";
      };
      models.${aiProxyModel} = { };
    };
    lsp = {
      nixd = {
        command = [ "${pkgs.nixd}/bin/nixd" ];
        extensions = [ ".nix" ];
      };
      pyright = {
        command = [
          "${pkgs.pyright}/bin/pyright-langserver"
          "--stdio"
        ];
        extensions = [
          ".py"
          ".pyi"
        ];
      };
      lua-ls = {
        command = [ "${pkgs.lua-language-server}/bin/lua-language-server" ];
        extensions = [ ".lua" ];
      };
      typescript = {
        command = [
          "${pkgs.typescript-language-server}/bin/typescript-language-server"
          "--stdio"
        ];
        extensions = [
          ".ts"
          ".tsx"
          ".js"
          ".jsx"
          ".mjs"
          ".cjs"
          ".mts"
          ".cts"
        ];
        env.PATH = lspPath;
      };
      json = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server"
          "--stdio"
        ];
        extensions = [
          ".json"
          ".jsonc"
        ];
      };
      yaml-ls = {
        command = [
          "${pkgs.yaml-language-server}/bin/yaml-language-server"
          "--stdio"
        ];
        extensions = [
          ".yaml"
          ".yml"
        ];
      };
      css = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server"
          "--stdio"
        ];
        extensions = [
          ".css"
          ".scss"
          ".less"
        ];
      };
      html = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server"
          "--stdio"
        ];
        extensions = [
          ".html"
          ".htm"
        ];
      };
      docker = {
        command = [
          "${pkgs.dockerfile-language-server}/bin/docker-langserver"
          "--stdio"
        ];
        extensions = [
          "Dockerfile"
          ".dockerfile"
        ];
      };
    };
    mcp = {
      chrome-devtools = {
        type = "local";
        command = [
          npx
          "-y"
          "chrome-devtools-mcp@latest"
          "--executable-path=${chromeBinary}"
          "--user-data-dir=${chromeDevToolsProfile}"
          "--no-usage-statistics"
          "--no-performance-crux"
          "--headless"
        ];
        environment.PATH = mcpPath;
        timeout = 20000;
        enabled = true;
      };

      github = {
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

      nixos = {
        type = "local";
        command = [ "${pkgs.uv}/bin/uvx" "mcp-nixos" ];
        enabled = true;
      };
    };
  };

  programs.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    skills = mattSkills;
    tui = {
      theme = "system";
    };
  };

  home.sessionVariablesExtra = ''
    if [ -r "${ninerouterTokenPath}" ]; then
      export NINEROUTER_API_KEY="$(tr -d '\n' < "${ninerouterTokenPath}")"
    fi

    if [ -r "${githubTokenPath}" ]; then
      export GITHUB_COPILOT_MCP_TOKEN="$(tr -d '\n' < "${githubTokenPath}")"
    fi
  '';

  home.file =
    {
      ".codex/config.toml" = {
        source = codexConfigFile;
        force = true;
      };
    }
    // lib.mapAttrs' (
      name: source: lib.nameValuePair ".codex/skills/${name}" { inherit source; }
    ) mattSkills;
}
