import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../screens/camera_screen.dart';

class CameraService {
  static final CameraService instance = CameraService._init();
  CameraService._init();

  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    try {
      final PermissionStatus status = await Permission.camera.request();
      
      if (status.isGranted) {
        _cameras = await availableCameras();
        print('✅ CameraService: ${_cameras?.length ?? 0} câmera(s) encontrada(s)');
      } else {
        print('❌ Permissão da câmera negada');
        _cameras = [];
      }
    } catch (e) {
      print('⚠️ Erro ao inicializar câmera: $e');
      _cameras = [];
    }
  }

  bool get hasCameras => _cameras != null && _cameras!.isNotEmpty;

  Future<String?> takePicture(BuildContext context) async {
    if (!hasCameras) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Nenhuma câmera disponível'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permissão da câmera necessária'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final CameraDescription camera = _cameras!.first;
    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    try {
      await controller.initialize();

      if (!context.mounted) return null;
      
      final String? imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(controller: controller),
          fullscreenDialog: true,
        ),
      );

      return imagePath;
    } catch (e) {
      print('❌ Erro ao abrir câmera: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir câmera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<String> savePicture(XFile image) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'task_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savePath = path.join(appDir.path, 'images', fileName);
      
      final Directory imageDir = Directory(path.join(appDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final File savedImage = await File(image.path).copy(savePath);
      print('✅ Foto salva: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      print('❌ Erro ao salvar foto: $e');
      rethrow;
    }
  }

  Future<bool> deletePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return true;
    
    try {
      final File file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao deletar foto: $e');
      return false;
    }
  }
}