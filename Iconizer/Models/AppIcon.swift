//
// AppIcon.swift
// Iconizer
// https://github.com/raphaelhanneken/iconizer
//

import Cocoa

/// Creates and saves an App Icon asset catalog.
class AppIcon: NSObject {

    /// The resized images.
    var images: [String: [String: NSImage?]] = [:]

    /// Generate the necessary images for the selected platforms.
    ///
    /// - Parameters:
    ///   - platforms: The platforms to generate icon for.
    ///   - image: The image to generate the icon from.
    /// - Throws: See AppIconError for possible values.
    func generateImagesForPlatforms(_ platforms: [String], fromImage image: NSImage) throws {
        // Loop through the selected platforms
        for platform in platforms {
            // Temporary dict to hold the generated images.
            var tmpImages: [String: NSImage?] = [:]

            // Create a new JSON object for the current platform.
            let jsonData = try ContentsJSON(forType: AssetType.appIcon, andPlatforms: [platform])

            for imageData in jsonData.images {
                // Get the expected size, since App Icons are quadratic we only need one value.
                guard let size = imageData["expected-size"] else {
                    throw AppIconError.missingDataForImageSize
                }
                // Get the filename.
                guard let filename = imageData["filename"] else {
                    throw AppIconError.missingDataForImageName
                }

                if let size = Int(size) {
                    // Append the generated image to the temporary images dict.
                    tmpImages[filename] = image.resize(withSize: NSSize(width: size, height: size))
                } else {
                    throw AppIconError.formatError
                }
            }

            // Write back the images to self.images
            images[platform] = tmpImages
        }
    }

    /// Writes the App Icon to the supplied file url.
    ///
    /// - Parameters:
    ///   - name: The name of the asset catalog.
    ///   - url: The URL to save the catalog to.
    ///   - combined: Whether to save the assets combined.
    /// - Throws: See AppIconError for possible values.
    func saveAssetCatalogNamed(_ name: String, toURL url: URL, asCombinedAsset combined: Bool) throws {
        // Define where to save the asset catalog.
        var setURL = url.appendingPathComponent("\(appIconDir)/Combined/\(name).appiconset",
                                                isDirectory: true)

        // Loop through the selected platforms.
        for (platform, images) in images {
            // Override the setURL in case we don't generate a combined asset.
            if !combined {
                setURL = url.appendingPathComponent("\(appIconDir)/\(platform)/\(name).appiconset",
                                                    isDirectory: true)

                // Create the necessary folders.
                try FileManager.default.createDirectory(at: setURL,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)

                // Get the Contents.json for the current platform...
                var jsonFile = try ContentsJSON(forType: AssetType.appIcon, andPlatforms: [platform])
                // ...and save it to the given file url.
                try jsonFile.saveToURL(setURL)
            } else {
                // Create the necessary folders for a combined asset catalog.
                try FileManager.default.createDirectory(at: setURL,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)

                // Get the Contents.json for all selected platforms...
                var jsonFile = try ContentsJSON(forType: AssetType.appIcon,
                                                andPlatforms: Array(self.images.keys))

                // ...and save it to the given file url.
                try jsonFile.saveToURL(setURL)
            }

            // Get each image object + filename.
            for (filename, image) in images {
                // Append the filename to the appiconset url.
                let fileURL = setURL.appendingPathComponent(filename, isDirectory: false)

                // Unwrap the image object.
                guard let img = image else {
                    throw AppIconError.missingImage
                }
                try img.savePngTo(url: fileURL)
            }
        }

        // Reset the images array
        images = [:]
    }
}
