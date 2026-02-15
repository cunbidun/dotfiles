{ ... }: {
  programs.starship = {
    enable = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      palette = "default";
      format =
        "[┌─╼\\[$username@$hostname\\](╾─╼(\\[$status\\])(\\[$jobs\\]))╾─╼\\[$time\\](╾─╼\\[$cmd_duration\\])](frame)\n"
        + "[└─╼\\[$directory\\]](frame)\n"
        + "([ ╰╼(\\[$git_branch\\])(╾─╼$git_status)(╾─╼\\[$git_state\\])(╾─╼\\[\\${"$"}{custom.git_remote}\\])](frame))\\${"$"}{custom.line_break}"
        + "([ ╰╼\\[\\${"$"}{custom.git_commit_message}\\]╾─╼$git_commit╾─╼\\[\\${"$"}{custom.git_commit_time}\\]](frame))\\${"$"}{custom.line_break}▶ $python$conda";

      conda = {
        ignore_base = false;
        format = "[\\($environment\\)]($style) ";
        style = "green";
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style)";
        truncate_to_repo = false;
        truncation_length = 100;
        style = "blue";
      };

      jobs = {
        number_threshold = 1;
        format = "[$number]($style)";
        style = "blue";
      };

      hostname = {
        ssh_only = false;
        format = "[$hostname]($style)";
        style = "blue";
      };

      git_branch = {
        format = "[$branch]($style)";
        always_show_remote = true;
        style = "green";
      };

      git_commit = {
        commit_hash_length = 50;
        format = "\\[[$hash]($style)\\](\\[[$tag](green)\\])";
        only_detached = false;
        style = "cyan";
        tag_disabled = false;
        tag_symbol = "";
      };

      git_state = {
        format = "[$state( $progress_current/$progress_total)]($style)";
        style = "yellow";
      };

      git_status = {
        untracked = "?\${count}";
        modified = "[*\${count}](yellow)";
        deleted = "✘\${count}";
        conflicted = "C";
        stashed = "S";
        diverged = "[D+\${ahead_count}-\${behind_count}](red)";
        up_to_date = "=";
        staged = "[+\${count}](green)";
        ahead = "+\${count}";
        behind = "-\${count}";
        format = "(\\[[$all_status]($style)\\])(\\[[[u](blue)$ahead_behind](white)\\])";
        style = "red";
      };

      status = {
        disabled = false;
        format = "[$status]($style)";
        style = "red";
      };

      time = {
        format = "[$time]($style)";
        style = "blue";
        disabled = false;
      };

      cmd_duration = {
        format = "[tooks $duration]($style)";
        style = "blue";
        disabled = false;
        min_time = 0;
        show_milliseconds = true;
      };

      python = {
        format = "[\${pyenv_prefix}(\${version} )]($style)[(\\(\${virtualenv}\\) )]($style)";
        style = "yellow";
      };

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "blue";
        style_root = "red bold";
      };

      custom = {
        git_remote = {
          command = ''
remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -n "$remote_branch" ]; then
  echo "$remote_branch"
fi
'';
          require_repo = true;
          when = true;
          format = "[$output]($style)";
          style = "white";
        };

        line_break = {
          command = "echo ''";
          require_repo = true;
          when = true;
          format = "\n";
        };

        git_commit_time = {
          command = ''
git log -1 --format=%cd --date=format-local:'%Y-%m-%d %H:%M:%S' 2>/dev/null
'';
          require_repo = true;
          when = true;
          format = "[$output]($style)";
          style = "cyan";
        };

        git_commit_message = {
          command = ''
git log -1 --format=%s 2>/dev/null
'';
          require_repo = true;
          when = true;
          format = "[$output]($style)";
          style = "cyan";
        };
      };

      palettes.default = {
        frame = "#434c5e";
      };
    };
  };
}
