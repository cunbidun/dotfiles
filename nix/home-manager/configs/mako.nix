{...}: {
  services.mako = {
    enable = true;

    width = 300;
    height = 100;
    margin = "20";
    padding = "20";
    borderSize = 2;
    borderRadius = 0;

    # Notification behavior
    defaultTimeout = 5000;
    ignoreTimeout = true;
    maxVisible = 20;

    # Positioning and layout
    anchor = "top-right";
    layer = "overlay";

    extraConfig = ''
      [urgency=critical]
      ignore-timeout=1
    '';
  };
}
# {...}: {
#   services.mako = {
#     enable = true;
#
#     settings = {
#       width = 300;
#       height = 100;
#       margin = "20";
#       padding = "20";
#       borderSize = 2;
#       borderRadius = 0;
#
#       # Notification behavior
#       defaultTimeout = 5000;
#       ignoreTimeout = true;
#       maxVisible = 20;
#
#       # Positioning and layout
#       anchor = "top-right";
#       layer = "overlay";
#     };
#     criteria = {
#       "urgency=critical" = {
#         "ignore-timeout" = 1;
#       };
#     };
#   };
# }

