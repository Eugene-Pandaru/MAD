import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageRewardsPage extends StatefulWidget {
  const ManageRewardsPage({super.key});

  @override
  State<ManageRewardsPage> createState() => _ManageRewardsPageState();
}

class _ManageRewardsPageState extends State<ManageRewardsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Manage Rewards", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('rewards').stream(primaryKey: ['id']).order('points_required'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          final rewards = snapshot.data ?? [];

          if (rewards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No rewards found", style: GoogleFonts.openSans(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rewards.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final r = rewards[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.card_giftcard, color: Colors.white)),
                  title: Text(r['name'] ?? "Reward", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${r['points_required']} pts • ${r['description'] ?? ''}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showRewardDialog(context, reward: r)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(r['id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRewardDialog(context),
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Reward?"),
        content: const Text("Are you sure you want to remove this reward?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('rewards').delete().eq('id', id);
              Navigator.pop(context);
              Utils.snackbar(context, "Reward deleted");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog(BuildContext context, {Map<String, dynamic>? reward}) {
    final bool isEdit = reward != null;
    final nameController = TextEditingController(text: isEdit ? reward['name'] : "");
    final ptsController = TextEditingController(text: isEdit ? reward['points_required'].toString() : "");
    final descController = TextEditingController(text: isEdit ? reward['description'] : "");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Reward" : "Add Reward", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Reward Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: ptsController, decoration: const InputDecoration(labelText: "Points Required", border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || ptsController.text.isEmpty) {
                  Utils.snackbar(context, "Please fill in all fields", color: Colors.red);
                  return;
                }
                final data = {
                  'name': nameController.text,
                  'points_required': int.parse(ptsController.text),
                  'description': descController.text,
                };
                try {
                  if (isEdit) {
                    await supabase.from('rewards').update(data).eq('id', reward['id']);
                    Utils.snackbar(context, "Reward updated");
                  } else {
                    await supabase.from('rewards').insert(data);
                    Utils.snackbar(context, "Reward added");
                  }
                  Navigator.pop(context);
                } catch (e) {
                  Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
