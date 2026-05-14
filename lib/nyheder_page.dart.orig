// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
// ignore: unused_import
import 'package:oksboel_app/main.dart';

class NyhederPage extends StatefulWidget {
  const NyhederPage({super.key});

  @override
  State<NyhederPage> createState() => _NyhederPageState();
}

class _NyhederPageState extends State<NyhederPage> {
  List<dynamic> _nyheder = [];
  bool _isLoading = true;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    // Vi henter nyhederne i det sekund siden åbnes
    _hentNyheder();
  }

  Future<void> _hentNyheder() async {
    // VIGTIGT: Sæt din egen Google Apps Script URL ind her!
    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbyHtOHT7rN8FPBN9GvpAeF6WgK9snTmZhQIF-e0mhFy36e30cioVCp20QYfwc84llrQMg/exec?type=Nyheder';

    try {
      final response = await http.get(Uri.parse(scriptUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            // Husk at tjekke om det hedder 'nyheder' i dit script
            _nyheder = data as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
      // ... nede i din catch-blok:
    } catch (e) {
      // Dette giver en flot, rød advarsel i din VS Code terminal!
      logger.e("Der skete en fejl under hentning af nyheder", error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. En meget lys, blød grå baggrund, så de hvide nyhedskort "popper" frem
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Nyheder fra Oksbøl",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF27C21),
        elevation:
            0, // Fjerner den hårde skygge under topbaren for et mere "fladt" look
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF27C21)),
            )
          : _nyheder.isEmpty
          ? Center(
              child: Text(
                "Ingen nyheder at vise i øjeblikket.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20), // Mere luft ude i siderne
              itemCount: _nyheder.length,
              itemBuilder: (context, index) {
                final nyhed = _nyheder[index];
                return _buildNyhedsKort(nyhed);
              },
            ),
    );
  }

  Widget _buildNyhedsKort(Map<String, dynamic> nyhed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24), // God plads mellem hver nyhed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Store, bløde hjørner
        boxShadow: [
          // En meget svag, elegant skygge i stedet for standard "Card" skyggen
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Virkelig god indvendig plads
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Moderne "Dato-pille" med en svag orange baggrund
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF27C21).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nyhed['dato'] ?? "",
                style: const TextStyle(
                  color: Color(0xFFF27C21),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5, // Gør små bogstaver lidt nemmere at læse
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overskrift
            Text(
              nyhed['overskrift'] ?? "Uden overskrift",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800, // Tyk og markant
                letterSpacing:
                    -0.5, // Et let "minus" i afstanden giver et super moderne look
                color: Color(
                  0xFF1A1A1A,
                ), // Næsten sort, hvilket er blidere for øjnene
              ),
            ),
            const SizedBox(height: 12),

            // Selve teksten
            Text(
              nyhed['tekst'] ?? "",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.6, // Øget linjeafstand gør teksten LÆKKER at læse
              ),
            ),
          ],
        ),
      ),
    );
  }
}
