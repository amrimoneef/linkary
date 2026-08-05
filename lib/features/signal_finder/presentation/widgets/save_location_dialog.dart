import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/entities/signal_rank.dart';

class SaveLocationDialog extends StatefulWidget {
  final double score;
  final SignalRank rank;

  const SaveLocationDialog({
    Key? key,
    required this.score,
    required this.rank,
  }) : super(key: key);

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1E293B) 
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.save, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  'حفظ الموقع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'اسم الموقع (مثال: الصالة، المجلس)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'وصف إضافي (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        Get.snackbar('تنبيه', 'يجب كتابة اسم الموقع');
                        return;
                      }
                      
                      final location = SavedLocation(
                        name: name,
                        description: _descController.text.trim(),
                        score: widget.score,
                        rank: widget.rank,
                      );
                      Get.back(result: location);
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
