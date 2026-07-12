import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    List<Permission> permissions = [];

    // Camera
    permissions.add(Permission.camera);

    // Storage / Media
    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        permissions.add(Permission.photos); // READ_MEDIA_IMAGES
        permissions.add(Permission.videos); // READ_MEDIA_VIDEO
      } else {
        permissions.add(Permission.storage); // READ_EXTERNAL_STORAGE
      }
    }

    // Notification (Android 13+)
    if (Platform.isAndroid && await _isAndroid13OrAbove()) {
      permissions.add(Permission.notification);
    }

    // Request tất cả
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Debug log (optional)
    statuses.forEach((permission, status) {
      print("$permission: $status");
    });

    // Nếu bị từ chối vĩnh viễn
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      openAppSettings();
    }
  }

  static Future<bool> _isAndroid13OrAbove() async {
    return Platform.isAndroid && (await Permission.photos.status) != null;
  }
}