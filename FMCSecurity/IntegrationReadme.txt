- Add FMCSecurity root directory to Root of Project Directory
- Add FMCSecurity’s child FMCSecurity directory to Xcode Project
  
- Cocoapod Settings
  - If using Cocoapods, be sure to set “Build Active Architecture Only” to NO.

- Project Build Settings
  - Write Link Map File = YES
  - Enable Bitcode = NO
  - Header Search Paths
    - $(PROJECT_DIR)/FMCSecurity/FMCSecurity/common
  - Library Search Paths
    - Debug
      - $(PROJECT_DIR)/FMCSecurity/FMCSecurity/debug
    - Release
      - $(PROJECT_DIR)/FMCSecurity/FMCSecurity/release

- Target Build Phases
  - Add “New Run Script Phase”
  - Copy contents of Finalizer_Build_Phase.sh into this shell.