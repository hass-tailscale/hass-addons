# Home Assistant Add-ons: @tsujamin's repository

This repository contains additional add-ons for your Home Assistant.
These add-ons are primarily used only by the author; as such, your individual mileage may vary.

## Installation

### Quick Installation

[![Open your Home Assistant instance and show the add app repository dialog with a specific repository URL pre-filled.][supervisor-badge]](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fhass-tailscale%2Fhass-addons)

---

### Manual Installation

A user can add a repository by going to the Supervisor panel in Home Assistant, clicking the store icon in the top-right, copying and pasting the repository URL into the repository text area, then clicking Save.

See ["Create an add-on repository"](https://developers.home-assistant.io/docs/add-ons/repository/) for more information.

## Repository Add-ons

- **[Tailscale](https://github.com/hass-tailscale/hass-addons/tailscale/README.md)**: A Tailscale add-on for Home Assistant, allowing you to connect your Home Assistant instance to your Tailscale network.

## Updates

GitHub Actions automatically build and publish new versions of the add-ons when a new Tailscale release is made. The add-on's version number will be bumped or reverted to match the current stable Tailscale version number.

[supervisor-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
