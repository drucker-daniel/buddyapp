// swift-tools-version: 5.9
// This file is only for reference — add Firebase via Xcode's SPM integration.
// In Xcode: File > Add Package Dependencies...
// URL: https://github.com/firebase/firebase-ios-sdk
// Version: Up to Next Major from 10.0.0

import PackageDescription

let package = Package(
    name: "buddyapp",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.0.0"
        ),
    ],
    targets: [
        .target(
            name: "buddyapp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ]
        ),
    ]
)
