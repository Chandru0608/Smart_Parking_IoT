import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Windows desktop: http://localhost:3000
// Android emulator: http://10.0.2.2:3000
// Physical phone: replace with your laptop's LAN IPv4 address.
const String apiBaseUrl = 'http://localhost:3000';

void main() => runApp(const SmartParkingApp());

const bg = Color(0xFF0B1220);
const panel = Color(0xFF14243A);
const green = Color(0xFF22C55E);
const cyan = Color(0xFF22D3EE);
const red = Color(0xFFFB7185);

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ParkEase',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
    ),
    home: const Dashboard(),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final List<String> slotNames = const ['A1', 'A2', 'B1', 'B2'];
  Map<String, int> slots = {'A1': 0, 'A2': 0, 'B1': 0, 'B2': 0};
  String recommendation = 'A1';
  DateTime? updatedAt;
  bool loading = true;
  String? error;
  Timer? refreshTimer;

  int get occupied => slots.values.where((v) => v == 1).length;
  int get available => 4 - occupied;

  @override
  void initState() {
    super.initState();
    fetchParking();
    refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetchParking());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchParking() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/parking'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final rawSlots = Map<String, dynamic>.from(data['slots'] as Map);
      final nextSlots = <String, int>{};
      for (final name in slotNames) {
        final value = rawSlots[name];
        if (value != 0 && value != 1) throw Exception('Invalid slot value for $name');
        nextSlots[name] = value as int;
      }
      if (!mounted) return;
      setState(() {
        slots = nextSlots;
        recommendation = data['recommendedSlot'] as String? ?? 'PARKING FULL';
        updatedAt = data['updatedAt'] == null ? null : DateTime.parse(data['updatedAt'] as String).toLocal();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: panel,
      title: const Row(children: [
        Icon(Icons.local_parking, color: green),
        SizedBox(width: 10),
        Text('PARKEASE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ]),
      actions: [IconButton(onPressed: fetchParking, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
    ),
    body: RefreshIndicator(
      onRefresh: fetchParking,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('SMART PARKING SYSTEM', style: TextStyle(color: Colors.white54, letterSpacing: 1.2)),
          const SizedBox(height: 18),
          _summaryCard(),
          const SizedBox(height: 22),
          const Text('PARKING SLOTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slotNames.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final name = slotNames[index];
              final isOccupied = slots[name] == 1;
              final color = isOccupied ? red : green;
              return Container(
                decoration: BoxDecoration(
                  color: panel, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color, width: 1.3),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.directions_car, color: color, size: 30),
                  const SizedBox(height: 7),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(isOccupied ? 'OCCUPIED' : 'AVAILABLE',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                ]),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF123B50), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: cyan, size: 30),
              const SizedBox(width: 12),
              const Expanded(child: Text('RECOMMENDED SLOT', style: TextStyle(color: cyan, fontWeight: FontWeight.bold))),
              Text(recommendation, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 16),
          if (loading) const Center(child: Padding(
            padding: EdgeInsets.all(12), child: CircularProgressIndicator(),
          )),
          if (error != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text('Backend connection issue: $error\nCheck that the backend is running and API URL is correct.',
              style: const TextStyle(color: red)),
          ),
          if (error == null && updatedAt != null)
            Text('Last updated: ${updatedAt!.toString()}',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          const Text('Dashboard refreshes automatically every 3 seconds.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF164E45), Color(0xFF12364B)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PARKING AVAILABILITY', style: TextStyle(color: Colors.white70, letterSpacing: 1)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$available', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
        const Padding(padding: EdgeInsets.only(left: 8, bottom: 10),
          child: Text('/ 4 SLOTS FREE', style: TextStyle(color: Colors.white70))),
      ]),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(children: [
          if (available > 0) Expanded(flex: available, child: Container(height: 9, color: green)),
          if (occupied > 0) Expanded(flex: occupied, child: Container(height: 9, color: red)),
        ]),
      ),
      const SizedBox(height: 10),
      Text('$available Available   •   $occupied Occupied', style: const TextStyle(color: Colors.white70)),
    ]),
  );
}
