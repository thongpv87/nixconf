{
  users.users.root = {
    password = "demo";
    extraGroups =
      [ "wheel" "networkmanager" "video" "libvirtd" "audio" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrWdE6zdQrm3sL80V/y6ZdA2CLYgwTUj7XSZm0ptRXXKBDu3xeWRoQ3rDV59IDGLtEdPBmXg3NIPvGthgIIFgbrfiHeC4HW7MkBeTOktF2EkUBzqlP7qBE1y7ensFpvti0MvtzxSc6fC1A0NxYUtbAV82vW6aPtsewcl1cP5eoskAi7vE+L39qYPjQ3WJhAtvGlDvxvwy8Bz10QXdwUHR2wDxIn96SS4fleMDiaDFzwEVnkEd564R02y2Le60VlOPi3h3p2pcX943kCoVsdZyl4k1+CgyXUq5EhPEqbHIipTMP4U6uZPWdeuhOfX/W+COIs4LsHtzemeIm3cPlEV3PQ7VEFzDoZZq4T2MjOfVsh+L6GOk9hteegddKBjCVPjvhk5LBvrnpuAO4IyGJMeC8KXYGI13fYSzouU9rqh6AUg/joyUEs33rOmTohlqAqmcVuQZwuv2ANkmvBs9glpAvVlGMzd56Bu70rcW+xT3yPYyB1cMGNxHfg/s5Qc+9cC0= thongpv87@thinkpad"
    ];
  };
}
