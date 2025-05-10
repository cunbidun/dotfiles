{
  project_root,
  userdata,
  pkgs,
  ...
}: {
  programs.firefox = {
    enable = true;
    profiles.${userdata.username} = {
      search = {
        force = true;
        engines = {
          "GitHub Repositories" = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                  {
                    name = "type";
                    value = "repositories";
                  }
                ];
              }
            ];
            icon = "${project_root}/icons/github.svg";
            definedAliases = ["@gh"];
          };
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@nix"];
          };
        };
      };

      bookmarks = {};
      bookmarks = {};
      # https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/generated-firefox-addons.nix
      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          sponsorblock
          vimium
          competitive-companion
          multi-account-containers
          onepassword-password-manager
          user-agent-string-switcher
          tampermonkey
          aw-watcher-web
        ];
        settings = {
          # competitive-companion
          "{74e326aa-c645-4495-9287-b6febc5565a7}".settings = {
            force = true;
            customPorts = [8080];
          };
          # multi-account-containers
          "@testpilot-containers".settings = {
            force = true;
            onboarding-stage = 8;
            syncEnabled = false;
            "siteContainerMap@@_chatgpt.com" = {
              "userContextId" = "1";
              "neverAsk" = true;
              "identityMacAddonUUID" = "78aa2e5b-407c-4fa9-8ee0-8aacf271ba19";
            };
            "siteContainerMap@@_openai.com" = {
              "userContextId" = "1";
              "neverAsk" = true;
              "identityMacAddonUUID" = "78aa2e5b-407c-4fa9-8ee0-8aacf271ba19";
            };
            "identitiesState@@_firefox-container-1" = {
              "hiddenTabs" = [];
              "macAddonUUID" = "78aa2e5b-407c-4fa9-8ee0-8aacf271ba19";
            };
          };
          # aw-watcher-web
          "{ef87d84c-2127-493f-b952-5b4e744245bc}".settings = {
            force = true;
            baseUrl = "http://localhost:5600";
            enabled = true;
          };
        };
      };
      containersForce = true;
      containers = {
        gpt = {
          color = "orange";
          icon = "briefcase";
          id = 1;
        };
      };
      settings = {
        "browser.startup.homepage" = "about:home";

        # Disable irritating first-run stuff
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.feeds.showFirstRunUI" = false;
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "browser.rights.3.shown" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.uitour.enabled" = false;
        "startup.homepage_override_url" = "";
        "trailhead.firstrun.didSeeAboutWelcome" = true;
        "browser.bookmarks.restore_default_bookmarks" = false;
        "browser.bookmarks.addedImportButton" = true;

        # Don't ask for download dir
        "browser.download.useDownloadDir" = false;
        "browser.urlbar.suggest.weather" = false;

        # Disable crappy home activity stream page
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showWeather" = false;
        "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
        "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # Disable some telemetry
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false;
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.sessions.current.clean" = true;
        "devtools.onboarding.telemetry.logged" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.hybridContent.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.prompted" = 2;
        "toolkit.telemetry.rejected" = true;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.unifiedIsOptIn" = false;
        "toolkit.telemetry.updatePing.enabled" = false;

        # Smooth scrolling
        "general.smoothScroll.currentVelocityWeighting" = 1;
        "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
        "general.smoothScroll.msdPhysics.enabled" = true;
        "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
        "general.smoothScroll.msdPhysics.regularSpringConstant" = 250;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
        "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = 0.3;
        "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
        "general.smoothScroll.stopDecelerationWeighting" = 1.0;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "mousewheel.default.delta_multiplier_y" = 200;

        # Disable fx accounts
        "identity.fxaccounts.enabled" = false;
        "signon.rememberSignons" = false;
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.uiCustomization.state" = ''
          {
            "placements": {
              "widget-overflow-fixed-list": [],
              "unified-extensions-area": [
                "_testpilot-containers-browser-action",
                "sponsorblocker_ajay_app-browser-action",
                "ublock0_raymondhill_net-browser-action",
                "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
                "_a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7_-browser-action",
                "firefox_tampermonkey_net-browser-action"
              ],
              "nav-bar": [
                "back-button",
                "forward-button",
                "stop-reload-button",
                "customizableui-special-spring1",
                "vertical-spacer",
                "urlbar-container",
                "customizableui-special-spring2",
                "downloads-button",
                "fxa-toolbar-menu-button",
                "unified-extensions-button",
                "_74e326aa-c645-4495-9287-b6febc5565a7_-browser-action",
                "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action",
                "firefox_tampermonkey_net-browser-action"
              ],
              "toolbar-menubar": [
                "menubar-items"
              ],
              "TabsToolbar": [
                "firefox-view-button",
                "tabbrowser-tabs",
                "new-tab-button",
                "alltabs-button"
              ],
              "vertical-tabs": [],
              "PersonalToolbar": [
                "personal-bookmarks"
              ]
            },
            "seen": [
              "save-to-pocket-button",
              "developer-button",
              "_74e326aa-c645-4495-9287-b6febc5565a7_-browser-action",
              "_testpilot-containers-browser-action",
              "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action",
              "sponsorblocker_ajay_app-browser-action",
              "ublock0_raymondhill_net-browser-action",
              "_a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7_-browser-action",
              "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
              "firefox_tampermonkey_net-browser-action"
            ],
            "dirtyAreaCache": [
              "nav-bar",
              "vertical-tabs",
              "unified-extensions-area",
              "toolbar-menubar",
              "TabsToolbar",
              "PersonalToolbar"
            ],
            "currentVersion": 22,
            "newElementCount": 3
          }
        '';
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = ["firefox.desktop"];
    "text/xml" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];
  };
}
