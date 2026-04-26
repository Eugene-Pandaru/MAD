import 'package:flutter/material.dart';
import 'package:mad/utility.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class ManagePharmacistsPage extends StatefulWidget {
  const ManagePharmacistsPage({super.key});

  @override
  State<ManagePharmacistsPage> createState() => _ManagePharmacistsPageState();
}

class _ManagePharmacistsPageState extends State<ManagePharmacistsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _pharmacistsFuture;
  Key _listViewKey = UniqueKey(); // Added: Key for the ListView.builder

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _pharmacistsFuture = supabase.from('pharmacists').select().order('name');
      _listViewKey = UniqueKey(); // Added: Update the key to force ListView rebuild
    });
  }

  Widget _buildPharmacistImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.person, color: Colors.teal, size: 40);

    return Image.network(
      url,
      // 🔑 The ValueKey forces the UI to update when the URL changes
      key: ValueKey(url),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal));
      },
      errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.teal, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Manage Pharmacists", style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pharmacistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));

          final pharmacists = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Text(
                  "Total Pharmacists: ${pharmacists.length}",
                  style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: pharmacists.isEmpty
                    ? Center(child: Text("No pharmacists found", style: GoogleFonts.openSans(color: Colors.grey)))
                    : ListView.builder(
                  key: _listViewKey, // Added: Assign the key to the ListView.builder
                  itemCount: pharmacists.length,
                  padding: const EdgeInsets.all(15),
                  itemBuilder: (context, index) {
                    final ph = pharmacists[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                      child: ListTile(
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[100]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildPharmacistImage(ph['image_url'])),
                        ),
                        title: Text(ph['name'], style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
                        subtitle: Text(ph['description'] ?? "No description", maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showPharmaDialog(context, pharmacist: ph)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(ph['id'])),
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
        onPressed: () => _showPharmaDialog(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Specialist?"),
        content: const Text("Are you sure? This will remove the pharmacist from the appointment list."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('pharmacists').delete().eq('id', id);
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData(); // Refresh list after delete
                  Utils.snackbar(context, "Pharmacist deleted", color: Colors.red);
                }
              } catch (e) {
                if (mounted) Utils.snackbar(context, "Error: $e", color: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPharmaDialog(BuildContext context, {Map<String, dynamic>? pharmacist}) {
    final bool isEdit = pharmacist != null;
    final nameController = TextEditingController(text: isEdit ? pharmacist['name'] : "");
    final descController = TextEditingController(text: isEdit ? pharmacist['description'] : "");
    String? imageUrl = isEdit ? pharmacist['image_url'] : null;
    File? tempPickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Edit Pharmacist" : "Add New Pharmacist"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        tempPickedFile = File(image.path);
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!)
                        ),
                        child: ClipOval(
                          child: tempPickedFile != null
                              ? Image.file(tempPickedFile!, fit: BoxFit.cover)
                              : _buildPharmacistImage(imageUrl),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  Utils.snackbar(context, "Name is required", color: Colors.red);
                  return;
                }

                try {
                  String? finalImageUrlForDB = imageUrl; // Start with the existing or initial imageUrl
                  if (tempPickedFile != null) {
                    final fileName = 'pharma_${DateTime.now().millisecondsSinceEpoch}.png';
                    final uploadedUrl = await Utils.uploadImage(
                        file: tempPickedFile!,
                        bucket: 'pharmacist',
                        fileName: fileName
                    );
                    if (uploadedUrl != null) {
                      setState(() { // Update imageUrl in the dialog's state
                        imageUrl = uploadedUrl;
                      });
                      finalImageUrlForDB = uploadedUrl; // This will be used for the database update
                    } else {
                      if (mounted) Utils.snackbar(context, "Image upload failed.", color: Colors.red);
                      return; // Stop if upload failed
                    }
                  }

                  final data = {
                    'name': nameController.text,
                    'description': descController.text,
                    'image_url': finalImageUrlForDB // Use the potentially new URL for DB update
                  };

                  if (isEdit) {
                    await supabase.from('pharmacists').update(data).eq('id', pharmacist['id']);
                    Utils.snackbar(context, "Updated successfully", color: Colors.green);
                  } else {
                    await supabase.from('pharmacists').insert(data);
                    Utils.snackbar(context, "Added successfully", color: Colors.green);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData(); // Refresh the parent list immediately
                  }
                } catch (e) {
                  Utils.snackbar(context, "Error: $e", color: Colors.red);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}