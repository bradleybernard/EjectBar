# EjectBar
A tiny lightweight macOS menubar application to eject multiple mounted volumes in one click. Right click the menubar eject icon to unmount all saved volumes. Left click the icon to show all of the mounted volumes so you can change your saved volumes.

## Technologies
The app uses the [Disk Arbitration framework](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L170) to hook into mount/unmount volume callbacks at a low-level. In addition, the code uses [low-level reference management](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L67) since the DA framework only accepts C function pointers. Lastly, the app uses a [class that boxes a callback using generic types](https://github.com/bradleybernard/EjectBar/blob/master/EjectBar/Classes/Volume.swift#L28-L33) T, U to create a generic function: (T) -> U. 

## Screenshots
![1](/Screenshots/1.png?raw=true "1")
![2](/Screenshots/2.png?raw=true "2")

### Credits
Created by [Bradley Bernard](https://bradleybernard.com) with [help](https://twitter.com/jckarter/status/889604979995967488) from [Joe Groff](https://twitter.com/jckarter)
