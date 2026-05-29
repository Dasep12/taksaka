import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/file_picker_widget.dart';
import '../../domain/request_models.dart';
import '../../data/request_service.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String _permissionType = 'Sakit';
  final List<String> _permissionTypes = ['Sakit', 'Izin Keperluan Keluarga', 'Izin Dinas Luar', 'Lainnya'];
  
  final _descCtrl = TextEditingController();
  List<PlatformFile> _attachedFiles = [];
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal izin terlebih dahulu')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final req = PermissionRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        permissionType: _permissionType,
        date: _selectedDate!,
        description: _descCtrl.text,
      );
      
      await RequestService.instance.submitPermissionRequest(req);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan izin berhasil dikirim')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Pengajuan Izin', style: TextStyle(fontSize: 16, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Jenis Izin
            const Text(
              'Jenis Izin',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _permissionType,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: _permissionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _permissionType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Tanggal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDate == null 
                                ? 'Pilih Tanggal' 
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Keterangan
            AppTextField(
              label: 'Keterangan',
              controller: _descCtrl,
              hint: 'Tulis keterangan izin...',
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Lampiran
            const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
            const SizedBox(height: AppSpacing.sm),
            FilePickerWidget(
              files: _attachedFiles,
              onPick: () async {
                final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null) setState(() => _attachedFiles.addAll(result.files));
              },
              onRemove: (i) => setState(() => _attachedFiles.removeAt(i)),
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
            
            AppButton(
              label: 'Kirim Pengajuan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
