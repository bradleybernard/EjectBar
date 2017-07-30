# EjectBar
A tiny, lightweight macOS menubar application to eject multiple mounted volumes in one click. Check each mounted volume to save it as a favorite for quick unmounting later.

The application lives in the menubar and can be shown with a click on the icon to expose the menu for ejecting, showing/hiding the application and quitting. The main window for the application shows currently mounted volumes and whether they are saved as favorites, along with the buttons from the menubar.

## Technologies
The app uses the [Disk Arbitration framework](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L170) to hook into mount/unmount volume callbacks at a low-level. In addition, the code uses [low-level reference management](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L67) since the DA framework only accepts C function pointers. Lastly, the app uses a [class that boxes a callback using generic types](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L28-L33) T, U to create a generic function: (T) -> U. 

## Screenshots
![1](/Screenshots/1.png?raw=true "1")
![2](/Screenshots/2.png?raw=true "2")

## Credits
Created by [Bradley Bernard](https://bradleybernard.com) with [help](https://twitter.com/jckarter/status/889604979995967488) from [Joe Groff](https://twitter.com/jckarter)
