import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final bool isPassword;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;
  final bool? autoFocus;
  final bool? border;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;

  const AppTextFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.autoFocus = false,
    this.border,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.focusNode,
  });

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autoFocus!,
      textAlign: TextAlign.start,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,

      decoration: InputDecoration(
        hintText: widget.hint,
        labelText: widget.label,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.grey,
            width: widget.borderWidth ?? 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.grey,
            width: widget.borderWidth ?? 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.grey,
            width: widget.borderWidth ?? 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.grey,
            width: widget.borderWidth ?? 1,
          ),
        ),
      ),
    );
  }
}
