GA-SDK-CPP
==========

GameAnalytics C++ SDK

Documentation can be found [here](https://gameanalytics.com/docs/cpp-sdk).

Supported platforms:

* Mac OSX (x86_64 + arm64 universal binary)
* iOS (arm64 device + arm64/x86_64 simulator, XCFramework)
* Android (arm64-v8a, armeabi-v7a, x86_64)
* Windows 32-bit and 64-bit
* Linux

Dependencies
------------

* cmake  3.20 or higher
* **Mac/iOS:** XCode + command line tools
* **Android:** Android NDK (r21+)
* **Windows:** Visual Studio 2017 or later
* **Linux:** clang or gcc

Building Static Libraries
-------------------------

Build scripts are provided for each target platform. All scripts accept an
optional configuration argument (`Release` or `Debug`, defaults to `Release`).

### Build all platforms at once

```sh
./build_all.sh [Release|Debug]
```

### macOS

Builds a universal static library for both x86_64 and arm64.

```sh
./build_macos.sh [Release|Debug]
```

Output:
```
output/macos/
  lib/libGameAnalytics.a
  include/GameAnalytics/
```

### iOS

Builds static libraries for device (arm64) and simulator (arm64 + x86_64),
then packages them into an XCFramework.

```sh
./build_ios.sh [Release|Debug]
```

Set a custom deployment target (default 13.0):
```sh
IOS_DEPLOYMENT_TARGET=15.0 ./build_ios.sh Release
```

Output:
```
output/ios/
  GameAnalytics.xcframework/      # ready to drop into Xcode
  device/lib/libGameAnalytics.a   # device-only static lib
  simulator/lib/libGameAnalytics.a
  include/GameAnalytics/
```

### Android

Builds static libraries for arm64-v8a, armeabi-v7a, and x86_64.
Requires the Android NDK. Set one of these environment variables:

```sh
export ANDROID_NDK=$HOME/Library/Android/sdk/ndk/<version>
# or
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/<version>
# or
export ANDROID_HOME=$HOME/Library/Android/sdk  # uses latest installed NDK
```

Then build:
```sh
./build_android.sh [Release|Debug]
```

Set a custom minimum SDK version (default 24):
```sh
ANDROID_MIN_SDK=21 ./build_android.sh Release
```

Output:
```
output/android/
  arm64-v8a/lib/libGameAnalytics.a
  armeabi-v7a/lib/libGameAnalytics.a
  x86_64/lib/libGameAnalytics.a
  include/GameAnalytics/
```

### CMake directly

You can also invoke CMake directly for more control:

```sh
# macOS
cmake -B build/macos -DPLATFORM=osx -DCMAKE_BUILD_TYPE=Release -DGA_BUILD_SAMPLE=OFF -DGA_BUILD_TESTS=OFF
cmake --build build/macos --config Release

# iOS device
cmake -B build/ios -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 -DPLATFORM=ios -DGA_BUILD_SAMPLE=OFF -DGA_BUILD_TESTS=OFF
cmake --build build/ios --config Release

# Android (requires NDK toolchain)
cmake -B build/android \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_NATIVE_API_LEVEL=24 \
  -DANDROID_STL=c++_static \
  -DPLATFORM=android \
  -DGA_BUILD_SAMPLE=OFF \
  -DGA_BUILD_TESTS=OFF
cmake --build build/android --config Release
```

Linking Against the Static Library
-----------------------------------

When linking the GameAnalytics static library into your game, you must also
link the following dependencies:

**All platforms:**
* libcurl (static or dynamic)
* OpenSSL (libssl, libcrypto)

**macOS additionally:**
* CoreFoundation, Foundation, CoreServices, SystemConfiguration, Metal, MetalKit

**iOS additionally:**
* CoreFoundation, Foundation, UIKit, SystemConfiguration, Security

**Android additionally:**
* log (Android logging)

The prebuilt curl and OpenSSL binaries for macOS and Linux are included in the
`externals/` directory. For iOS and Android you need to provide your own
builds of curl and OpenSSL for the target platform.

Legacy Build System
-------------------

The original `setup.py` script is still available for desktop platforms:

```sh
python setup.py --platform {linux_x64,linux_x86,osx,win32,win64,uwp} [--cfg {Release,Debug}] [--build] [--test] [--coverage]
```

Lib Dependencies
----------------

* **crossguid** (*as source*) - Cross platform library to generate a Guid.
* **cryptoC++** (*as source*) - collection of functions and classes for cryptography related tasks.
* **curl** (*as binary*) - library used to make HTTP requests.
* **nlohmann json** (*as source*) - lightweight C++ library for manipulating JSON values including serialization and deserialization.
* **openssl** (*as binary*) - used by **curl** to make HTTPS requests.
* **SQLite** (*as source*) - SQLite is a software library that implements a self-contained, serverless, zero-configuration, transactional SQL database engine.

*as source* means the dependency will be compiled with the project itself, *as binary* means the dependency is prebuild and will be linked to the project

Usage of the SDK
----------------

Remember to include the GameAnalytics header file wherever you are using the SDK:

``` c++
 #include "GameAnalytics/GameAnalytics.h"
```

### Custom log handler
If you want to use your own custom log handler here is how it is done:
``` c++
void logHandler(const char *message, gameanalytics::EGALoggerMessageType type)
{
    // add your logging in here
}

gameanalytics::GameAnalytics::configureCustomLogHandler(logHandler);
```

### Configuration

Example:

``` c++
 gameanalytics::GameAnalytics::setEnabledInfoLog(true);
 gameanalytics::GameAnalytics::setEnabledVerboseLog(true);

 gameanalytics::GameAnalytics::configureBuild("0.10");

 {
     std::vector<std::string> list;
     list.push_back("gems");
     list.push_back("gold");
     gameanalytics::GameAnalytics::configureAvailableResourceCurrencies(list);
 }
 {
     std::vector<std::string> list;
     list.push_back("boost");
     list.push_back("lives");
     gameanalytics::GameAnalytics::configureAvailableResourceItemTypes(list);
 }
 {
     std::vector<std::string> list;
     list.push_back("ninja");
     list.push_back("samurai");
     gameanalytics::GameAnalytics::configureAvailableCustomDimensions01(list);
 }
 {
     std::vector<std::string> list;
     list.push_back("whale");
     list.push_back("dolphin");
     gameanalytics::GameAnalytics::configureAvailableCustomDimensions02(list);
 }
 {
     std::vector<std::string> list;
     list.push_back("horde");
     list.push_back("alliance");
     gameanalytics::GameAnalytics::configureAvailableCustomDimensions03(list);
 }
```

### Initialization

Example:

``` c++
 gameanalytics::GameAnalytics::initialize("<your game key>", "<your secret key>");
```

### Send events

Example:

``` c++
 gameanalytics::GameAnalytics::addDesignEvent("testEvent");
 gameanalytics::GameAnalytics::addBusinessEvent("USD", 100, "boost", "super_boost", "shop");
 gameanalytics::GameAnalytics::addResourceEvent(gameanalytics::Source, "gems", 10, "lives", "extra_life");
 gameanalytics::GameAnalytics::addProgressionEvent(gameanalytics::Start, "progression01", "progression02");
```
