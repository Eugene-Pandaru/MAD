import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageVouchersPage extends StatefulWidget {
  const ManageVouchersPage({super.key});

  @override
  State<ManageVouchersPage> createState() => _ManageVouchersPageState();
}

class _ManageVouchersPageState extends State<ManageVouchersPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Manage Vouchers", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('vouchers').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          final vouchers = snapshot.data ?? [];

          return Column(
            children: [
              // 📊 TOTAL NUMBER DISPLAY
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Total Vouchers: ${vouchers.length}",
                      style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: vouchers.isEmpty
                    ? Center(child: Text("No vouchers found", style: GoogleFonts.openSans(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: vouchers.length,
                        padding: const EdgeInsets.all(15),
                        itemBuilder: (context, index) {
                          final v = vouchers[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.confirmation_number, color: Colors.white)),
                              title: Text(v['code'] ?? "CODE", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${v['category']} • RM ${v['discount_amount']} (${v['discount_type']})"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showVoucherDialog(context, voucher: v)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDeleteVoucher(v['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVoucherDialog(context),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDeleteVoucher(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Voucher?"),
        content: const Text("Are you sure you want to delete this voucher? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('vouchers').delete().eq('id', id);
              if (mounted) {
                Navigator.pop(context);
                Utils.snackbar(context, "Voucher deleted", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVoucherDialog(BuildContext context, {Map<String, dynamic>? voucher}) {
    final bool isEdit = voucher != null;
    final codeController = TextEditingController(text: isEdit ? voucher['code'] : "");
    final amountController = TextEditingController(text: isEdit ? voucher['discount_amount'].toString() : "");
    final descController = TextEditingController(text: isEdit ? voucher['description'] : "");
    String category = isEdit ? voucher['category'] : 'DISCOUNT';
    String type = isEdit ? voucher['discount_type'] : 'FIXED';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Voucher" : "Add Voucher"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeController, decoration: const InputDecoration(labelText: "Voucher Code", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: "Discount Amount", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: ['DISCOUNT', 'SHIPPING'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder()),
                  items: ['FIXED', 'PERCENTAGE'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => type = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (codeController.text.isEmpty || amountController.text.isEmpty) {
                  Utils.snackbar(context, "Please fill all required fields", color: Colors.red);
                  return;
                }
                
                final data = {
                  'code': codeController.text,
                  'discount_amount': double.tryParse(amountController.text) ?? 0.0,
                  'category': category,
                  'discount_type': type,
                  'description': descController.text,
                };
                
                try {
                  if (isEdit) {
                    await supabase.from('vouchers').update(data).eq('id', voucher['id']);
                    Utils.snackbar(context, "Voucher updated", color: Colors.green);
                  } else {
                    await supabase.from('vouchers').insert(data);
                    Utils.snackbar(context, "Voucher added", color: Colors.green);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
