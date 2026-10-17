# PhotoPurge

PhotoPurge is a fluid, high-performance iOS photo management and cleanup utility written in Objective-C and UIKit. Inspired by card-swiping interactions, PhotoPurge turns the tedious task of decluttering your camera roll into an intuitive, fast, and satisfying experience. Review photos, videos, screenshots, and Live Photos one by one, stage unwanted media for deletion, and reclaim disk space with transparent batch confirmation and real-time storage metrics.

## App Layout & Appearance

The app natively adapts to both Light and Dark appearances across iOS and iPadOS.

| Light Mode | Dark Mode |
| :---: | :---: |
| <img src="screenshots/main_light.jpeg" alt="PhotoPurge Light Mode" width="380" /> | <img src="screenshots/main_dark.jpeg" alt="PhotoPurge Dark Mode" width="380" /> |

## Tools & Technologies Used

- Language: Objective-C (with Automatic Reference Counting / ARC enabled, modern LLVM compiler flags, strict nullability annotations).
- User Interface: UIKit (100% programmatic Auto Layout, custom Core Animation spring physics, affine transforms, blurred visual effect materials (`UIVisualEffectView`), and modern `UIMenu` / `UIAction` controls).
- Photo Library Management: Apple Photos and PhotosUI frameworks:
  - `PHPhotoLibrary`: Access control, permission lifecycle, transactional batch deletion (`PHAssetChangeRequest`), and live change monitoring (`PHPhotoLibraryChangeObserver`).
  - `PHCachingImageManager`: High-efficiency image caching with a dynamic sliding lookahead preheat pipeline.
  - `PHAsset` & `PHAssetCollection`: Querying camera rolls, albums, and smart albums (Screenshots, Live Photos, Videos).
  - `PHLivePhotoView`: Native Live Photo playback and gesture handling.
  - `PHAssetResource`: Byte-accurate calculation of asset disk footprints without reading raw file data into memory.
- Media Playback: AVFoundation (`AVPlayer`, `AVPlayerItem`, and custom `AVPlayerLayer` wrapper `PPPlayerView`) for seamless, low-overhead looped video playback with audio mute controls.
- Haptics: `UIImpactFeedbackGenerator` providing tactile feedback when card drags reach deletion or preservation thresholds.
- Persistence: `NSUserDefaults` & `NSByteCountFormatter` for tracking and formatting cumulative lifetime storage reclaimed across sessions.

## Minimum Requirements

| Requirement | Specification |
| :--- | :--- |
| Operating System | iOS 17.6 or later / iPadOS 17.6 or later |
| Supported Devices | iPhone (`TargetedDeviceFamily 1`) and iPad (`TargetedDeviceFamily 2`) |
| Development Environment | Xcode 16.0 or later running on macOS Sonoma 14.5+ or macOS Sequoia 15.0+ |
| Architecture | `arm64` (Apple Silicon physical devices) and `arm64` / `x86_64` (iOS Simulator) |
| Dependencies | None (pure native Apple system SDK frameworks, no third-party pods or packages required) |

## Permissions & Privacy

PhotoPurge requires explicit read and write access to your Photo Library to load media, stream video/Live Photos, and submit items for deletion upon your confirmation.

- Info.plist Key: `NSPhotoLibraryUsageDescription`
- Default System Description: "PhotoPurge needs access to your photos to help you manage and delete them."
- Access Level Requested: `PHAccessLevelReadWrite` via `PHPhotoLibrary requestAuthorizationForAccessLevel:handler:`

### Authorization Handling

1. Not Determined (`PHAuthorizationStatusNotDetermined`):
   - The user is greeted by an onboarding / pre-prompt screen explaining the necessity of photo access prior to invoking the native iOS permission modal.
2. Authorized (`PHAuthorizationStatusAuthorized`) & Limited (`PHAuthorizationStatusLimited`):
   - The permission overlay automatically dismisses, and the swipe deck populates with media. Both full library and limited photo selection modes are supported.
3. Denied (`PHAuthorizationStatusDenied`) & Restricted (`PHAuthorizationStatusRestricted`):
   - Active media cards are hidden, control buttons are dimmed and disabled, and an Access Restricted card is presented with a direct button to deep-link straight to the app's permission settings in iOS Settings (`UIApplicationOpenSettingsURLString`).

## How the App Works

PhotoPurge is designed around a zero-clutter, card-stack architecture that maximizes speed while guaranteeing that no photo is deleted without explicit user confirmation. As illustrated in the screenshots above, the interface centers around an interactive card deck flanked by top navigation utilities and a bottom action cluster.

### 1. Dual-Card Stack Model
- The app maintains two cards in memory at any given time:
  - `topCardView`: The front card that responds to user touch, gestures, and active playback (video or Live Photo).
  - `bottomCardView`: Subtly pre-rendered beneath the top card scaled down to 0.95. As soon as the top card is swiped away, the bottom card instantly scales up with a smooth 0.25s animation to become the new top card, while the next card is prepared asynchronously in the background.

### 2. High-Performance Sliding Preheat Window
- To ensure buttery 60/120fps interactions without high memory consumption, `PHCachingImageManager` operates on a sliding window:
  - Ahead: Assets `[currentIndex + 2 ... currentIndex + 5]` are pre-cached in exact card dimensions (`PHImageContentModeAspectFill`).
  - Behind: Assets that pass out of view are immediately evicted from the cache to keep memory usage minimal.

### 3. Non-Destructive Deletion Staging Pipeline
- Swiping a card left does not immediately delete the photo from your device.
- It stages the asset into a local deletion queue (`pendingDeletionAssets`).
- Only when the user taps the Confirm Delete button is a destructive batch transaction submitted to `PHPhotoLibrary`, prompting the official iOS system confirmation dialog.

## Gestures & Interaction Guide

### Swiping Left (Purge / Delete)
- Gesture: Drag the top card horizontally towards the left.
- Visual Feedback: 
  - The card rotates counter-clockwise proportionally up to 20° (-0.35 rad).
  - A red PURGE stamp badge tilts (+11°) and fades in on the top-right of the card.
  - A subtle translucent red overlay tints the card up to 28% opacity.
  - When reaching the 120pt threshold, a tactile medium haptic impulse triggers.
- Action: If released past 120pt or with a fling velocity exceeding 800 pt/s, the card animates off-screen to the left, enters the staged deletion queue, increments the badge counter on the trash button, and pushes an undo entry into history.

### Swiping Right (Keep / Preserve)
- Gesture: Drag the top card horizontally towards the right.
- Visual Feedback: 
  - The card rotates clockwise proportionally up to 20° (+0.35 rad).
  - A green KEEP stamp badge tilts (-11°) and fades in on the top-left of the card.
  - A subtle translucent green overlay tints the card up to 28% opacity.
  - When reaching the 120pt threshold, a tactile medium haptic impulse triggers.
- Action: If released past 120pt or with a fling velocity exceeding 800 pt/s, the card animates off-screen to the right, preserves the photo in your library, and advances the stack.

### Sub-Threshold Snap Back
- If the drag is released before crossing the threshold or without fling momentum, the card snaps back into the center with a spring damping animation (`damping: 0.75`), fading out badges and color overlays and resuming media playback.

### Live Photos & Videos
- Live Photos: Press and hold anywhere on a Live Photo card to trigger native playback (`PHLivePhotoViewPlaybackStyleFull`). Releasing stops playback.
- Videos: Automatically loop seamlessly with hardware acceleration. A volume pill in the bottom-right corner allows instant toggling between mute and audio playback.

## Controls & Navigation Buttons

| UI Element | Location | Icon / Visual | Function & Description |
| :--- | :--- | :--- | :--- |
| Storage Counter | Top-Left Navigation Bar | `internaldrive` pill | Displays the cumulative lifetime storage reclaimed by PhotoPurge (e.g., 0 KB, 450 MB, 3.2 GB). Bounces with an elastic spring animation each time deletions are confirmed. |
| Filter Button | Top-Right Navigation Bar | `line.3.horizontal.decrease.circle` | Opens a menu to switch active media stacks: All Photos, Screenshots, Videos, and Live Photos. Checks the currently active filter. |
| Undo / Restore | Control Cluster (Top / Middle-Up) | `arrow.uturn.backward` (Orange) | Pops the last action from history. If the photo was staged for deletion, it unstages it, decrements the badge, rewinds the stack index, and slides the restored photo back onto the stack from off-screen with spring physics. Disabled when no actions exist. |
| Purge Button | Control Cluster (Left) | `xmark` (Red, 56pt) | Programmatically swipes the top card to the left, staging it for deletion without needing to drag. Disabled on completion or permission views. |
| Keep Button | Control Cluster (Right) | `checkmark` (Green, 56pt) | Programmatically swipes the top card to the right, keeping the photo without needing to drag. Disabled on completion or permission views. |
| Confirm Deletion | Control Cluster (Bottom / Middle-Down) | `trash.fill` (Red, 44pt) + Badge | Displays the count of items currently staged for deletion (e.g., 1, 14, 99+). Tapping presents a batch confirmation sheet to permanently commit deletions to the Photos library. Disabled when staged count is 0. |
| Volume Toggle | Bottom-Right of Video Cards | `speaker.slash.fill` / `speaker.wave.2.fill` | Embedded directly on video cards. Toggles video playback mute state on and off with haptic bounce feedback. |

## Edge Cases & Fault Tolerance

PhotoPurge includes comprehensive defense-in-depth handling for iOS edge conditions:

### 1. Empty Media Stack (PPCompletionView)
- When it happens: When a chosen category (e.g., Videos or Screenshots) has 0 photos, or after swiping through the last item in a stack.
- Behavior: The card stack cross-dissolves into the `PPCompletionView` card ("All Caught Up!" with a green seal badge):
  - With staged deletions: Displays total reviewed and staged count, featuring a prominent red "Purge X Photos Now" button.
  - Without staged deletions: Displays total reviewed count, featuring a blue "Review From Beginning" button to restart the stack.
  - Tapping Undo while looking at the completion screen immediately dismisses the completion view and pulls the previous card back into view.

### 2. Switching Filter with Staged Purges
- When it happens: If you swipe photos into the trash and attempt to switch categories (e.g., from All Photos to Screenshots) using the filter menu.
- Behavior: PhotoPurge intercepts the action with a safety action sheet:
  - "Commit Purges First": Executes deletion of the staged photos, updates the storage counter, and then switches filter.
  - "Discard Staged & Switch": Clears staged deletions and history, then switches filter.
  - "Cancel": Leaves current stack and staged purges intact.

### 3. Background Permission Changes
- When it happens: User minimizes the app, navigates to iOS Settings > PhotoPurge, and revokes or limits photo access.
- Behavior: The app subscribes to `UIApplicationWillEnterForegroundNotification`. Upon resuming, it instantly re-evaluates `PHPhotoLibrary authorizationStatusForAccessLevel:` and presents or dismisses the permission card accordingly.

### 4. External Library Mutations (PHPhotoLibraryChangeObserver)
- When it happens: Photos are edited, deleted, or captured in the native Apple Photos or Camera app while PhotoPurge is running or in background.
- Behavior: PhotoPurge implements `photoLibraryDidChange:`:
  - Prunes any staged deletion references and undo history items for assets that were deleted externally.
  - Adjusts current stack pointers and rebuilds the card stack if the currently visible top photo was deleted outside the app.
  - Inserts restored or new photos seamlessly into the stack if they appear before or at the current viewing index.

### 5. Deletion Cancellation or Failure
- When it happens: User confirms in PhotoPurge, but taps "Don't Allow" on Apple's native system prompt, or the disk write fails.
- Behavior: Handled cleanly in `performChanges:completionHandler:`. Storage counters are only incremented upon confirmed `success == YES`. Staged assets remain available for re-evaluation.

### 6. iPadOS Popover Presentation Safety
- All action sheets and alert dialogs anchor their `popoverPresentationController.sourceView` or `barButtonItem` to avoid UIKit presentation crashes on iPad screen layouts.

## Building & Running

1. Clone or download the repository to your Mac:
   ```bash
   git clone https://github.com/adamsat2/PhotoPurge.git
   cd PhotoPurge
   ```
2. Open `PhotoPurge.xcodeproj` in Xcode 16+:
   ```bash
   open PhotoPurge.xcodeproj
   ```
3. Select an active scheme (`PhotoPurge`) and choose a target device or simulator (iOS 17.6+).
4. Press ⌘ + R to compile, install, and run.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
