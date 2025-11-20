import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth.dart';
import '../database/database_service.dart';

class ReportProductDialog extends StatefulWidget {
  final int productId;
  final String productTitle;

  const ReportProductDialog({
    super.key,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ReportProductDialog> createState() => _ReportProductDialogState();
}

class _ReportProductDialogState extends State<ReportProductDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  final _descriptionCtrl = TextEditingController();
  bool _loading = false;

  final List<String> _reasons = [
    'spam',
    'fake',
    'inappropriate',
    'other',
  ];

  final Map<String, String> _reasonLabels = {
    'spam': 'Spam / Quảng cáo',
    'fake': 'Hàng giả / Lừa đảo',
    'inappropriate': 'Nội dung không phù hợp',
    'other': 'Khác',
  };

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lý do báo cáo'), backgroundColor: Colors.orange),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập'), backgroundColor: Colors.orange),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _loading = true);

    final dbService = DatabaseService.instance;
    final result = await dbService.reportProduct(
      productId: widget.productId,
      reporterId: authProvider.userId!,
      reason: _selectedReason!,
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo thành công. Cảm ơn bạn đã báo cáo!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Lỗi khi gửi báo cáo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Báo cáo sản phẩm',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.productTitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'Lý do báo cáo *',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(_reasonLabels[reason] ?? reason),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
                validator: (v) => v == null ? 'Vui lòng chọn lý do' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết (tùy chọn)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Mô tả thêm về vấn đề...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Gửi báo cáo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

