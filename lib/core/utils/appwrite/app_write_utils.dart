// import 'dart:io';

// import 'package:appwrite/appwrite.dart';
// import 'package:chat_kare/core/constants/apprite/app_write_config.dart';
// import 'package:logger/logger.dart';

// /// Utility class for handling Appwrite storage operations.
// ///
// /// This class provides a centralized way to interact with Appwrite's Storage
// /// service for uploading files (documents, images, etc.) and generating
// /// public view URLs for accessing uploaded files.
// ///
// /// Features:
// /// - File upload to Appwrite Storage bucket
// /// - Automatic file ID generation
// /// - View URL generation for file access
// /// - Error handling and logging
// ///
// /// Usage:
// /// ```dart
// /// final appWriteUtils = AppWriteUtils();
// /// final fileUrl = await appWriteUtils.uploadDocument(File('/path/to/file.pdf'));
// /// ```
// class AppWriteUtils {
//   /// Logger instance for tracking upload operations and errors.
//   final log = Logger();

//   /// Shared Appwrite client instance configured with endpoint and project ID.
//   ///
//   /// This client is static to avoid recreating it multiple times, improving
//   /// performance and resource usage. Configuration values are loaded from
//   /// [AppWriteConfig].
//   static final Client client = Client()
//     ..setEndpoint(AppWriteConfig.appwritePublicEndpoint)
//     ..setProject(AppWriteConfig.appwriteProjectId);

//   /// Appwrite Storage service instance initialized with the shared client.
//   ///
//   /// Used to perform file operations like createFile, listFiles, etc.
//   static final Storage storage = Storage(client);

//   /// Uploads a document file (PDF, DOC, TXT, etc.) to Appwrite Storage.
//   ///
//   /// This method:
//   /// 1. Takes a [File] object representing the local file to upload.
//   /// 2. Generates a unique file ID using [ID.unique()].
//   /// 3. Converts the local file to Appwrite's [InputFile] format.
//   /// 4. Uploads to the configured bucket via [storage.createFile].
//   /// 5. Logs success or error using the logger.
//   /// 6. Returns a publicly accessible view URL if successful, otherwise an empty string.
//   ///
//   /// The returned URL can be used to display or download the file.
//   ///
//   /// Parameters:
//   /// - [file]: The local file to upload. Must exist and be readable.
//   ///
//   /// Returns:
//   /// - A `String` containing the view URL of the uploaded file, or an empty string
//   ///   if the upload fails.
//   ///
//   /// Example:
//   /// ```dart
//   /// final file = File('/storage/emulated/0/Download/report.pdf');
//   /// final url = await appWriteUtils.uploadDocument(file);
//   /// if (url.isNotEmpty) {
//   ///   print('File available at: $url');
//   /// }
//   /// ```
//   Future<String> uploadDocument(File file) async {
//     try {
//       // Perform the upload operation with Appwrite Storage
//       final response = await storage.createFile(
//         bucketId: AppWriteConfig.bucketId,
//         fileId: ID.unique(), // Auto-generate a unique file identifier
//         file: InputFile.fromPath(path: file.path),
//       );

//       log.i('File uploaded successfully. File ID: ${response.$id}');
//       return _getFileViewUrl(response.$id);
//     } catch (e) {
//       log.e('Failed to upload document. Error: $e');
//       return ''; // Return empty string to indicate failure
//     }
//   }

//   /// Generates a public view URL for a file stored in Appwrite.
//   ///
//   /// The URL follows Appwrite's storage view endpoint format and includes
//   /// the project ID and admin mode parameter for unrestricted access.
//   /// This URL can be used in web views, image widgets, or shared links.
//   ///
//   /// Parameters:
//   /// - [fileId]: The unique identifier of the file in Appwrite storage.
//   ///
//   /// Returns:
//   /// - A `String` containing the full URL to view/download the file.
//   ///
//   /// Example:
//   /// ```dart
//   /// final viewUrl = _getFileViewUrl('unique-file-id-123');
//   /// // Result: https://your-appwrite-endpoint/v1/storage/buckets/bucketId/files/unique-file-id-123/view?project=projectId&mode=admin
//   /// ```
//   String _getFileViewUrl(String fileId) {
//     return '${AppWriteConfig.appwritePublicEndpoint}/storage/buckets/${AppWriteConfig.bucketId}/files/$fileId/view?project=${AppWriteConfig.appwriteProjectId}&mode=admin';
//   }
// }
