{ ... }:
{
  # Cache unlocked SSH keys for the duration of the desktop login session.
  programs.ssh.startAgent = true;

  services.openssh = {
    enable = true;
    settings = {
      # Use the normal wheel user for administration instead of root login.
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };
}
