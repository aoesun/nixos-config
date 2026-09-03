{ ... }:
{
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
