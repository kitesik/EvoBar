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
        try discoveryReport(defaultRoots: defaultRoots, additionalPatterns: additionalPatterns,
                            providerID: providerID, homeDirectory: homeDirectory).locations
    }

    public static func discoveryReport(
        defaultRoots: [URL], additionalPatterns: [String], providerID: ProviderID,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) throws -> LogDiscoveryReport {
        var issues = Set<TrackingIssue>()
        var additional: [URL] = []
        for pattern in additionalPatterns {
            try validate(pattern: pattern, homeDirectory: homeDirectory)
            do {
                additional += try expand(pattern: pattern, homeDirectory: homeDirectory)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                issues.insert(TrackingIssue.reading(error))
            }
        }
        var seen = Set<String>()
        var results: [LogLocation] = []
        for candidate in defaultRoots + additional {
            try Task.checkCancellation()
            let values: URLResourceValues
            do {
                values = try candidate.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            } catch {
                if !isMissing(error) { issues.insert(TrackingIssue.reading(error)) }
                continue
            }
            if values.isRegularFile == true, candidate.pathExtension.lowercased() == "jsonl" {
                append(candidate, providerID: providerID, seen: &seen, results: &results)
                continue
            }
            guard values.isDirectory == true else { continue }
            let keys: Set<URLResourceKey> = [.isRegularFileKey]
            guard let enumerator = FileManager.default.enumerator(
                at: candidate,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants],
                errorHandler: { _, error in
                    if !isMissing(error) { issues.insert(TrackingIssue.reading(error)) }
                    return true
                }
            ) else { issues.insert(.discoveryFailed); continue }
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "jsonl" {
                try Task.checkCancellation()
                do {
                    let fileValues = try url.resourceValues(forKeys: keys)
                    guard fileValues.isRegularFile == true else { continue }
                    append(url, providerID: providerID, seen: &seen, results: &results)
                } catch {
                    if !isMissing(error) { issues.insert(TrackingIssue.reading(error)) }
                }
            }
        }
        return LogDiscoveryReport(locations: results.sorted { $0.url.path < $1.url.path }, issues: issues)
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
        do {
            _ = try baseURL.resourceValues(forKeys: [.isDirectoryKey])
        } catch {
            if isMissing(error) { return [] }
            throw error
        }
        let regex = try NSRegularExpression(pattern: try regexPattern(for: expanded))
        var candidates = [baseURL]
        var enumerationError: (any Error)?
        if let enumerator = FileManager.default.enumerator(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: [.skipsPackageDescendants],
            errorHandler: { _, error in enumerationError = error; return false }
        ) {
            for case let url as URL in enumerator {
                try Task.checkCancellation()
                candidates.append(url)
            }
        }
        if let enumerationError { throw enumerationError }
        return candidates.filter { url in
            let path = url.standardizedFileURL.path
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            return regex.firstMatch(in: path, range: range) != nil
        }
    }

    private static func isMissing(_ error: any Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain
            && [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(error.code)
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
