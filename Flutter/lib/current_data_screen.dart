import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class CurrentDataScreen extends StatefulWidget {
  const CurrentDataScreen({super.key});

  @override
  State<CurrentDataScreen> createState() => _CurrentDataScreenState();
}

class _CurrentDataScreenState extends State<CurrentDataScreen> {
  Map<String, dynamic>? currentData;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCurrentData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCurrentData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

void _fetchCurrentData() async {
  try {
    final data = await ApiService().fetchData();
    setState(() {
      currentData = data.last;
    });

    // Cek apakah nilai gas lebih dari 2500
    if (currentData!['sensor_value_gas'] > 2500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Warning: Gas level is above 2500 PPM!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentData == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildMetricsGrid(),
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IoT Monitor',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3250),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getFormattedDateTime(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        _buildLocationCard(), // Kartu lokasi ditampilkan di bawah tanggal
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        _buildMetricCard(
          'Temperature',
          '${currentData!['sensor_value_temp']}°',
          'Celsius',
          Icons.thermostat_outlined,
          const Color(0xFFFFF3E9),
          const Color(0xFFFF9950),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Humidity',
                '${currentData!['sensor_value_humidity']}',
                'Percent',
                Icons.water_drop_outlined,
                const Color(0xFFE9F6FF),
                const Color(0xFF4C9AFF),
                small: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Gas Level',
                currentData!['sensor_value_gas'].toString(),
                'PPM',
                Icons.air_outlined,
                const Color(0xFFEFFFF3),
                const Color(0xFF4CAF50),
                small: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color bgColor,
    Color accentColor, {
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.all(small ? 20 : 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3250),
                ),
              ),
              Icon(
                icon,
                color: accentColor,
                size: small ? 20 : 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 24 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3250),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: small ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3250).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF2D3250),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ruang Kelas 8-301',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3250),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedDateTime() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
