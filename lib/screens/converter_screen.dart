import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Currency'),
            Tab(text: 'Timezone'),
            Tab(text: 'Unit'),
          ],
        ),
      ),
      body:
          user == null
              ? const Center(
                child: Text(
                  'Not signed in',
                  style: TextStyle(color: Colors.red),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  // Currency Converter
                  CurrencyConverterWidget(),
                  // Timezone Converter
                  TimezoneConverterWidget(),
                  // Unit Converter
                  UnitConverterWidget(),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Converter is index 2
        onTap: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
          } else if (index == 1) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => MapScreen()));
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Nearby'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Converter',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CurrencyConverterWidget extends StatefulWidget {
  @override
  State<CurrencyConverterWidget> createState() =>
      _CurrencyConverterWidgetState();
}

class _CurrencyConverterWidgetState extends State<CurrencyConverterWidget> {
  final TextEditingController _amountController = TextEditingController();
  String _from = 'USD';
  String _to = 'EUR';
  double? _result;
  bool _loading = false;
  String? _error;

  static const String accessKey = 'b317b9330af979844a9c880e1e97f01c';

  Future<void> _convert() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        setState(() {
          _error = 'Invalid amount';
          _loading = false;
        });
        return;
      }
      final url = Uri.parse(
        'https://api.exchangerate.host/convert?from=$_from&to=$_to&amount=$amount&access_key=$accessKey',
      );
      final response = await http.get(url);
      print('API status: \\${response.statusCode}');
      print('API body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['result'] != null) {
          setState(() {
            _result = (data['result'] as num?)?.toDouble();
            _loading = false;
          });
        } else {
          setState(() {
            _error = data['error']?['info'] ?? 'API error';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'API error';
          _loading = false;
        });
      }
    } catch (e) {
      print('Exception: \\${e.toString()}');
      setState(() {
        _error = 'Conversion failed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _from,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                ],
                onChanged: (v) => setState(() => _from = v!),
              ),
              const Icon(Icons.arrow_forward),
              DropdownButton<String>(
                value: _to,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                ],
                onChanged: (v) => setState(() => _to = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _convert,
            child:
                _loading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Convert'),
          ),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Result: $_result',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

class TimezoneConverterWidget extends StatefulWidget {
  @override
  State<TimezoneConverterWidget> createState() =>
      _TimezoneConverterWidgetState();
}

class _TimezoneConverterWidgetState extends State<TimezoneConverterWidget> {
  final TextEditingController _timeController = TextEditingController();
  String _from = 'UTC';
  String _to = 'Asia/Jakarta';
  String? _result;

  void _convert() {
    try {
      final time = TimeOfDay(
        hour: int.parse(_timeController.text.split(':')[0]),
        minute: int.parse(_timeController.text.split(':')[1]),
      );
      // Mock: add 7 hours if converting UTC to Asia/Jakarta
      if (_from == 'UTC' && _to == 'Asia/Jakarta') {
        final newHour = (time.hour + 7) % 24;
        _result =
            '${newHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (_from == 'Asia/Jakarta' && _to == 'UTC') {
        final newHour = (time.hour - 7) % 24;
        _result =
            '${newHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        _result = _timeController.text;
      }
      setState(() {});
    } catch (e) {
      setState(() {
        _result = 'Invalid time format';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _from,
                items: const [
                  DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  DropdownMenuItem(
                    value: 'Asia/Jakarta',
                    child: Text('Asia/Jakarta'),
                  ),
                ],
                onChanged: (v) => setState(() => _from = v!),
              ),
              const Icon(Icons.arrow_forward),
              DropdownButton<String>(
                value: _to,
                items: const [
                  DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  DropdownMenuItem(
                    value: 'Asia/Jakarta',
                    child: Text('Asia/Jakarta'),
                  ),
                ],
                onChanged: (v) => setState(() => _to = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _convert, child: const Text('Convert')),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Result: $_result',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UnitConverterWidget extends StatefulWidget {
  @override
  State<UnitConverterWidget> createState() => _UnitConverterWidgetState();
}

class _UnitConverterWidgetState extends State<UnitConverterWidget> {
  final TextEditingController _valueController = TextEditingController();
  String _from = 'km';
  String _to = 'mi';
  double? _result;

  void _convert() {
    final value = double.tryParse(_valueController.text);
    if (value == null) {
      setState(() {
        _result = null;
      });
      return;
    }
    if (_from == 'km' && _to == 'mi') {
      _result = value * 0.621371;
    } else if (_from == 'mi' && _to == 'km') {
      _result = value / 0.621371;
    } else if (_from == _to) {
      _result = value;
    } else {
      _result = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _from,
                items: const [
                  DropdownMenuItem(value: 'km', child: Text('km')),
                  DropdownMenuItem(value: 'mi', child: Text('mi')),
                ],
                onChanged: (v) => setState(() => _from = v!),
              ),
              const Icon(Icons.arrow_forward),
              DropdownButton<String>(
                value: _to,
                items: const [
                  DropdownMenuItem(value: 'km', child: Text('km')),
                  DropdownMenuItem(value: 'mi', child: Text('mi')),
                ],
                onChanged: (v) => setState(() => _to = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _convert, child: const Text('Convert')),
          if (_result != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Result: $_result',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
