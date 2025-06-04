# WoT Map Editor

A Flutter tool for placing and annotating markers on map images from World of Tanks. The app lets you load any image and draw several types of objects:

- **Points** – mark tank positions with an identifier, description and tank type.
- **Zones** – drag out rectangular regions and label them.
- **Brush** – freehand areas created by drawing a path on the map.

All added objects can be exported to JSON so that the data can be used elsewhere.

## Usage

1. Launch the app and press the image button to choose a map picture.
2. Select a tank type and a drawing tool.
3. Tap or drag on the map to create markers or areas.
4. Use the toolbar to undo, clear everything, save the JSON file or view its contents.

The resulting JSON structure contains the original image name along with all collected points, zones and brushes.

## Development

The project uses Flutter. Run `flutter pub get` to fetch dependencies and `flutter run` to start the application. Widget tests are located in `test/`.
