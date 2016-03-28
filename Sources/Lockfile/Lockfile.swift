/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Utility
import func POSIX.mkdir
import func POSIX.fopen
import func POSIX.fputs
import func libc.fclose

public struct Lockfile {

    public static func generate(dir: String) throws {
        let filePath = Path.join(dir, Lockfile.fileName)
        let file = try fopen(filePath, mode: .Write)
        defer {
            libc.fclose(file)
        }
        let content = try lockFileContent(dir)
        try fputs(content, file)
    }

    static func lockFileContent(rootDir: String) throws -> String {
        var json = "{ \n"
        json += "\t\"packages\": [ \n"

        let packagesDir = Path.join(rootDir, "Packages")
        let dirs = walk(packagesDir, recursively: false).filter { $0.isDirectory }
        let packages = try dirs.map(packageJson)
        json += packagesJson(packages)

        json += "\t]\n"
        json += "}\n"
        print(json)

        return json
    }

    static var exist: Bool {
        return true
    }

    static let fileName = "PackageVersions.json"
}

func packagesJson(packages:  [String]) -> String {
    guard !packages.isEmpty else {
        return ""
    }

    var json = "\t\t"
    for pkg in packages {
        json += "{ \n"
        json += pkg
        json += "\t\t}, "
    }
    json.characters.removeLast(2)
    json += "\n"

    return json
}

func packageJson(dir: String) throws -> String {
    guard let repo = Git.Repo(path: dir) else {
        throw Error.NoGitRepo(dir.basename)
    }
    return packageJson(dir.basename, repo: repo)
}


func packageJson(clone: String, repo: Git.Repo) -> String {
    guard let origin = repo.origin else {
        //TODO: halde error
        return ""
    }
    var json = ""
    json += "\t\t\t\"clone\": \"Packages/\(clone)\",\n"
    json += "\t\t\t\"origin\": \"\(origin)\",\n"

    //TODO: add ref and sha values
    json += "\t\t\t\"ref\": \"\",\n"
    json += "\t\t\t\"sha\": \"\"\n"

    return json
}