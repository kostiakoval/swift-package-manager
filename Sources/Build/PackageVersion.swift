/*
 This source file is part of the Swift.org open source project

 Copyright 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import POSIX
import PackageType
import class Utility.Git
import struct Utility.Path
import func libc.fclose

public func generateVersionData(_ rootDir: String, rootPackage: Package, externalPackages: [Package]) throws {
    let dirPath = Path.join(rootDir, ".build/versionData")
    try mkdir(dirPath)

    let packages = externalPackages + [rootPackage]
    for pkg in packages {
        let data = try versionData(package: pkg)
        try saveVersionData(dirPath, packageName: pkg.name, data: data)
    }
}

func versionData(package: Package) throws -> String {
    let repo = Git.Repo(path: package.path)

    //TODO: user repo?.origin ?? package.url. Not it exits if there is origin
    var data = "public let url: String = \"\(package.url)\"\n"

    data += "public let version: (major: Int, minor: Int, patch: Int, prereleaseIdentifiers: [String], buildMetadata: String?) = "
    if let version = package.version {
        data += "\(version.major, version.minor, version.patch, version.prereleaseIdentifiers, version.buildMetadataIdentifier)\n"
        data += "public let versionString: String = \"\(version)\"\n"
    } else {
        data += "(0, 0, 0, [], nil) \n"
        data += "public let versionString: String = \"0.0.0\"\n"
    }

    data += "public let sha: String? = "
    if let repo = repo {
        if let version = package.version {
            let prefix = repo.versionsArePrefixed ? "v" : ""
            let versionSha = try repo.versionSha(tag: "\(prefix)\(version)")

            if repo.sha != versionSha {
                data += "\"\(repo.sha)\"\n"
            } else {
                data += "nil\n"
            }
        } else {
            data += "\"\(repo.sha)\"\n"
        }

        data += "public let modified: Bool = "
        data += repo.hasLocalChanges ? "true" : "false"
        data += "\n"

    } else {
        data += "nil\n"
        data += "public let modified: Bool = false\n"
    }

    return data
}

private func saveVersionData(_ dirPath: String, packageName: String, data: String) throws {
    let filePath = Path.join(dirPath, "\(packageName).swift")
    let file = try fopen(filePath, mode: .Write)
    defer {
        libc.fclose(file)
    }
    try fputs(data, file)
}
