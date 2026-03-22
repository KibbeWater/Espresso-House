# Espresso House

A third-party iOS client for the Espresso House loyalty program, built with SwiftUI.

## Features

- **Member ID & Barcode** — scan-ready barcode with flip-to-show via device orientation
- **Fika Club** — track fika points, challenges, and progress
- **Wallet** — view balance, coupons, and punch cards
- **Shop Finder** — browse coffee shop locations
- **Order Menu** — browse the full product menu with cached images
- **Authentication** — SMS-based login using the Espresso House registration flow with proof-of-work

## Requirements

- iOS 18.1+
- Xcode 16+
- Swift 5.0+

## Dependencies

- [Alamofire](https://github.com/Alamofire/Alamofire) — networking
- [Kingfisher](https://github.com/onevcat/Kingfisher) — image loading & caching
- [Cache](https://github.com/hyperoslo/Cache) — response caching

All dependencies are managed via Swift Package Manager.

## Getting Started

1. Clone the repository
2. Open `Espresso House.xcodeproj` in Xcode
3. Resolve Swift packages (File > Packages > Resolve Package Versions)
4. Build and run on a simulator or device

## API

This app communicates with the [Espresso House Mobile App API](https://kibbewater.github.io/espresso-api/). Authentication is handled via BPAuth headers with credentials stored securely in the iOS Keychain.

## Disclaimer

This is an unofficial, independently developed client and is not affiliated with or endorsed by Espresso House. Use at your own risk.
