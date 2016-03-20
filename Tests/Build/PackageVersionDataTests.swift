/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

@testable import Build
import PackageType
import XCTest
import PackageDescription

final class PackageVersionDataTests: XCTestCase {

    func makePackage() -> PackageType.Package {
        let m = Manifest(path: "path", package: PackageDescription.Package(), products: [])
        return Package(manifest: m, url: "https://github.com/testPkg")
    }

    func testPackageData(package: PackageType.Package, url: String, version: Version?) {
        var expected = "public let url: String = \"\(url)\" \n" +
            "public let version: (Int, Int, Int, [String], String?)?"
        if let version = version {
            expected += " = (\(version.major), \(version.minor), \(version.patch), \(version.prereleaseIdentifiers), \(version.buildMetadataIdentifier)) \n"
        }

        let metadata = packageVersionData(package)
        XCTAssertEqual(metadata, expected)
    }

    func testPackageVersionData() {
        let package = makePackage()
        package.version = Version(1, 2, 3)
        testPackageData(package, url: "https://github.com/testPkg", version: Version(1, 2, 3))
    }

    func testPackageEmptyVersionData() {
        let package = makePackage()
        package.version = nil
        testPackageData(package, url: "https://github.com/testPkg", version: nil)
    }

    func testSavePackageVersionDataToFile() {
        mktmpdir { dir in
            let package = makePackage()
            try generateVersionData(dir, packages: [package])
            XCTAssertFileExists(dir, ".build/versionData/", "\(package.name).swift")
        }
    }
}

extension PackageVersionDataTests {
    static var allTests: [(String, PackageVersionDataTests -> () throws -> Void)] {
        return [
                   ("testPackageVersionData", testPackageVersionData),
                   ("testPackageEmptyVersionData", testPackageEmptyVersionData),
                   ("testSavePackageVersionDataToFile", testSavePackageVersionDataToFile),
        ]
    }
}