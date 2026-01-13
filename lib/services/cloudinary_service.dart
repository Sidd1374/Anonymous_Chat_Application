import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Minimal Cloudinary helper for signed uploads from Flutter.
/// Your backend must return a signature and timestamp; keep the API secret server-side.
class CloudinaryService {
  CloudinaryService({
    required this.cloudName,
    required this.signatureEndpoint,
  });

  final String cloudName; // Cloudinary cloud name (public)
  final String signatureEndpoint; // HTTPS endpoint that returns {signature, timestamp, apiKey}

  Uri get _uploadUri => Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Fetch signed params from your backend.
  Future<CloudinarySignature> fetchSignature() async {
    final res = await http.get(Uri.parse(signatureEndpoint));
    if (res.statusCode != 200) {
      throw Exception('Cloudinary signature fetch failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CloudinarySignature(
      signature: data['signature'] as String,
      timestamp: data['timestamp'] as int,
      apiKey: data['apiKey'] as String,
      folder: data['folder'] as String?,
    );
  }

  /// Upload a local file path. Returns upload metadata including secure URL and publicId.
  Future<CloudinaryUploadResult> uploadFile({
    required CloudinarySignature sig,
    required String filePath,
    String? uploadPreset,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final req = http.MultipartRequest('POST', _uploadUri)
      ..fields.addAll(_fields(sig, uploadPreset: uploadPreset))
      ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.statusCode} ${res.body}');
    }
    return _parseUploadResult(res.body);
  }

  /// Upload raw bytes. Returns upload metadata including secure URL and publicId.
  Future<CloudinaryUploadResult> uploadBytes({
    required CloudinarySignature sig,
    required Uint8List bytes,
    required String fileName,
    String? uploadPreset,
  }) async {
    final req = http.MultipartRequest('POST', _uploadUri)
      ..fields.addAll(_fields(sig, uploadPreset: uploadPreset))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.statusCode} ${res.body}');
    }
    return _parseUploadResult(res.body);
  }

  /// Unsigned upload (no server signer). Use only with a locked-down unsigned preset.
  Future<CloudinaryUploadResult> uploadFileUnsigned({
    required String filePath,
    String? uploadPreset,
    String? folder,
    String? publicId,
  }) async {
    final preset = uploadPreset ?? CloudinaryConfig.uploadPreset;
    if (preset.isEmpty) {
      throw Exception('uploadPreset is required for unsigned uploads');
    }
    final fileName = filePath.split(Platform.pathSeparator).last;
    final req = http.MultipartRequest('POST', _uploadUri)
      ..fields.addAll(_unsignedFields(preset, folder: folder, publicId: publicId))
      ..files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary unsigned upload failed: ${res.statusCode} ${res.body}');
    }
    return _parseUploadResult(res.body);
  }

  /// Unsigned upload (no server signer) for raw bytes.
  Future<CloudinaryUploadResult> uploadBytesUnsigned({
    required Uint8List bytes,
    required String fileName,
    String? uploadPreset,
    String? folder,
    String? publicId,
  }) async {
    final preset = uploadPreset ?? CloudinaryConfig.uploadPreset;
    if (preset.isEmpty) {
      throw Exception('uploadPreset is required for unsigned uploads');
    }
    final req = http.MultipartRequest('POST', _uploadUri)
      ..fields.addAll(_unsignedFields(preset, folder: folder, publicId: publicId))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      throw Exception('Cloudinary unsigned upload failed: ${res.statusCode} ${res.body}');
    }
    return _parseUploadResult(res.body);
  }

  /// Convenience: fetch signature then upload a file path.
  Future<CloudinaryUploadResult> uploadFileWithSignature({
    required String filePath,
    String? uploadPreset,
  }) async {
    final sig = await fetchSignature();
    return uploadFile(
      sig: sig,
      filePath: filePath,
      uploadPreset: uploadPreset ?? CloudinaryConfig.uploadPreset,
    );
  }

  /// Convenience: fetch signature then upload raw bytes.
  Future<CloudinaryUploadResult> uploadBytesWithSignature({
    required Uint8List bytes,
    required String fileName,
    String? uploadPreset,
  }) async {
    final sig = await fetchSignature();
    return uploadBytes(
      sig: sig,
      bytes: bytes,
      fileName: fileName,
      uploadPreset: uploadPreset ?? CloudinaryConfig.uploadPreset,
    );
  }

  /// Build a transformed image URL for delivery (e.g., thumbnail).
  String imageUrl({
    required String publicId,
    int? width,
    int? height,
    int quality = 80,
    bool autoFormat = true,
  }) {
    final transforms = <String>[];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    if (autoFormat) transforms.add('f_auto');
    if (quality > 0) transforms.add('q_$quality');

    final tx = transforms.isNotEmpty ? '${transforms.join(',')}/' : '';
    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$tx$publicId';
  }

  CloudinaryUploadResult _parseUploadResult(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return CloudinaryUploadResult(
      secureUrl: data['secure_url'] as String,
      publicId: data['public_id'] as String,
      resourceType: data['resource_type'] as String? ?? 'image',
      bytes: (data['bytes'] as num?)?.toInt(),
      format: data['format'] as String?,
    );
  }

  Map<String, String> _fields(CloudinarySignature sig, {String? uploadPreset}) {
    final fields = <String, String>{
      'api_key': sig.apiKey,
      'timestamp': sig.timestamp.toString(),
      'signature': sig.signature,
    };
    if (sig.folder != null && sig.folder!.isNotEmpty) {
      fields['folder'] = sig.folder!;
    }
    if (uploadPreset != null && uploadPreset.isNotEmpty) {
      fields['upload_preset'] = uploadPreset;
    }
    return fields;
  }

  Map<String, String> _unsignedFields(String uploadPreset, {String? folder, String? publicId}) {
    final fields = <String, String>{
      'upload_preset': uploadPreset,
    };
    if (folder != null && folder.isNotEmpty) {
      fields['folder'] = folder;
    }
    if (publicId != null && publicId.isNotEmpty) {
      fields['public_id'] = publicId;
    }
    return fields;
  }
}

class CloudinarySignature {
  CloudinarySignature({
    required this.signature,
    required this.timestamp,
    required this.apiKey,
    this.folder,
  });

  final String signature; // Generated server-side using API secret
  final int timestamp; // Unix epoch seconds
  final String apiKey; // Cloudinary API key (safe for client)
  final String? folder; // Optional default folder set by backend
}

class CloudinaryUploadResult {
  CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    this.bytes,
    this.format,
  });

  final String secureUrl; // CDN URL to use in messages
  final String publicId; // Store for future transforms/deletes
  final String resourceType; // image, video, raw
  final int? bytes;
  final String? format;
}

class CloudinaryConfig {
  static const cloudName = 'dpcxkqv3z';
  // HTTPS endpoint you host that returns JSON: {signature, timestamp, apiKey, folder?}
  static const signatureEndpoint = '';
  // Required for unsigned uploads (set this to your unsigned preset name).
  static const uploadPreset = 'profile_upload';
}

final cloudinary = CloudinaryService(
  cloudName: CloudinaryConfig.cloudName,
  signatureEndpoint: CloudinaryConfig.signatureEndpoint,
);
