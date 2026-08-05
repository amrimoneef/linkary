import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isNumber;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool isEnabled;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isNumber = false,
    this.isEnabled = true,
    this.validator,
    this.suffixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade300),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade500),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
