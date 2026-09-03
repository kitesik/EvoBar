import EvoBarCore
import Foundation

public enum LogPathPatternError: Error, Equatable {
    case empty
    case unsafeWildcardRoot
    case invalidPattern
}

public enum LogPathResolver {
    public static func validate(
        pattern: String,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws {
        _ = try normalizedPattern(pattern, homeDirectory: homeDirectory)
    }

    public static func jsonlLocations(
        defaultRoots: [URL],
        additionalPatterns: [String],
        providerID: ProviderID,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> [LogLocation] {
        let additional = try additionalPatterns.flatMap {
            try expand(pattern: $0, homeDirectory: homeDirectory)
        }
        var seen = Set<String>()
        var results: [LogLocation] = []
        for candidate in defaultRoots + additional {
            let values = try? candidate.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values?.isRegularFile == true, candidate.pathExtension.lowercased() == "jsonl" {
                append(candidate, providerID: providerID, seen: &seen, results: &results)
                continue
            }
            guard values?.isDirectory == true else { continue }
            let keys: Set<URLResourceKey> = [.isRegularFileKey]
            guard let enumerator = FileManager.default.enumerator(
                at: candidate,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants]
            ) else { continue }
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "jsonl" {
                let fileValues = try? url.resourceValues(forKeys: keys)
                guard fileValues?.isRegularFile == true else { continue }
                append(url, providerID: providerID, seen: &seen, results: &results)
            }
        }
        return results.sorted { $0.url.path < $1.url.path }
    }

    public static func expand(
        pattern: String,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> [URL] {
        let expanded = try normalizedPattern(pattern, homeDirectory: homeDirectory)
        guard expanded.contains("*") || expanded.contains("?") else {
            return [URL(fileURLWithPath: expanded).standardizedFileURL]
        }

        let components = expanded.split(separator: "/", omittingEmptySubsequences: false)
        var fixedComponents: [Substring] = []
        for component in components.dropFirst() {
            if component.contains("*") || component.contains("?") { break }
            fixedComponents.append(component)
        }
        let basePath = "/" + fixedComponents.joined(separator: "/")
        let baseURL = URL(fileURLWithPath: basePath, isDirectory: true).standardizedFileURL
        guard FileManager.default.fileExists(atPath: baseURL.path) else { return [] }
        let regex = try NSRegularExpression(pattern: try regexPattern(for: expanded))
        var candidates = [baseURL]
        if let enumerator = FileManager.default.enumerator(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: [.skipsPackageDescendants]
        ) {
            candidates.append(contentsOf: enumerator.compactMap { $0 as? URL })
        }
        return candidates.filter { url in
            let path = url.standardizedFileURL.path
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            return regex.firstMatch(in: path, range: range) != nil
        }
    }

    private static func append(
        _ url: URL,
        providerID: ProviderID,
        seen: inout Set<String>,
        results: inout [LogLocation]
    ) {
        let standardized = url.standardizedFileURL
        guard seen.insert(standardized.path).inserted else { return }
        results.append(LogLocation(url: standardized, providerID: providerID))
    }

    private static func expandTilde(_ path: String, homeDirectory: URL) -> String {
        if path == "~" { return homeDirectory.path }
        if path.hasPrefix("~/") { return homeDirectory.path + String(path.dropFirst()) }
        return path
    }

    private static func normalizedPattern(_ pattern: String, homeDirectory: URL) throws -> String {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LogPathPatternError.empty }
        let expanded = expandTilde(trimmed, homeDirectory: homeDirectory)
        guard expanded.hasPrefix("/") else { throw LogPathPatternError.invalidPattern }
        if expanded.contains("*") || expanded.contains("?") {
            let components = expanded.split(separator: "/", omittingEmptySubsequences: false)
            var fixedComponents: [Substring] = []
            for component in components.dropFirst() {
                if component.contains("*") || component.contains("?") { break }
                fixedComponents.append(component)
            }
            let basePath = "/" + fixedComponents.joined(separator: "/")
            guard basePath != "/" else { throw LogPathPatternError.unsafeWildcardRoot }
        }
        return expanded
    }

    private static func regexPattern(for glob: String) throws -> String {
        var result = "^"
        var index = glob.startIndex
        while index < glob.endIndex {
            let character = glob[index]
            if character == "*" {
                let next = glob.index(after: index)
                if next < glob.endIndex, glob[next] == "*" {
                    let afterDouble = glob.index(after: next)
                    if afterDouble < glob.endIndex, glob[afterDouble] == "/" {
                        result += "(?:.*/)?"
                        index = glob.index(after: afterDouble)
                    } else {
                        result += ".*"
                        index = afterDouble
                    }
                    continue
                }
                result += "[^/]*"
            } else if character == "?" {
                result += "[^/]"
            } else {
                result += NSRegularExpression.escapedPattern(for: String(character))
            }
            index = glob.index(after: index)
        }
        result += "$"
        return result
    }
}
