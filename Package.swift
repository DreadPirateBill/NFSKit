// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NFSKit",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NFSKit",
            // Dynamic so libnfs sits behind a replaceable framework boundary. libnfs is LGPL-2.1-or-later and
            // ships here as a static archive (Framework/Libnfs.xcframework holds libnfs.a), so a statically
            // linked NFSKit copies it straight into the consuming application binary. That forecloses LGPL 2.1
            // section 6(b) -- the "suitable shared library mechanism" route -- and leaves only 6(a), which asks
            // the distributor to supply relinkable object files. A code-signed App Store binary cannot satisfy
            // 6(a), so a proprietary app had no compliant way to use this package.
            //
            // Built dynamically, the consumer links NFSKit.framework and a user can substitute a framework
            // built against a modified libnfs, which is what 6(b) asks for. This mirrors AMSMB2, which ships
            // the sibling libsmb2 the same way (type: .dynamic).
            type: .dynamic,
            targets: ["NFSKit"])
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NFSKit",
            dependencies: ["nfs"]),
        .testTarget(
            name: "NFSKitTests",
            dependencies: ["NFSKit"]),
        .target(
            name: "nfs",
            dependencies: ["Libnfs"],
            cSettings: [
                .define("HAVE_CONFIG_H", to: "1"),
                .define("_U_", to: "__attribute__((unused))"),
                .define("HAVE_GETPWNAM", to: "1"),
                .define("HAVE_SOCKADDR_LEN", to: "1"),
                .define("HAVE_SOCKADDR_STORAGE", to: "1"),
                .define("HAVE_TALLOC_TEVENT", to: "1")
            ]),
        .binaryTarget(
            name: "Libnfs",
            path: "Framework/Libnfs.xcframework")
    ])
