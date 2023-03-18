# App-DL

This program is a simple package manager which downloads packaged portable apps from official repositories.

All you need to do is typing or copying this command in your powershell terminal. It will redirect you to the app.

```powershell
irm bit.ly/psappdl | iex
```


## Changelog

### App-DL v1.1

---

* Improved performance and many bugs are fixed
* Now it checks if even the package or the app are stored in the selected directory
  * Added the "open" option, which allows the user to skip the downloading steps if the app or the package is allocated in the specified path

  * Fixed the "restart" and "exit" options, which didn't appear
* Added app descriptions
* Added recommended parameters for some apps and their corresponding description
* Added new portable apps to the library

# ---

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
