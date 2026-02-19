{pkgs, ...}: let
in {
  home.packages = [
    pkgs.prismlauncher
    pkgs.jdk21
  ];

  # Keep Java 8 available for legacy Minecraft without adding it to PATH,
  # which would collide with jdk21 on bin/keytool in home-manager-path.
  home.sessionVariables.JAVA8_HOME = "${pkgs.jdk8}";
}
