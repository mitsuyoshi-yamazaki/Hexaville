//
//  DockerBuildEnvironmentProvider.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

struct DockerBuildEnvironmentProvider: SwiftBuildEnvironmentProvider {
    
    func build(config: Configuration, hexavilleApplicationPath: String) throws -> BuildResult {
        try String(contentsOfFile: "\(projectRoot)/Scripts/build-swift.sh")
            .write(toFile: "\(hexavilleApplicationPath)/build-swift.sh", atomically: true, encoding: .utf8)
        
        try String(contentsOfFile: projectRoot+"/templates/Dockerfile", encoding: .utf8)
            .replacingOccurrences(of: "{{SWIFT_DOWNLOAD_URL}}", with: SwiftBuilder.swiftDownloadURL)
            .replacingOccurrences(of: "{{SWIFTFILE}}", with: SwiftBuilder.swiftFileName)
            .write(
                toFile: hexavilleApplicationPath+"/Dockerfile",
                atomically: true,
                encoding: .utf8
        )
        
        try String(contentsOfFile: projectRoot+"/templates/.dockerignore", encoding: .utf8)
            .write(
                toFile: hexavilleApplicationPath+"/.dockerignore",
                atomically: true,
                encoding: .utf8
        )
        
        let tag = "hexaville-app"
        
        var opts = ["build", "-t", tag, "-f", "\(hexavilleApplicationPath)/Dockerfile", hexavilleApplicationPath]
        if config.forBuild.noCache {
            opts.insert("--no-cache", at: 1)
        }
        let buildResult = Proc("/usr/local/bin/docker", opts)
        if buildResult.terminationStatus != 0 {
            throw SwiftBuilderError.swiftBuildFailed
        }
        
        let sharedDir = "\(hexavilleApplicationPath)/__docker_shared"
        
        _ = Proc("/bin/mkdir", ["-p", sharedDir])
        
        _ = try Spawn(args: ["/usr/local/bin/docker", "run", "-v", "\(sharedDir):/hexaville-app/.build", "-it", tag]) {
            print($0, separator: "", terminator: "")
        }
        
        return BuildResult(destination: sharedDir+"/debug", dockerTag: tag)
    }
}
