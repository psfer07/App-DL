# App-DL

This program is a simple package manager which downloads packaged portable apps from official repositories.

All you need to do is typing or copying this command in your powershell terminal. It will redirect you to the app.

```powershell
irm bit.ly/psappdl | iex
```


## Changelog

### App-DL v1.0.0 (First release)

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
