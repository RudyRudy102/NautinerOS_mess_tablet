import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoStartupService {
  static const MethodChannel _channel = MethodChannel('auto_startup');
  
  static Future<void> initialize() async {
    try {
      // Sprawdź czy auto-startup jest włączony i uruchom aplikację w trybie kiosk jeśli tak
      final prefs = await SharedPreferences.getInstance();
      final isAutoStartupEnabled = prefs.getBool('auto_startup_enabled') ?? false;
      final isKioskModeEnabled = prefs.getBool('kiosk_mode_enabled') ?? true;
      
      if (isAutoStartupEnabled && isKioskModeEnabled) {
        // Ukryj pasek stanu i nawigacji
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (e) {
      print('Error initializing auto-startup: $e');
    }
  }
  
  static Future<bool> enableAutoStartup() async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod('enableAutoStartup') ?? false;
      } else if (Platform.isLinux) {
        return await _enableLinuxAutoStartup();
      } else if (Platform.isWindows) {
        return await _enableWindowsAutoStartup();
      }
    } catch (e) {
      print('Error enabling auto-startup: $e');
    }
    return false;
  }
  
  static Future<bool> disableAutoStartup() async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod('disableAutoStartup') ?? false;
      } else if (Platform.isLinux) {
        return await _disableLinuxAutoStartup();
      } else if (Platform.isWindows) {
        return await _disableWindowsAutoStartup();
      }
    } catch (e) {
      print('Error disabling auto-startup: $e');
    }
    return false;
  }
  
  static Future<bool> _enableLinuxAutoStartup() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return false;
      
      final autostartDir = Directory('$homeDir/.config/autostart');
      if (!await autostartDir.exists()) {
        await autostartDir.create(recursive: true);
      }
      
      final desktopFile = File('${autostartDir.path}/yachtos_mess.desktop');
      final executablePath = Platform.resolvedExecutable;
      
      final desktopContent = '''[Desktop Entry]
Type=Application
Name=YachtOS Mess
Exec=$executablePath
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
''';
      
      await desktopFile.writeAsString(desktopContent);
      return true;
    } catch (e) {
      print('Error creating Linux autostart file: $e');
      return false;
    }
  }
  
  static Future<bool> _disableLinuxAutoStartup() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) return false;
      
      final desktopFile = File('$homeDir/.config/autostart/yachtos_mess.desktop');
      if (await desktopFile.exists()) {
        await desktopFile.delete();
      }
      return true;
    } catch (e) {
      print('Error removing Linux autostart file: $e');
      return false;
    }
  }
  
  static Future<bool> _enableWindowsAutoStartup() async {
    try {
      final executablePath = Platform.resolvedExecutable.replaceAll('/', '\\');
      final result = await Process.run('reg', [
        'add',
        'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'YachtOS Mess',
        '/t',
        'REG_SZ',
        '/d',
        executablePath,
        '/f'
      ]);
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error adding Windows registry entry: $e');
      return false;
    }
  }
  
  static Future<bool> _disableWindowsAutoStartup() async {
    try {
      final result = await Process.run('reg', [
        'delete',
        'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'YachtOS Mess',
        '/f'
      ]);
      
      return result.exitCode == 0;
    } catch (e) {
      print('Error removing Windows registry entry: $e');
      return false;
    }
  }
}
