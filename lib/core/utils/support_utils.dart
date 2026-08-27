import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

class SupportUtils {
  static void showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For Complaints and Queries',
                style: AppTextStyles.heading2.copyWith(color: context.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email, color: AppColors.primary),
                ),
                title: Text('Email', style: AppTextStyles.titleSmall.copyWith(color: context.textColor)),
                subtitle: Text('aqibk1051@gmail.com', style: AppTextStyles.bodyMedium.copyWith(color: context.mutedColor)),
                onTap: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'aqibk1051@gmail.com',
                  );
                  launchUrl(emailLaunchUri);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.message, color: Colors.green),
                ),
                title: Text('WhatsApp', style: AppTextStyles.titleSmall.copyWith(color: context.textColor)),
                subtitle: Text('+923255944262', style: AppTextStyles.bodyMedium.copyWith(color: context.mutedColor)),
                onTap: () async {
                  final Uri whatsappUri = Uri.parse('whatsapp://send?phone=+923255944262');
                  launchUrl(whatsappUri);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
