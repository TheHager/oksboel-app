import 'dart:ui';

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Vigtig for GPS
import 'nyheder_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const OksbolApp());
}

// DEL 1: Den "offentlige" klasse
class ErhvervHubPage extends StatefulWidget {
  final String startKategori;
  const ErhvervHubPage({super.key, required this.startKategori});

  @override
  State<ErhvervHubPage> createState() => _ErhvervHubPageState();
}

// DEL 2: Den "private" state-klasse (Her sker magien)
class _ErhvervHubPageState extends State<ErhvervHubPage> {
  late String _valgtKategori;
  List<dynamic> _allData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // 1. Tjek om der ligger et filter fra forsiden (f.eks. "Butik" eller "Restaurant")
    String? startFilter = MainNavigation.erhvervFilterNotifier.value;

    if (startFilter != null) {
      // Hvis der ligger noget i postkassen, så brug det!
      _valgtKategori = startFilter;

      // Tøm postkassen med det samme, så den ikke "hænger fast" til næste gang
      MainNavigation.erhvervFilterNotifier.value = null;
    } else {
      // Hvis postkassen er tom, så brug den normale startKategori
      _valgtKategori = widget.startKategori;
    }

    // 2. Hent data baseret på den kategori vi lige har fundet frem til
    _hentErhvervData();
  }

  Future<void> _hentErhvervData() async {
    const url =
        "https://script.google.com/macros/s/AKfycbyHtOHT7rN8FPBN9GvpAeF6WgK9snTmZhQIF-e0mhFy36e30cioVCp20QYfwc84llrQMg/exec?type=erhverv";

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _allData = json.decode(response.body);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Fejl: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FILTRERING: Vi fjerner mellemrum og gør det småt for at undgå fejl
    final filtreretListe = _allData.where((item) {
      String katFraSheet = item['kategori'].toString().trim().toLowerCase();
      String valgtKat = _valgtKategori.trim().toLowerCase();
      return katFraSheet == valgtKat;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Erhverv i Oksbøl",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ), // Samme font-stil
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF27C21),
        elevation: 0,
        centerTitle: true, // Centrerer teksten præcis ligesom på nyhedssiden
      ),
      body: Column(
        children: [
          // FILTER-KNAPPERNE I TOPPEN
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip("Restaurant", Icons.restaurant),
                const SizedBox(width: 12),
                _buildFilterChip("Butik", Icons.storefront),
              ],
            ),
          ),

          // LISTEN MED FIRMAER
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF27C21)),
                  )
                : filtreretListe.isEmpty
                ? const Center(child: Text("Ingen fundet i denne kategori"))
                // ... (Alt dit kode op til ListView.builder er uændret) ...
                : ListView.builder(
                    itemCount: filtreretListe.length,
                    // Vi fjerner horizontal padding her, og lægger det ind i margin på kortet i stedet for et bedre udtryk
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemBuilder: (context, index) {
                      final firma = filtreretListe[index];
                      final billedeUrl = firma['billedeUrl']?.toString() ?? "";

                      // HER STARTER DET NYE DESIGN (Erstatter dit Card)
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 16,
                          left: 20,
                          right: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              // Din originale onTap logik - urørt!
                              final urlString =
                                  firma['hjemmeside']?.toString() ?? "";
                              if (urlString.isNotEmpty) {
                                final Uri url = Uri.parse(urlString);
                                try {
                                  if (!await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    debugPrint("Kunne ikke åbne $urlString");
                                  }
                                } catch (e) {
                                  debugPrint("Fejl ved åbning af link: $e");
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Ingen hjemmeside tilgængelig",
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Logo Boksen
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: billedeUrl.isNotEmpty
                                        ? Image.network(
                                            billedeUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      color:
                                                          Colors.grey.shade100,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade100,
                                            child: const Icon(
                                              Icons.storefront,
                                              color: Color(0xFFF27C21),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Tekst Delen
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firma['navn'] ?? "Navn mangler",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          firma['beskrivelse'] ?? "",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ); // HER SLUTTER DET NYE DESIGN
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // HJÆLPEFUNKTION TIL KNAPPERNE
  Widget _buildFilterChip(String titel, IconData ikon) {
    bool erValgt = _valgtKategori == titel;
    return GestureDetector(
      onTap: () => setState(() => _valgtKategori = titel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: erValgt ? const Color(0xFFF27C21) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              ikon,
              size: 18,
              color: erValgt ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              titel,
              style: TextStyle(
                color: erValgt ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SKYDETIDER SIDE ---
class SkydetiderPage extends StatefulWidget {
  const SkydetiderPage({super.key});

  @override
  State<SkydetiderPage> createState() => _SkydetiderPageState();
}

class _SkydetiderPageState extends State<SkydetiderPage> {
  Future<List<dynamic>> fetchAktiviteter() async {
    return await ApiService.fetchFromScript('skydetider') as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Militære øvelsesaktiviteter',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- DEN FASTE INFO-BOKS I TOPPEN ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF27C21).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF27C21).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ikon og lille overskrift på sin egen linje
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF27C21),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "VIGTIG INFORMATION",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF27C21),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8), // Lidt luft ned til selve teksten
                // Hele din tekst, som nu har fuld plads fra venstre til højre
                Text(
                  "Omhandler KUN skarpskydning på Kallesmærsk hede. Tider er KUN VEJLEDENDE. Gældende tider og afstand meldes ud via Lyngby radio.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // --- LISTEN MED AKTIVITETER (som nu ligger under den faste boks) ---
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: fetchAktiviteter(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF27C21)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Kunne ikke indlæse aktiviteter..."),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Ingen planlagte aktiviteter fundet."),
                  );
                }

                final alleTider = snapshot.data!;
                final nu = DateTime.now();
                // Vi sætter 'i dag' til midnat, så aktiviteter der sker i dag ikke forsvinder før i morgen
                final iDag = DateTime(nu.year, nu.month, nu.day);

                // 1. Filtrer alle de overskredne fra (skjul dem)
                List<dynamic> fremtidigeAktiviteter = alleTider.where((
                  aktivitet,
                ) {
                  if (aktivitet['dato_iso'] == null) return false;
                  final dato = DateTime.parse(aktivitet['dato_iso']);
                  return dato.isAfter(iDag.subtract(const Duration(days: 1)));
                }).toList();

                // 2. Sortér listen, så den dato der er tættest på, ligger øverst
                fremtidigeAktiviteter.sort((a, b) {
                  final datoA = DateTime.parse(a['dato_iso']);
                  final datoB = DateTime.parse(b['dato_iso']);
                  return datoA.compareTo(datoB);
                });

                if (fremtidigeAktiviteter.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Der er ingen planlagte øvelsesaktiviteter i den kommende tid.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                // 3. Byg selve kortene
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ), // Paddingen i toppen er fjernet her, da boksen giver luft
                  itemCount: fremtidigeAktiviteter.length,
                  itemBuilder: (context, index) {
                    final aktivitet = fremtidigeAktiviteter[index];
                    final erNaeste = index == 0;

                    return Card(
                      elevation: erNaeste ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: erNaeste
                            ? const BorderSide(
                                color: Color(0xFFF27C21),
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (erNaeste) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF27C21),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "NÆSTE AKTIVITET",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: erNaeste
                                      ? const Color(0xFFF27C21)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    aktivitet['dag'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: erNaeste
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  aktivitet['tid'],
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  aktivitet['status'],
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Her fortæller vi appen at den skal vente i 2 sekunder
    Future.delayed(const Duration(seconds: 2), () {
      // Efter 2 sekunder hopper den videre til hovedmenuen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Baggrundsfarven på din startskærm
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Her bruger vi dit lokale logo igen
            Image.asset(
              'images/logo.png',
              width: 200, // Her kan du gøre logoet lidt større end i toppen
            ),
            const SizedBox(height: 20),
            // Valgfrit: En lille lade-cirkel under logoet
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF27C21)),
            ),
          ],
        ),
      ),
    );
  }
}

class OksbolApp extends StatelessWidget {
  const OksbolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oksbøl By-app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF27C21)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  // Vi laver en "fjernbetjening" (Controller)
  static final PageController faneController = PageController();
  static ValueNotifier<String?> erhvervFilterNotifier = ValueNotifier<String?>(
    null,
  );

  // Nu bruger vi KUN controlleren til at skifte fane - INGEN setState her!
  static void skiftFane(int index, {String? ekstraData}) {
    if (faneController.hasClients) {
      // Hvis vi har ekstra data (f.eks. "Restaurant"), lægger vi det i postkassen
      if (ekstraData != null) {
        erhvervFilterNotifier.value = ekstraData;
      }

      faneController.jumpToPage(index);
    }
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    // Vi bruger din fjernbetjening til at skifte side i vores PageView
    MainNavigation.skiftFane(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: MainNavigation.faneController,
        physics:
            const NeverScrollableScrollPhysics(), // Forhindrer at man kan swipe med fingeren
        onPageChanged: (index) {
          // Opdaterer ikonet i bunden, når siden skiftes
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          OverblikPage(), // Index 0
          DetSkerPage(), // Index 1
          UdforskPage(), // Index 2
          ErhvervHubPage(startKategori: 'Restaurant'), // Index 3
          NyhederPage(), // Index 4
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // SKAL være fixed ved 5 elementer
        selectedItemColor: const Color(0xFFF27C21), // Din orange farve
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Overblik'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Det sker'),
          BottomNavigationBarItem(icon: Icon(Icons.forest), label: 'Natur'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Erhverv'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Nyt'),
        ],
      ),
    );
  }
}

// 1. DEL: Selve siden
class UdforskPage extends StatefulWidget {
  const UdforskPage({super.key});

  @override
  State<UdforskPage> createState() => _UdforskPageState();
}

// 2. DEL: Logikken og designet
class _UdforskPageState extends State<UdforskPage> {
  String valgtKategori = "Vandre";
  final List<String> kategorier = ["Vandre", "Løb", "Cykel", "MTB"];
  int? _udfoldetIndex;

  Position? _brugerPosition;
  late Future<List<dynamic>> _ruterFuture;

  @override
  void initState() {
    super.initState();
    _ruterFuture = fetchRuter();
    _hentBrugerLokation();
  }

  Future<void> _hentBrugerLokation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _brugerPosition = position;
      });
    }
  }

  double _beregnAfstandITal(dynamic ruteLat, dynamic ruteLon) {
    if (_brugerPosition == null ||
        ruteLat == null ||
        ruteLon == null ||
        ruteLat == "" ||
        ruteLon == "") {
      return 999999.0;
    }
    try {
      final lat = double.parse(ruteLat.toString().replaceAll(',', '.'));
      final lon = double.parse(ruteLon.toString().replaceAll(',', '.'));

      final afstandIMeter = Geolocator.distanceBetween(
        _brugerPosition!.latitude,
        _brugerPosition!.longitude,
        lat,
        lon,
      );
      return afstandIMeter / 1000;
    } catch (e) {
      return 999999.0;
    }
  }

  String _beregnAfstandTekst(dynamic ruteLat, dynamic ruteLon) {
    final afstandIKm = _beregnAfstandITal(ruteLat, ruteLon);
    if (afstandIKm == 999999.0) return "";

    // Uden prik, da den nu har sin egen linje
    return "${afstandIKm.toStringAsFixed(1)} km til start";
  }

  Future<List<dynamic>> fetchRuter() async {
    return await ApiService.fetchFromScript('ruter') as List<dynamic>;
  }

  Future<void> _aabnLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Kunne ikke åbne $urlString');
    }
  }

  Color getRuteFarve(String type, String navn) {
    if (type == "MTB") return Colors.orange;

    // 1. Gør alle bogstaver små
    String rensetNavn = navn.toLowerCase();

    // 2. Fjern kommaer og punktummer, så vi ikke bliver snydt af "Blå,"
    rensetNavn = rensetNavn.replaceAll(RegExp(r'[.,]'), '');

    // 3. Sæt mellemrum før og efter, så vi kan lede efter HELE ord
    rensetNavn = " $rensetNavn ";

    // Nu tjekker vi for farver med mellemrum på begge sider
    if (rensetNavn.contains(" rød ")) return Colors.red;
    if (rensetNavn.contains(" gul ")) return Colors.amber;
    if (rensetNavn.contains(" blå ")) return Colors.blue;
    if (rensetNavn.contains(" grøn ")) return Colors.green;

    // Standard Oksbøl-orange, hvis ingen specifikke farver findes
    return const Color(0xFFF27C21);
  }

  IconData getRuteIkon(String type) {
    if (type == "MTB" || type == "Cykel") return Icons.pedal_bike;
    if (type == "Løb") return Icons.directions_run; // Lille bonus til løberne!
    return Icons.directions_walk; // Standard for Vandre
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Oplev naturen',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF27C21),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: kategorier
                  .map(
                    (kat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(kat),
                        selected: valgtKategori == kat,
                        selectedColor: const Color(0xFFF27C21),
                        onSelected: (bool selected) {
                          setState(() {
                            valgtKategori = kat;
                            _udfoldetIndex = null;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _ruterFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF27C21)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Kunne ikke indlæse ruter..."),
                  );
                }

                final alleRuter = snapshot.data ?? [];
                List<dynamic> filtreret = alleRuter
                    .where((r) => r['type'] == valgtKategori)
                    .toList();

                if (_brugerPosition != null) {
                  filtreret.sort((a, b) {
                    final afstandA = _beregnAfstandITal(
                      a['start_lat'],
                      a['start_lon'],
                    );
                    final afstandB = _beregnAfstandITal(
                      b['start_lat'],
                      b['start_lon'],
                    );
                    return afstandA.compareTo(afstandB);
                  });
                }

                if (filtreret.isEmpty) {
                  return const Center(
                    child: Text("Ingen ruter i denne kategori endnu."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtreret.length,
                  itemBuilder: (context, index) {
                    final rute = filtreret[index];
                    final farve = getRuteFarve(
                      rute['type'],
                      rute['navn'] ?? "",
                    );
                    final erUdfoldet = _udfoldetIndex == index;
                    final afstandString = _beregnAfstandTekst(
                      rute['start_lat'],
                      rute['start_lon'],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          setState(() {
                            _udfoldetIndex = erUdfoldet ? null : index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: farve,
                                    child: Icon(
                                      getRuteIkon(
                                        rute['type'],
                                      ), // NYT: Vi bruger vores nye funktion
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rute['navn'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        Text(
                                          "${rute['laengde']} • ${rute['afmaerket_rute']}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),

                                        // NYT: Her er den nye, orange afstands-linje!
                                        if (afstandString.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Color(0xFFF27C21),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  afstandString,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF27C21),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    erUdfoldet
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              if (erUdfoldet) ...[
                                const SizedBox(height: 16),
                                Text(rute['beskrivelse'] ?? ""),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          _aabnLink(rute['kort_url']),
                                      icon: const Icon(Icons.map, size: 18),
                                      label: const Text("Se kort"),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _aabnLink(rute['start_url']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF27C21,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                        Icons.directions_car,
                                        size: 18,
                                      ),
                                      label: const Text("Find start"),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- VEJR SERVICE ---
class WeatherService {
  final String apiKey = dotenv.env["WEATHER_API_KEY"] ?? "";

  Future<Map<String, dynamic>> fetchWeather() async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=55.62&lon=8.28&appid=$apiKey&units=metric&lang=da';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Fejl ved hentning af vejr, status code: ${response.statusCode}');
    } catch (e) {
      throw Exception('Fejl ved vejr API kald: $e');
    }
  }
}

class OverblikPage extends StatefulWidget {
  const OverblikPage({super.key});

  @override
  State<OverblikPage> createState() => _OverblikPageState();
}

class _OverblikPageState extends State<OverblikPage> {
  // Variabler til Highlight (Begivenhed)
  Map<String, dynamic>? _naesteBegivenhed;

  // Variabler til Nyheder
  List<dynamic> _nyheder = [];
  bool _isLoadingNews = true;

  // Variabler til vejr
  String _temperatur = "-";
  String _vejrbeskrivelse = "Henter vejr...";
  String _ikonUrl = "";
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _hentNaesteBegivenhed();
      _hentNyheder();
      _hentVejrData();
    });
  }

  // Henter den store highlight begivenhed
  Future<void> _hentNaesteBegivenhed() async {
    const url =
        "https://script.google.com/macros/s/AKfycbyHtOHT7rN8FPBN9GvpAeF6WgK9snTmZhQIF-e0mhFy36e30cioVCp20QYfwc84llrQMg/exec?type=Begivenheder";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && mounted) {
          setState(() {
            _naesteBegivenhed = data[0];
          });
        }
      }
    } catch (e) {
      // Vi sletter isLoadingEvent og sætter bare en besked ind i stedet
      debugPrint("Fejl ved hentning af næste begivenhed: $e");
    }
  }

  Future<void> _hentVejrData() async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=oksbol&units=metric&lang=da&appid=${dotenv.env["WEATHER_API_KEY"]}';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Hent temp og rund af til helt tal
            double temp = data['main']['temp'];
            _temperatur = "${temp.round()}°";

            // Hent beskrivelse og gør første bogstav stort ("Klar himmel" fremfor "klar himmel")
            String beskrivelse = data['weather'][0]['description'].toString();
            _vejrbeskrivelse =
                beskrivelse[0].toUpperCase() + beskrivelse.substring(1);

            // Hent det rigtige ikon fra OpenWeather
            String iconCode = data['weather'][0]['icon'];
            _ikonUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";

            _isLoadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _vejrbeskrivelse = "Kunne ikke hente vejr";
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Vejr API fejl: $e");
      if (mounted) {
        setState(() {
          _vejrbeskrivelse = "Fejl ved indlæsning";
          _isLoadingWeather = false;
        });
      }
    }
  }

  // Henter nyhederne fra din nye fane
  Future<void> _hentNyheder() async {
    const url =
        "https://script.google.com/macros/s/AKfycbyHtOHT7rN8FPBN9GvpAeF6WgK9snTmZhQIF-e0mhFy36e30cioVCp20QYfwc84llrQMg/exec?type=Nyheder";
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _nyheder = json.decode(response.body);
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/baggrund.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // --- 1. VEJR SEKTION ---
              Center(
                child: Column(
                  children: [
                    _isLoadingWeather
                        ? const SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : _ikonUrl.isNotEmpty
                        ? Image.network(
                            _ikonUrl,
                            width: 60,
                            height: 60,
                            // Gør ikonet hvidt så det matcher designet. Slet denne linje, hvis du vil have skyernes rigtige farver:
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.wb_sunny,
                            color: Colors.white,
                            size: 50,
                          ),
                    Text(
                      "$_temperatur i Oksbøl",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _vejrbeskrivelse,
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 2. GENVEJS KNAPPER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPillKnap("Oplev naturen", Icons.directions_run),
                    _buildPillKnap("Spisesteder", Icons.restaurant),
                    _buildPillKnap("Butikker", Icons.shopping_bag),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. HIGHLIGHT KORT (Begivenhed) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Næste begivenhed",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHighlightWidget(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 4. AKTUELLE NYHEDER (Løsning 1) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Aktuelle nyheder",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingNews)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF27C21),
                        ),
                      )
                    else if (_nyheder.isEmpty)
                      const Text(
                        "Ingen aktuelle nyheder",
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ..._nyheder.take(3).map((news) => _buildNyhedsKort(news)),
                  ],
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightWidget() {
    if (_naesteBegivenhed == null) return const SizedBox();

    return ClipRRect(
      // Klipper kanterne runde, så blur-effekten ikke går udenfor
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3,
          sigmaY: 3,
        ), // Her er magien! (Sløring)
        child: Container(
          decoration: BoxDecoration(
            // En mørk, semi-gennemsigtig baggrund gør hvid tekst VILDT flot
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ), // En tynd, fin glaskant
          ),
          child: InkWell(
            onTap: () => MainNavigation.skiftFane(1),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _naesteBegivenhed!['navn'] ?? "Begivenhed",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Ændret til hvid
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFFF27C21),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _naesteBegivenhed!['dato'] ?? "",
                        style: const TextStyle(
                          color: Color(0xFFF27C21),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _naesteBegivenhed!['tekst'] ?? "",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(
                        alpha: 0.8,
                      ), // Lysegrå/hvid så det kan læses på mørk glas
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNyhedsKort(dynamic news) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3,
            sigmaY: 3,
          ), // Samme blur som begivenhed
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2), // Mørk glas-baggrund
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: .2)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                news['overskrift'] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white, // Hvid tekst så det kan læses
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  news['dato'] ?? "",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .6), // Lysegrå tekst
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => MainNavigation.skiftFane(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillKnap(String titel, IconData ikon) {
    return GestureDetector(
      onTap: () {
        if (titel == "Oplev naturen") {
          // Sender brugeren til 'Natur' fanen (Index 2)
          MainNavigation.skiftFane(2);
        } else if (titel == "Spisesteder") {
          // Sender brugeren til 'Erhverv' (Index 3) med filteret 'Restaurant'
          MainNavigation.skiftFane(3, ekstraData: "Restaurant");
        } else if (titel == "Butikker") {
          // Sender brugeren til 'Erhverv' (Index 3) med filteret 'Butik'
          MainNavigation.skiftFane(3, ekstraData: "Butik");
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Dette giver det flotte semi-gennemsigtige hvide look
              color: Colors.white.withValues(alpha: .2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: Icon(ikon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            titel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DetSkerPage extends StatefulWidget {
  const DetSkerPage({super.key});

  @override
  State<DetSkerPage> createState() => _DetSkerPageState();
}

class _DetSkerPageState extends State<DetSkerPage> {
  List<dynamic> _begivenheder = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hentBegivenheder();
  }

  Future<void> _hentBegivenheder() async {
    try {
      final data = await ApiService.fetchFromScript('Begivenheder');
      if (!mounted) return;
      setState(() {
        _begivenheder = data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fejl ved hentning af begivenheder: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Det sker i Oksbøl",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ), // Samme font-stil
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF27C21),
        elevation: 0,
        centerTitle: true, // Centrerer teksten præcis ligesom på nyhedssiden
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // MILITÆR KNAP (Beholdt præcis som du lavede den)
          Card(
            color: Colors.green.shade800,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SkydetiderPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.shield, color: Colors.white, size: 30),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forsvarets øvelsesaktiviteter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Kommende begivenheder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 15),

          // DYNAMISK INDHOLD: Viser enten loader, tom besked, eller listen
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFFF27C21)),
              ),
            )
          else if (_begivenheder.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text("Der er pt. ingen andre planlagte begivenheder."),
              ),
            )
          // ... DYNAMISK INDHOLD
          else if (_begivenheder.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text("Der er pt. ingen andre planlagte begivenheder."),
              ),
            )
          else
            // Her bruger vi vores nye interaktive kort!
            ..._begivenheder.map((event) {
              return BegivenhedKort(event: event);
            }),
        ],
      ),
    );
  }
}

class BegivenhedKort extends StatefulWidget {
  final Map<String, dynamic> event;

  const BegivenhedKort({super.key, required this.event});

  @override
  State<BegivenhedKort> createState() => _BegivenhedKortState();
}

class _BegivenhedKortState extends State<BegivenhedKort> {
  // Denne holder styr på, om kortet er foldet ud eller ej
  bool _erFoldetUd = false;

  @override
  Widget build(BuildContext context) {
    final billedeUrl = widget.event['billedeUrl']?.toString() ?? "";

    // Vi tager bare datoen præcis som den står i dit Sheet
    String visningsDato = widget.event['dato']?.toString() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior:
          Clip.antiAlias, // Sikrer at billedet følger de runde hjørner
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Når man trykker, skifter den mellem foldet ud/sammen
          setState(() {
            _erFoldetUd = !_erFoldetUd;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BILLEDE: Tilpasser sig automatisk
            if (billedeUrl.isNotEmpty)
              Image.network(
                billedeUrl,
                width: double.infinity, // Fyld hele bredden
                fit: BoxFit
                    .fitWidth, // Skalerer højden automatisk, så intet skæres af
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATO OG TID
                  Text(
                    "$visningsDato - kl. ${widget.event['tid']}",
                    style: const TextStyle(
                      color: Color(0xFFF27C21),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TITEL OG PIL-IKON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event['navn'] ?? "Uden navn",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Ikonet skifter afhængigt af om den er åben
                      Icon(
                        _erFoldetUd
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  // BESKRIVELSE OG LOKATION (Visuelt skjult, medmindre den er foldet ud)
                  if (_erFoldetUd) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 1. Beskrivelse
                    Text(
                      widget.event['beskrivelse'] ?? "",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),

                    // 2. Lokation (Hvis der er en)
                    if (widget.event['lokation'] != null &&
                        widget.event['lokation'] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.event['lokation'],
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. HER ER DEN NYE KNAP (Tilføjet i bunden)
                    if (widget.event['link'] != null &&
                        widget.event['link'] != "")
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double
                              .infinity, // Gør knappen lige så bred som kortet
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(widget.event['link']);
                              try {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                debugPrint("Kunne ikke åbne link: $e");
                              }
                            },
                            icon: const Icon(Icons.public, size: 20),
                            label: const Text(
                              "Se mere",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF27C21),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                  ], // <-- Her slutter hele fold-ud sektionen

                  if (widget.event['lokation'] != null &&
                      widget.event['lokation'] != "")
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.event['lokation'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
