import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CaptchaDialog extends StatefulWidget {
  final String imageUrl;
  final String cookies;
  final Function(String) onSubmit;
  final VoidCallback onRefresh;

  const CaptchaDialog({
    super.key,
    required this.imageUrl,
    required this.cookies,
    required this.onSubmit,
    required this.onRefresh,
  });

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  final TextEditingController _controller = TextEditingController();
  // We append a timestamp to force the image to refresh without caching
  late String _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = '${widget.imageUrl}?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  void _refreshCaptcha() {
    setState(() {
      _currentImageUrl = '${widget.imageUrl}?t=${DateTime.now().millisecondsSinceEpoch}';
    });
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'رمز التحقق',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يرجى إدخال الرمز الموجود في الصورة للاستعلام عن الرصيد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Image container with refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentImageUrl,
                      headers: {'Cookie': widget.cookies},
                      width: 150,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(
                        width: 150,
                        height: 50,
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _refreshCaptcha,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث الصورة',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                labelText: 'الرمز',
                hintText: 'أدخل الرمز هنا',
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  widget.onSubmit(val.trim());
                }
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSubmit(_controller.text.trim());
            }
          },
          child: const Text('متابعة'),
        ),
      ],
    );
  }
}
