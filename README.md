# EjectBar
A tiny, lightweight macOS menubar application to eject multiple mounted volumes in one click. Favorite a mounted volume to save it for quick unmounting later.

## App Store
![App store icon](https://is2-ssl.mzstatic.com/image/thumb/Purple114/v4/e9/0e/46/e90e460d-24e4-6569-201d-d7da9e91d8f9/AppIcon-85-220-4-2x.png/230x0w.webp)
Available for free on the App Store for macOS 10.10 (Yosemite) and newer: https://apps.apple.com/us/app/ejectbar/id1264259104?mt=12

## Description

The application lives in the macOS menubar and can be shown with a click on the icon to expose the menu for ejecting, showing/hiding the mounted volumes, showing/hiding the favorite volumes, and quitting. The main window for the application shows currently mounted volumes and whether they are saved as favorites, along with the buttons from the menubar.

## Technologies
The app uses the [Disk Arbitration framework](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L170) to hook into mount/unmount volume callbacks at a low-level. In addition, the code uses [low-level reference management](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L67) since the DA framework only accepts C function pointers. Lastly, the app uses a [class that boxes a callback using generic types](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L28-L33) Input, Output to create a generic function: (Input) -> Output. 

## Screenshots
![Menu bar](/Screenshots/1.png?raw=true "1")
![Mounted volumes](/Screenshots/2.png?raw=true "2")
![Favorite volumes](/Screenshots/1.png?raw=true "3")

## Credits
Created by [Bradley Bernard](https://bradleybernard.com) with [techincal help](https://twitter.com/jckarter/status/889604979995967488) from the Swift expert [Joe Groff](https://twitter.com/jckarter)!