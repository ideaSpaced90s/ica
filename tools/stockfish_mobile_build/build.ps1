# Build script for mobile-optimized standalone Stockfish on Android
# This script uses the Android NDK to compile libstockfish.so for arm64-v8a.

$NDK_PATH = "C:\Android\Sdk\ndk\28.2.13676358"
$CMAKE_DIR = "C:\Android\Sdk\cmake\3.22.1\bin"
$CMAKE_PATH = "$CMAKE_DIR\cmake.exe"
$STRIP_PATH = "$NDK_PATH\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-strip.exe"
$TOOLCHAIN = "$NDK_PATH\build\cmake\android.toolchain.cmake"

# Add CMake directory to the temporary PATH so it can find ninja.exe which is in the same folder.
$env:PATH = "$CMAKE_DIR;" + $env:PATH

$BUILD_DIR = "out"
$ABI = "arm64-v8a"
$MIN_SDK = "26"

Write-Host "Configuring CMake for Stockfish (ABI: $ABI, Min SDK: $MIN_SDK)..."
& $CMAKE_PATH -G "Ninja" `
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" `
  -DANDROID_ABI="$ABI" `
  -DANDROID_PLATFORM="android-$MIN_SDK" `
  -DCMAKE_BUILD_TYPE=Release `
  -S . `
  -B $BUILD_DIR

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed!"
    exit 1
}

Write-Host "Building Stockfish..."
& $CMAKE_PATH --build $BUILD_DIR --config Release

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake build failed!"
    exit 1
}

Write-Host "Stripping binary..."
& $STRIP_PATH "$BUILD_DIR\libstockfish.so"

Write-Host "Verifying binary..."
$binaryPath = "$BUILD_DIR\libstockfish.so"
if (Test-Path $binaryPath) {
    $size = (Get-Item $binaryPath).Length / 1MB
    Write-Host "Binary built successfully at $binaryPath!"
    Write-Host ("Size: {0:N2} MB" -f $size)
} else {
    Write-Error "Binary was not found at $binaryPath!"
    exit 1
}
