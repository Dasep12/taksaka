import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/request_models.dart';
import '../../data/request_service.dart';

class OvertimeRequestScreen extends StatefulWidget {
  const OvertimeRequestScreen({super.key});

  @override
  State<OvertimeRequestScreen> createState() => _OvertimeRequestScreenState();
}

class _OvertimeRequestScreenState extends State<OvertimeRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _earlyStart;
  TimeOfDay? _earlyEnd;
  TimeOfDay? _lateStart;
  TimeOfDay? _lateEnd;

  final _totalEarlyCtrl = TextEditingController();
  final _totalLateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
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

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) async {
    return showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lembur terlebih dahulu')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final req = OvertimeRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _selectedDate!,
        totalEarlyOvertime: _totalEarlyCtrl.text,
        earlyOvertimeStart: _earlyStart?.format(context) ?? '-',
        earlyOvertimeEnd: _earlyEnd?.format(context) ?? '-',
        totalLateOvertime: _totalLateCtrl.text,
        lateOvertimeStart: _lateStart?.format(context) ?? '-',
        lateOvertimeEnd: _lateEnd?.format(context) ?? '-',
        description: _descCtrl.text,
      );
      
      await RequestService.instance.submitOvertimeRequest(req);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan overtime berhasil dikirim')),
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
        title: const Text('Pengajuan Overtime', style: TextStyle(fontSize: 16, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Tanggal
            _buildPickerField(
              label: 'Tanggal',
              value: _selectedDate == null 
                  ? 'Pilih Tanggal' 
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Lembur Awal
            const Text('Lembur Awal', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Total Jam Lembur Awal',
              controller: _totalEarlyCtrl,
              keyboardType: TextInputType.number,
              hint: 'Contoh: 2',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: 'Jam Mulai',
                    value: _earlyStart?.format(context) ?? '--:--',
                    icon: Icons.access_time_rounded,
                    onTap: () async {
                      final t = await _pickTime(_earlyStart);
                      if (t != null) setState(() => _earlyStart = t);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPickerField(
                    label: 'Jam Akhir',
                    value: _earlyEnd?.format(context) ?? '--:--',
                    icon: Icons.access_time_rounded,
                    onTap: () async {
                      final t = await _pickTime(_earlyEnd);
                      if (t != null) setState(() => _earlyEnd = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Lembur Pulang
            const Text('Lembur Pulang', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Total Jam Lembur Pulang',
              controller: _totalLateCtrl,
              keyboardType: TextInputType.number,
              hint: 'Contoh: 3',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: 'Jam Mulai',
                    value: _lateStart?.format(context) ?? '--:--',
                    icon: Icons.access_time_rounded,
                    onTap: () async {
                      final t = await _pickTime(_lateStart);
                      if (t != null) setState(() => _lateStart = t);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPickerField(
                    label: 'Jam Akhir',
                    value: _lateEnd?.format(context) ?? '--:--',
                    icon: Icons.access_time_rounded,
                    onTap: () async {
                      final t = await _pickTime(_lateEnd);
                      if (t != null) setState(() => _lateEnd = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Lampiran
            const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur upload file belum tersedia')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_rounded, color: AppColors.grey600),
                    SizedBox(width: 8),
                    Text('Pilih File', style: TextStyle(color: AppColors.grey800, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Keterangan
            AppTextField(
              label: 'Keterangan',
              controller: _descCtrl,
              hint: 'Tulis keterangan lembur...',
            ),
            const SizedBox(height: AppSpacing.xxxl),
            
            AppButton(
              label: 'Kirim Pengajuan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
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
    );
  }
}
