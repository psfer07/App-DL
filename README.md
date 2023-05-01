# App-DL

This program is a simple package manager which downloads packaged portable apps from verified repositories.

All you need to do is typing or copying this command in your powershell terminal. It will redirect you to the app.

```powershell
irm bit.ly/psappdl | iex
```

## Changelog

### App-DL v1.2

---

* Added app details (writing a period before the number for displaying them)
* Added accurate file sizes for each program
* Reworked UI design
* Fixed known bugs
* Improved stability
* Improved performance

### App-DL v1.1

---

* Improved performance and many bugs are fixed
* Now it checks if even the package or the app are stored in the selected directory

  * Added the "open" option, which allows the user to skip the downloading steps if the app or the package is allocated in the specified path
  * Fixed the "restart" and "exit" options, which didn't appear
* Added self-explanatory descriptions for the apps
* Added recommended parameters for some apps and their corresponding description
* Added new portable apps to the library
* Functions Write-Main, Write-Secondary, Write-Point and Write-Warning are fixed when the app restarts

![1679232823640](image/README/1679232823640.png "App selection")

![1679232767060](image/README/1679232767060.png)

Known bugs:

* When you run 7-zip with the recommended parameters, the path assigned is shown as $path\, and not as the actual path, but the user can browse to the wanted folder

### App-DL v1.0 (First release)

---

* Downloads the app that the user selects
* Gives 6 paths to download

  * Desktop
  * Documents
  * Downloads
  * The system drive (normally C:\\)
  * Program Files
  * User path (C:\\users\\**\\)
* Extracts the package or installs it, whatever is a zip or an exe file.
* Looks for the executable to open it if desired

  ![1679231456807](image/README/1679231456807.png "App selection")

  ![1679232109146](image/README/1679232109146.png "Asks to install it")
