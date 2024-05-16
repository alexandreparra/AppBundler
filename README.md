## AppBundler

AppBundler is a simple MacOS program made with SwiftUI that creates a [standard bundle structure] (https://developer.apple.com/documentation/bundleresources/placing_content_in_a_bundle) out of your binary and image. You can also inspect a bundle to change it's name.


### Create bundle

![create bundle preview image](Assets/create_bundle.png)

To create a bundle you need to simply provide the bundle name and a native MacOS executable. The binary can be created in virtually any language that correctly generates native MacOS binaries so that the system can execute it, notice that for interpreted languages (like Python or Java) or terminal programs, the bundle won't work. 
You can optionally provide an image to your bundle that will be displayed on your Finder, Launchpad and Dock.

### Edit bundle
![edit bundle preview image 01](Assets/edit_bundle_01.png)
![edit bundle preview image 02](Assets/edit_bundle_02.png)

You can load any valid bundle and inspect it's name and image, and optionally edit the bundle name.

## Build Bundle
To build a `.app` of AppBundler simply run the automated script in the root folder:

```bash
./build_bundle.sh
```
