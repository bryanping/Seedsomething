# iOS Build Checklist (Seedsomething)

1) xcode-select 指向 Xcode.app
- sudo xcode-select -s /Applications/Xcode.app
- xcodebuild -version

2) scheme 存在
- xcodebuild -list

3) simulator destination 存在
- xcrun simctl list devices | rg "iPhone 16"

4) build
- scripts/ai_verify.sh
- scripts/ai_build.sh（固定 iPhone 16）

5) 若 SPM 卡住
- 重跑 xcodebuild -resolvePackageDependencies
