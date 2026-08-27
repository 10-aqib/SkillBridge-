import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  int updatedFiles = 0;
  
  for (final file in files) {
    if (file.path.contains('app_colors.dart') || 
        file.path.contains('app_theme.dart') || 
        file.path.contains('context_extensions.dart')) {
      continue;
    }
    
    String content = file.readAsStringSync();
    bool modified = false;
    
    if (content.contains('AppColors.onSurfaceVariant')) {
      content = content.replaceAll('AppColors.onSurfaceVariant', 'context.mutedColor');
      modified = true;
    }
    if (content.contains('AppColors.onSurface')) {
      content = content.replaceAll('AppColors.onSurface', 'context.textColor');
      modified = true;
    }
    if (content.contains('AppColors.surfaceWhite')) {
      content = content.replaceAll('AppColors.surfaceWhite', 'context.surfaceColor');
      modified = true;
    }
    if (content.contains('AppColors.backgroundGray')) {
      content = content.replaceAll('AppColors.backgroundGray', 'context.scaffoldBg');
      modified = true;
    }
    if (content.contains('AppColors.outlineVariant')) {
      content = content.replaceAll('AppColors.outlineVariant', 'context.borderColor');
      modified = true;
    }
    
    if (modified) {
      if (!content.contains('context_extensions.dart')) {
        // Insert import after the last import statement or at the top
        final lines = content.split('\n');
        int lastImportIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lastImportIndex = i;
          }
        }
        
        final importStmt = "import 'package:skill_bridge/core/extensions/context_extensions.dart';";
        if (lastImportIndex != -1) {
          lines.insert(lastImportIndex + 1, importStmt);
        } else {
          lines.insert(0, importStmt);
        }
        content = lines.join('\n');
      }
      
      file.writeAsStringSync(content);
      updatedFiles++;
      print('Updated \${file.path}');
    }
  }
  
  print('Total files updated: \$updatedFiles');
}
