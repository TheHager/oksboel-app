// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
// ignore: unused_import
import 'package:oksboel_app/main.dart';
import 'package:oksboel_app/utils/proxy_helper.dart';

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
                return NyhedKort(nyhed: nyhed);
              },
            ),
    );
  }


}

class NyhedKort extends StatefulWidget {
  final Map<String, dynamic> nyhed;

  const NyhedKort({super.key, required this.nyhed});

  @override
  State<NyhedKort> createState() => _NyhedKortState();
}

class _NyhedKortState extends State<NyhedKort> {
  bool _erFoldetUd = false;

  @override
  Widget build(BuildContext context) {
    final billedeUrl = widget.nyhed['billedeUrl']?.toString() ?? "";
    String visningsDato = widget.nyhed['dato']?.toString() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: () {
          setState(() {
            _erFoldetUd = !_erFoldetUd;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (billedeUrl.isNotEmpty)
              Image.network(
                getProxyUrl(billedeUrl),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visningsDato,
                    style: const TextStyle(
                      color: Color(0xFFF27C21),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.nyhed['overskrift'] ?? "Uden overskrift",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _erFoldetUd ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (_erFoldetUd) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      widget.nyhed['tekst'] ?? "",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
