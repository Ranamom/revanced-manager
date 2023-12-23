import 'package:flutter/foundation.dart';
import 'package:root/root.dart';

class RootAPI {
  // TODO(aAbed): remove in the future, keep it for now during migration.
  final String _postFsDataDirPath = '/data/adb/post-fs-data.d';

  final String _revancedDirPath = '/data/adb/revanced';
  final String _serviceDDirPath = '/data/adb/service.d';

  Future<bool> isRooted() async {
    try {
      final bool? isRooted = await Root.isRootAvailable();
      return isRooted != null && isRooted;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<bool> hasRootPermissions() async {
    try {
      bool? isRooted = await Root.isRootAvailable();
      if (isRooted != null && isRooted) {
        isRooted = await Root.isRooted();
        return isRooted != null && isRooted;
      }
      return false;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<void> setPermissions(
    String permissions,
    ownerGroup,
    seLinux,
    String filePath,
  ) async {
    try {
      if (permissions.isNotEmpty) {
        await Root.exec(
          cmd: 'chmod $permissions "$filePath"',
        );
      }
      if (ownerGroup.isNotEmpty) {
        await Root.exec(
          cmd: 'chown $ownerGroup "$filePath"',
        );
      }
      if (seLinux.isNotEmpty) {
        await Root.exec(
          cmd: 'chcon $seLinux "$filePath"',
        );
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    if (packageName.isNotEmpty) {
      return fileExists('$_serviceDDirPath/$packageName.sh');
    }
    return false;
  }

  Future<List<String>> getInstalledApps() async {
    final List<String> apps = List.empty(growable: true);
    try {
      final String? res = await Root.exec(
        cmd: 'ls "$_revancedDirPath"',
      );
      if (res != null) {
        final List<String> list = res.split('\n');
        list.removeWhere((pack) => pack.isEmpty);
        apps.addAll(list.map((pack) => pack.trim()).toList());
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return apps;
  }

  Future<void> unmount(String packageName) async {
    await Root.exec(
      cmd:
          'grep $packageName /proc/mounts | while read -r line; do echo \$line | cut -d " " -f 2 | sed "s/apk.*/apk/" | xargs -r umount -l; done',
    );
    await Root.exec(
      cmd: 'rm -rf "$_revancedDirPath/$packageName"',
    );
    await Root.exec(
      cmd: 'rm -rf "$_serviceDDirPath/$packageName.sh"',
    );
  }

  // TODO(aAbed): remove in the future, keep it for now during migration.
  Future<void> removeOrphanedFiles() async {
    await Root.exec(
      cmd: '''
      find "$_revancedDirPath" -type f -name original.apk -delete
      for file in "$_serviceDDirPath"/*; do
        filename=\$(basename "\$file")
        if [ -f "$_postFsDataDirPath/\$filename" ]; then
          rm "$_postFsDataDirPath/\$filename"
        fi
      done
      '''
          .trim(),
    );
  }

  Future<bool> installApp(
    String packageName,
    String originalFilePath,
    String patchedFilePath,
  ) async {
    try {
      await Root.exec(
        cmd: 'mkdir -p "$_revancedDirPath/$packageName"',
      );
      await setPermissions(
        '0755',
        'shell:shell',
        '',
        '$_revancedDirPath/$packageName',
      );
      await installServiceDScript(packageName);
      await installApk(packageName, patchedFilePath);
      await mountApk(packageName);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  Future<void> installServiceDScript(String packageName) async {
    await Root.exec(
      cmd: 'mkdir -p "$_serviceDDirPath"',
    );
    final String mountScript = '''
    #!/system/bin/sh
    MAGISKTMP="\$(magisk --path)" || MAGISKTMP=/sbin
    MIRROR="\$MAGISKTMP/.magisk/mirror"

    until [ "\$(getprop sys.boot_completed)" = 1 ]; do sleep 3; done
    until [ -d "/sdcard/Android" ]; do sleep 1; done
    
    base_path=$_revancedDirPath/$packageName/base.apk
    stock_path=\$(pm path $packageName | grep base | sed "s/package://g" )

    chcon u:object_r:apk_data_file:s0  \$base_path
    mount -o bind \$MIRROR\$base_path \$stock_path

    # Kill the app to force it to restart the mounted APK in case it is already running
    am force-stop $packageName
    '''
        .trimMultilineString();
    final String scriptFilePath = '$_serviceDDirPath/$packageName.sh';
    await Root.exec(
      cmd: 'echo \'$mountScript\' > "$scriptFilePath"',
    );
    await setPermissions('0744', '', '', scriptFilePath);
  }

  Future<void> installApk(String packageName, String patchedFilePath) async {
    final String newPatchedFilePath = '$_revancedDirPath/$packageName/base.apk';
    await Root.exec(
      cmd: 'cp "$patchedFilePath" "$newPatchedFilePath"',
    );
    await setPermissions(
      '0644',
      'system:system',
      'u:object_r:apk_data_file:s0',
      newPatchedFilePath,
    );
  }

  Future<void> mountApk(
    String packageName,
  ) async {
    await Root.exec(
      cmd: '''
      grep $packageName /proc/mounts | while read -r line; do echo \$line | cut -d " " -f 2 | sed "s/apk.*/apk/" | xargs -r umount -l; done
      .$_serviceDDirPath/$packageName.sh
      '''
          .trim(),
    );
  }

  Future<bool> fileExists(String path) async {
    try {
      final String? res = await Root.exec(
        cmd: 'ls $path',
      );
      return res != null && res.isNotEmpty;
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }
}

// Remove leading spaces manually until
// https://github.com/dart-lang/language/issues/559 is closed
extension StringExtension on String {
  String trimMultilineString() =>
      split('\n').map((line) => line.trim()).join('\n').trim();
}
