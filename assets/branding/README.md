# Launcher icon

The eagle head in `eagle.svg` is an original symbol for this independent launcher, not the official Bielik or SpeakLeash logo.

The palette follows the landing page: dark olive `#424237`, cream `#FFF9F5`, and coral `#F66953`. The 108 × 108 source keeps the bird within the central area used by adaptive launcher masks.

Android resources:

- `drawable/ic_launcher_foreground.xml`: matching colored vector artwork.
- `drawable/ic_launcher_monochrome.xml`: silhouette with eye cutouts for themed icons.
- `mipmap-anydpi-v26/`: adaptive square/round icon definitions.
- `mipmap-anydpi-v33/`: adaptive definitions with a monochrome layer.
- `mipmap-*/ic_launcher.png` and `ic_launcher_round.png`: legacy PNG exports at 48, 72, 96, 144, and 192 px for mdpi through xxxhdpi.
- `values/launcher_colors.xml`: adaptive icon background.

`site/assets/mark.svg` uses the same artwork with a rounded background for the landing page and browser favicon. Keep the SVG, Android vectors, and PNG exports in sync when changing the design. The source SVG is not bundled as a Flutter UI asset.
