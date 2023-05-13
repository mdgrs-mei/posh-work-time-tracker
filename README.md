<div align="center">

# Posh Work Time Tracker

[![GitHub license](https://img.shields.io/github/license/mdgrs-mei/posh-work-time-tracker)](https://github.com/mdgrs-mei/posh-work-time-tracker/blob/main/LICENSE)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/mdgrs-mei/posh-work-time-tracker?label=latest%20release)](https://github.com/mdgrs-mei/posh-work-time-tracker/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/mdgrs-mei/posh-work-time-tracker/total)](https://github.com/mdgrs-mei/posh-work-time-tracker/releases/latest)

*Posh Work Time Tracker* is a Windows taskbar application that records your work time and notifies you of overtime on the taskbar.

This is also an example project that demonstrates how to use [*PoshTaskbarItem*](https://github.com/mdgrs-mei/PoshTaskbarItem) PowerShell module.

https://github.com/mdgrs-mei/posh-work-time-tracker/assets/81177095/3f7ad6d7-419c-4662-b644-7f12ad563242

</div>

## Features

- Records the time while the app is running excluding the time when the screen is locked
- Notifies you of overtime by the progress bar and overlay badge on the taskbar icon  
![overtime](https://user-images.githubusercontent.com/81177095/213721157-7042e52a-c9e5-451a-b191-761c9c068994.png)

- Shows monthly reports of your work time

## Requirements

- Windows 10 or 11

## Installation

1. Download and extract the [zip](https://github.com/mdgrs-mei/posh-work-time-tracker/releases/latest/download/posh-work-time-tracker.zip) anywhere you like
1. Run [`install.bat`](./install.bat)
1. Pick a folder where log files are stored  
![pick_log_folder](https://user-images.githubusercontent.com/81177095/211552064-36b870db-7cdc-405e-9426-4dc84eefc7cb.png)

1. Configure settings and press `Save`  
![config](https://user-images.githubusercontent.com/81177095/211552089-991e59b4-a216-4ca8-8e11-6aa5847e64a1.png)

1. Save a shortcut. The default location is your Startup folder so that the app automatically runs at login.  
![save_shortcut](https://user-images.githubusercontent.com/81177095/211552130-fd7e44ec-badb-4e93-8255-f03023d17a0f.png)

1. Run the shortcut
