# Publishing checklist

Everything here is done by you once; the scripts take care of the rest.

## 1. Make the identifiers yours

The code uses the GitHub user name `mizhar-developer` and the widget id
`io.github.mizhar-developer.batterymode`. If you publish a fork under another
GitHub user name, replace both in one go (run from the repository root):

```sh
sed -i 's/github.com\/mizhar-developer\//github.com\/YOURNAME\//g; s/io\.github\.mizhar-developer\./io.github.YOURNAME./g' \
    README.md PUBLISHING.md plasmoid/metadata.json plasmoid/contents/ui/main.qml
```

Then edit `plasmoid/metadata.json`: add an `"Email"` next to the author name
if you want one published, and check `"Version"` (bump it for every store upload).

## 2. Screenshots

The store wants at least one. `screenshots/popup.png` is shown at the top of
`README.md` and doubles as the store screenshot. When the popup changes, open it
from the tray, capture it with Spectacle (Meta+Shift+Print for a region) and
save over that file.

## 3. Put the source online

```sh
git add -A
git commit -m "Battery Mode 1.0.0"
git remote add origin git@github.com:YOURNAME/battery-mode.git
git push -u origin main
git tag v1.0.0 && git push --tags
```

## 4. Build and test the widget file

```sh
./build-plasmoid.sh            # writes dist/<id>-<version>.plasmoid
```

Test it the way a store user gets it: on a clean user account (or after
`kpackagetool6 -t Plasma/Applet -r io.github.mizhar-developer.batterymode`), right-click
the desktop › *Add Widgets…* › *Get New Widgets…* › *Install Widget From Local
File…* and pick the file. Check that the icon shows, the popup opens, and the
"service not running" note appears with a working link.

## 5. KDE Store

1. Create an account at https://store.kde.org (it is an OpenDesktop account).
2. *Add Product*. Category: **Plasma 6 Extensions** (this is the category that
   Plasma's *Get New Widgets…* dialog and Discover query; pick the widgets
   sub-category if the site offers one).
3. Fill in name, description (copy the first paragraph and the mode table from
   `README.md`, and state clearly that it is for ThinkPads with charge-threshold
   support and needs the background service from the repository), license MIT,
   the repository link, and the screenshots.
4. Upload `dist/<id>-<version>.plasmoid` as the file.
5. Publish. The listing appears in *Get New Widgets…* within a few minutes.
   Plasma shows a standard "this widget may run executables" warning for every
   widget in this category; that is expected (the widget runs `upower` and `cat`).

## 6. Updating later

Bump `"Version"` in `metadata.json`, rebuild, upload the new file to the same
product, and push a matching git tag.
