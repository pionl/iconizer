//
// JSONFile.swift
// Iconizer
// https://github.com/raphaelhanneken/iconizer
//

import Cocoa

/// Reads and writes the Contents.json files.
struct ContentsJSON {

    /// The image information from <AssetType>.json
    var images: [[String: String]]

    /// The Contents.json file as array.
    var contents: [String: Any] = [:]

    // MARK: Initializers

    /// Initialize a new ContentsJSON instance.
    init() {
        // Init the images array.
        images = []

        // Init the contents array, with general information.
        contents["author"] = "Iconizer"
        contents["version"] = "1.0"
        contents["images"] = []
    }

    /// Initialize a new ContentsJSON instance with a specified Asset Type
    /// and selected platforms.
    ///
    /// - Parameters:
    ///   - type: The asset type to get the JSON data for.
    ///   - platforms: The platforms selected by the user.
    /// - Throws: See ContentsJSONError for possible values.
    init(forType type: AssetType, andPlatforms platforms: [String]) throws {
        // Basic initialization.
        self.init()

        // Initialize the data object.
        for platform in platforms {
            // Add the image information for each platform to our images array.
            images += try JSONObjectForType(type, andPlatform: platform)
        }
    }

    // MARK: Methods

    /// Get the asset information for the supplied Asset Type.
    ///
    /// - Parameters:
    ///   - type: The asset type to get the information for.
    ///   - platform: The platforms selected by the user.
    /// - Returns: The Contents.json for the supplied asset type and platforms as Array.
    /// - Throws: See ContentsJSONError for possible values.
    func JSONObjectForType(_ type: AssetType, andPlatform platform: String) throws -> [[String: String]] {
        guard let resourcePath = resourcePath(forAssetType: type, andPlatform: platform) else {
            throw ContentsJSONError.fileNotFound
        }
        // Create a new JSON object from the given data.
        let json = try JSONSerialization
            .jsonObject(with: try Data(contentsOf: URL(fileURLWithPath: resourcePath), options: .alwaysMapped),
                        options: .allowFragments)

        // Convert the JSON object into a Dictionary.
        guard let contents = json as? [String: AnyObject] else {
            throw ContentsJSONError.castingJSONToDictionaryFailed
        }
        // Get the image information from the JSON dictionary.
        guard let images = contents["images"] as? [[String: String]] else {
            throw ContentsJSONError.gettingImagesArrayFailed
        }

        // Return the image information.
        return images
    }


    func resourcePath(forAssetType type: AssetType, andPlatform platform: String) -> String? {
        let resource: String
        switch type {
        case .appIcon:
            resource = "AppIcon_" + platform
        case .imageSet:
            resource = "ImageSet"
        case .launchImage:
            resource = "LaunchImage_" + platform
        }
        return Bundle.main.path(forResource: resource, ofType: "json")
    }

    ///  Saves the Contents.json to the appropriate folder.
    ///
    ///  - parameter url: File url to save the Contents.json to.
    ///  - throws: An exception when the JSON serialization fails.
    /// Save the Contents.json to the supplied file URL.
    ///
    /// - Parameter url: The file URL to save the Contents.json to.
    /// - Throws: See JSONSerialization for possible values.
    mutating func saveToURL(_ url: URL) throws {
        // Add the image information to the contents dictionary.
        contents["images"] = images
        // Serialize the contents as JSON object.
        let data = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
        // Write the JSON object to the HD.
        try data.write(to: url.appendingPathComponent("Contents.json", isDirectory: false), options: .atomic)
    }
}
