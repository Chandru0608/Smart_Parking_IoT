
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartParkingApp());
}

const bg = Color(0xFF0B1220);
const panel = Color(0xFF14243A);
const green = Color(0xFF22C55E);
const cyan = Color(0xFF22D3EE);
const red = Color(0xFFFB7185);

class SmartParkingApp extends StatelessWidget {
  const SmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkEase',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
        ),
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Map<String, bool> slots = {
    'A1': false,
    'A2': true,
    'A3': false,
    'A4': true,
    'B1': false,
    'B2': false,
    'B3': true,
    'B4': false,
  };

  String filter = 'All';
  int selectedTab = 0;

  int get available =>
      slots.values.where((v) => !v).length;

  int get occupied => slots.length - available;

  String get recommendation {
    for (final entry in slots.entries) {
      if (!entry.value) return entry.key;
    }
    return 'Full';
  }

  void showSlotDetails(String name) {
    final isOccupied = slots[name]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_parking,
                size: 48,
                color: isOccupied ? red : green,
              ),
              const SizedBox(height: 12),
              Text(
                'Parking Slot $name',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOccupied ? 'Currently Occupied' : 'Currently Available',
                style: TextStyle(
                  color: isOccupied ? red : green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isOccupied
                    ? 'This space is currently occupied.'
                    : 'This space is available for parking.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            dashboardPage(),
            parkingPage(),
            analyticsPage(),
            settingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: cyan.withValues(alpha: 0.18),
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            selectedIcon: Icon(Icons.local_parking),
            label: 'Parking',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget dashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          const SizedBox(height: 25),
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Your parking space at a glance.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 22),
          availabilityCard(),
          const SizedBox(height: 25),
          sectionTitle('Parking Overview', 'VIEW ALL', () {
            setState(() => selectedTab = 1);
          }),
          const SizedBox(height: 15),
          slotGrid(limit: 4),
          const SizedBox(height: 20),
          recommendationCard(),
          const SizedBox(height: 20),
          const Text(
            'Live Hardware Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: hardwareCard(
                  Icons.door_sliding,
                  'Gate',
                  'Open',
                  green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hardwareCard(
                  Icons.straighten,
                  'Distance',
                  '8.5 cm',
                  cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, color: green),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Demo mode - sample data'),
                ),
                Text(
                  'DEMO',
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.local_parking,
            color: green,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PARKEASE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 17,
                ),
              ),
              Text(
                'SMART PARKING SYSTEM',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none),
        ),
        const CircleAvatar(
          backgroundColor: panel,
          child: Icon(Icons.person, color: cyan),
        ),
      ],
    );
  }

  Widget availabilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF164E45),
            Color(0xFF12364B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL PARKING AVAILABILITY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: available.toDouble()),
                duration: const Duration(milliseconds: 900),
                builder: (context, value, child) {
                  return Text(
                    value.toInt().toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 9, left: 8),
                child: Text(
                  '/ 08 SLOTS FREE',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Expanded(
                  flex: available == 0 ? 1 : available,
                  child: Container(height: 9, color: green),
                ),
                if (occupied > 0)
                  Expanded(
                    flex: occupied,
                    child: Container(height: 9, color: red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              statusLegend(green, '$available Available'),
              statusLegend(red, '$occupied Occupied'),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusLegend(Color color, String text) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: const TextStyle(color: cyan),
          ),
        ),
      ],
    );
  }

  Widget slotGrid({int? limit}) {
    final names = slots.keys.toList();
    final visible = limit == null ? names : names.take(limit).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: limit == null ? 0.88 : 0.92,
      ),
      itemBuilder: (context, index) {
        final name = visible[index];
        final isOccupied = slots[name]!;

        return InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => showSlotDetails(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isOccupied
                  ? const Color(0xFF492630)
                  : const Color(0xFF153B35),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isOccupied ? red : green,
                width: 1.1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car,
                  color: isOccupied ? red : green,
                  size: 27,
                ),
                const SizedBox(height: 7),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOccupied ? 'TAKEN' : 'FREE',
                  style: TextStyle(
                    color: isOccupied ? red : green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget recommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF123B50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: cyan, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMART RECOMMENDATION',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your next parking spot',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            recommendation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget hardwareCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget parkingPage() {
    final filtered = slots.keys.where((name) {
      if (filter == 'Available') return !slots[name]!;
      if (filter == 'Occupied') return slots[name]!;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parking Spaces',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a slot to view its details.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: ['All', 'Available', 'Occupied'].map((item) {
              return ChoiceChip(
                label: Text(item),
                selected: filter == item,
                onSelected: (_) => setState(() => filter = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final name = filtered[index];
              final isOccupied = slots[name]!;
              return InkWell(
                onTap: () => showSlotDetails(name),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: isOccupied ? red : green),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: isOccupied ? red : green,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOccupied ? 'Occupied' : 'Available',
                        style: TextStyle(
                          color: isOccupied ? red : green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget analyticsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parking Analytics',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          hardwareCard(
            Icons.pie_chart,
            'Current Occupancy',
            '${occupied * 100 ~/ 8}%',
            cyan,
          ),
          const SizedBox(height: 15),
          hardwareCard(
            Icons.check_circle,
            'Available Spaces',
            '$available / 8',
            green,
          ),
          const SizedBox(height: 15),
          hardwareCard(
            Icons.directions_car,
            'Occupied Spaces',
            '$occupied / 8',
            red,
          ),
          const SizedBox(height: 20),
          const Text(
            'Analytics will use real parking history after backend integration.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget settingsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const ListTile(
            leading: Icon(Icons.cloud_outlined, color: cyan),
            title: Text('Backend connection'),
            subtitle: Text('Not connected yet'),
          ),
          const Divider(color: Colors.white12),
          const ListTile(
            leading: Icon(Icons.storage, color: cyan),
            title: Text('MongoDB'),
            subtitle: Text('Integration pending'),
          ),
          const Divider(color: Colors.white12),
          const ListTile(
            leading: Icon(Icons.info_outline, color: cyan),
            title: Text('App version'),
            subtitle: Text('1.0.0 - Demo'),
          ),
        ],
      ),
    );
  }
}
