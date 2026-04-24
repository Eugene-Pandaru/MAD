import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mad/footer.dart';
import 'package:mad/utility.dart';
import 'package:mad/pharmacistdetails.dart';

class PharmacistListPage extends StatefulWidget {
  const PharmacistListPage({super.key});

  @override
  State<PharmacistListPage> createState() => _PharmacistListPageState();
}

class _PharmacistListPageState extends State<PharmacistListPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Pharmacist"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('pharmacists').select().order('name'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No pharmacists available."));
                }

                final pharmacists = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: pharmacists.length,
                  itemBuilder: (context, index) {
                    final dr = pharmacists[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                dr['image_url'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dr['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(
                                      dr['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)
                                  ),
                                ],
                              ),
                            ),
                            // Select Button
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Inside your PharmacistListPage ListView.builder
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PharmacistDetailsPage(pharmacist: dr),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text("Select", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}