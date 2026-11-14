import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_bridge/shared/design_system/sb_text_field.dart';

/// Legacy form field API, rendered by [SbTextField] (persistent label above
/// the input, token borders, merged label semantics). Adds the password
/// visibility toggle this API has always had.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final suffix = widget.isPassword
        ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          )
        : widget.suffixIcon;

    return SbTextField(
      label: widget.labelText,
      controller: widget.controller,
      hint: widget.hintText,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.isPassword && _obscureText,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      prefixIcon: widget.prefixIcon,
      suffix: suffix,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      // Legacy forms validate on submit; keep that behaviour.
      autovalidateMode: AutovalidateMode.disabled,
    );
  }
}
