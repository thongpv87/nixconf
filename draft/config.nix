let devices = import ./devices;
in {
  laptop = host-config {
    laptop = devices.elitebook_845g10;

  };
}
