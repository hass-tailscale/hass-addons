# Patching Instructions

If you're looking to open a PR to bump the Tailscale version:

- Check that the corresponding version has been released at <https://pkgs.tailscale.com/stable/#static>

- Update the add-on version in `config.json`, e.g., for Tailscale `1.2.3`, set the add-on version to `1.2.3.0`

- Update the add-on version in `build.json` and Dockerfile

- Add a changelog entry with the content "Tailscale package updated to version `1.2.3`"

Thanks for your contribution!
