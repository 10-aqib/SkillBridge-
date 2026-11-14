import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/config/theme/sb/sb_tokens.dart';

/// Form field with a persistent label above the input (never placeholder-only),
/// optional helper text, and error text that replaces the helper.
class SbTextField extends StatelessWidget {
  const SbTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.requiredMarker,
    this.optionalLabel,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.prefixText,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final String label;
  final TextEditingController? controller;

  /// Example of expected input, e.g. "0300 1234567". Not a substitute for the label.
  final String? hint;
  final String? helper;

  /// Short marker for required fields (e.g. "*" with semantics), localized.
  final String? requiredMarker;

  /// Shown after the label for optional fields, e.g. "(optional)".
  final String? optionalLabel;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;

  /// Fixed prefix such as "+92" or "Rs".
  final String? prefixText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  /// When validation runs. Defaults to after the user interacts with the field.
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.sb;
    // MergeSemantics: the visible label and the input are read as one field.
    return MergeSemantics(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
        Text.rich(
            TextSpan(children: [
              TextSpan(text: label),
              if (requiredMarker != null)
                TextSpan(text: ' $requiredMarker', style: TextStyle(color: c.error)),
              if (optionalLabel != null)
                TextSpan(text: ' $optionalLabel', style: t.bodySmall),
            ]),
            style: t.labelLarge!.copyWith(color: c.text),
        ),
        const SizedBox(height: SbSpace.s2),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          style: t.bodyLarge,
          autovalidateMode: autovalidateMode,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            prefixText: prefixText == null ? null : '$prefixText ',
            suffixIcon: suffix,
          ),
        ),
      ],
      ),
    );
  }
}
