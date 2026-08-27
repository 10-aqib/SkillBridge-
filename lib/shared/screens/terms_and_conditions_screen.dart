import 'package:flutter/material.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = AppL10n.select(context, en: 'Terms & Conditions', ur: 'شرائط و ضوابط');
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading3),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: context.textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
              style: AppTextStyles.labelCaption.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              enTitle: '1. Introduction',
              urTitle: '1. تعارف',
              enText: 'Welcome to Skill Bridge. By using our application, you agree to these Terms and Conditions. Please read them carefully.',
              urText: 'سکل برج میں خوش آمدید۔ ہماری ایپ استعمال کر کے، آپ ان شرائط و ضوابط سے اتفاق کرتے ہیں۔ براہ کرم انہیں غور سے پڑھیں۔',
            ),
            _buildSection(
              context,
              enTitle: '2. User Responsibilities',
              urTitle: '2. صارف کی ذمہ داریاں',
              enText: 'You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account. You agree to provide accurate and complete information when registering.',
              urText: 'آپ اپنے اکاؤنٹ کی رازداری برقرار رکھنے اور اپنے اکاؤنٹ کے تحت ہونے والی تمام سرگرمیوں کے ذمہ دار ہیں۔ آپ رجسٹریشن کے وقت درست اور مکمل معلومات فراہم کرنے سے اتفاق کرتے ہیں۔',
            ),
            _buildSection(
              context,
              enTitle: '3. Services & Payments',
              urTitle: '3. خدمات اور ادائیگیاں',
              enText: 'Skill Bridge acts as a marketplace connecting clients with independent workers. We are not responsible for the quality of work provided by independent workers. Payments made through the platform are subject to our payment provider terms.',
              urText: 'سکل برج ایک مارکیٹ پلیس کے طور پر کام کرتا ہے جو کلائنٹس کو آزاد کاریگروں سے جوڑتا ہے۔ ہم کاریگروں کے فراہم کردہ کام کے معیار کے ذمہ دار نہیں ہیں۔ پلیٹ فارم کے ذریعے کی جانے والی ادائیگیاں ہمارے ادائیگی فراہم کنندہ کی شرائط کے تابع ہیں۔',
            ),
            _buildSection(
              context,
              enTitle: '4. Termination',
              urTitle: '4. معطلی',
              enText: 'We reserve the right to suspend or terminate your account at any time if we suspect you have violated these Terms and Conditions.',
              urText: 'اگر ہمیں شبہ ہو کہ آپ نے ان شرائط و ضوابط کی خلاف ورزی کی ہے، تو ہم کسی بھی وقت آپ کا اکاؤنٹ معطل یا ختم کرنے کا حق محفوظ رکھتے ہیں۔',
            ),
            _buildSection(
              context,
              enTitle: '5. Contact Us',
              urTitle: '5. رابطہ کریں',
              enText: 'If you have any questions about these Terms, please contact our support team via the Customer Support option in the settings menu.',
              urText: 'اگر آپ کو ان شرائط کے بارے میں کوئی سوالات ہیں، تو براہ کرم سیٹنگز مینو میں کسٹمر سپورٹ آپشن کے ذریعے ہماری سپورٹ ٹیم سے رابطہ کریں۔',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String enTitle,
    required String urTitle,
    required String enText,
    required String urText,
  }) {
    final title = AppL10n.select(context, en: enTitle, ur: urTitle);
    final text = AppL10n.select(context, en: enText, ur: urText);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
