{
  username = "cunbidun";
  email = "cunbidun@gmail.com";
  name = "Duy Pham";
  timeZone = "America/New_York";

  # Set to true to use a hermetic Neovim configuration
  # With this option enabled, you modify your Neovim configuration in the dotfiles repository, then run
  # nix rebuild to apply the changes.
  # Set this option to false allows direct editing of the Neovim configuration files in ~/.config/nvim,
  # making it's faster to iterate and test changes.
  hermeticNvimConfig = false;

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYi6b9Qaa6hF5PXkaTinS131ESVKDkQTOWCcvD8JmZ3"
  ];
}
