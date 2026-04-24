import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home/productlist style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Our Specialists",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('pharmacists').select().order('name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1392AB)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text("No pharmacists available.", style: GoogleFonts.openSans(color: Colors.grey)),
                    );
                  }

                  final pharmacists = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pharmacists.length,
                    itemBuilder: (context, index) {
                      final dr = pharmacists[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                dr['image_url'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dr['name'], 
                                    style: GoogleFonts.openSans(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    dr['description'] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.openSans(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  // Select Button
                                  SizedBox(
                                    height: 35,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PharmacistDetailsPage(pharmacist: dr),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1392AB),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                      ),
                                      child: Text(
                                        "Select", 
                                        style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
