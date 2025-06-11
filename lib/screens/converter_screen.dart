import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation

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
        bottom:
            user == null
                ? null // No bottom tab bar if not signed in
                : TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      text: 'Currency',
                      icon: Icon(Icons.currency_exchange_rounded),
                    ),
                    Tab(
                      text: 'Timezone',
                      icon: Icon(Icons.access_time_rounded),
                    ),
                    Tab(text: 'Unit', icon: Icon(Icons.square_foot_rounded)),
                  ],
                  labelColor:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // Brand blue for selected label
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface
                      .withOpacity(0.6), // Grey for unselected
                  indicatorColor:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // Brand blue indicator
                  indicatorSize:
                      TabBarIndicatorSize
                          .tab, // Indicator covers the entire tab
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  // Add a subtle border or line under the tab bar if desired for more separation
                  // decoration: BoxDecoration(
                  //   border: Border(
                  //     bottom: BorderSide(
                  //       color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  //       width: 1.0,
                  //     ),
                  //   ),
                  // ),
                ),
      ),
      body:
          user == null
              ? _buildUnauthenticatedState(
                context,
              ) // Show this if user is not signed in
              : TabBarView(
                controller: _tabController,
                children: const [
                  CurrencyConverterWidget(),
                  TimezoneConverterWidget(),
                  UnitConverterWidget(),
                ],
              ),
    );
  }

  // Private method to build the unauthenticated state UI
  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded, // Lock icon for signed-out state
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to use the currency, timezone, and unit converters.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 30.0,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign In Now',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Currency Converter Widget ---
class CurrencyConverterWidget extends StatefulWidget {
  const CurrencyConverterWidget({super.key}); // Added key
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
  List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'SEK',
    'NZD',
    'MXN',
    'SGD',
    'HKD',
    'NOK',
    'KRW',
    'TRY',
    'RUB',
    'INR',
    'BRL',
    'ZAR',
    'PHP',
    'PLN',
    'THB',
    'MYR',
    'IDR',
  ];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Sort currencies alphabetically for better UX
    _currencies.sort();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        setState(() {
          _error = 'Please enter a valid amount.';
          _loading = false;
        });
        return;
      }
      final rate = await _apiService.fetchCurrencyRate(
        _from,
        _to,
        amount: amount,
      );
      if (rate != null) {
        setState(() {
          _result = rate;
          _error = null;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Conversion failed. Please try again.';
          _result = null;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred during conversion: \\${e.toString()}';
        _result = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define InputDecoration styles for consistent text fields
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Light grey background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none, // No visible border initially
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color:
              Theme.of(context).colorScheme.primary, // Brand blue when focused
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
    );

    return SingleChildScrollView(
      // Added to prevent overflow on small screens
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration.copyWith(
              labelText: 'Amount',
              hintText: 'Enter amount to convert',
              prefixIcon: const Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: inputDecoration.copyWith(
                    labelText: 'From',
                    prefixIcon: const Icon(Icons.currency_exchange_rounded),
                  ),
                  items:
                      _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _from = v!),
                  isExpanded: true, // Allow dropdown to expand
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_right_alt_rounded, // Better arrow icon
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _to,
                  decoration: inputDecoration.copyWith(
                    labelText: 'To',
                    prefixIcon: const Icon(Icons.currency_exchange_rounded),
                  ),
                  items:
                      _currencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _to = v!),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loading ? null : _convert,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
            ),
            child:
                _loading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                    : const Text(
                      'Convert Currency',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          const SizedBox(height: 24),
          if (_result != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Conversion Result:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '${_amountController.text} $_from = ${_result!.toStringAsFixed(2)} $_to',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Timezone Converter Widget ---
class TimezoneConverterWidget extends StatefulWidget {
  const TimezoneConverterWidget({super.key}); // Added key
  @override
  State<TimezoneConverterWidget> createState() =>
      _TimezoneConverterWidgetState();
}

class _TimezoneConverterWidgetState extends State<TimezoneConverterWidget> {
  final TextEditingController _timeController = TextEditingController();
  String _from = 'UTC';
  String _to = 'Asia/Jakarta';
  String? _result;
  String? _error; // For error messages

  // Example timezones. In a real app, this would be a comprehensive list.
  final List<String> _timezones = [
    'UTC',
    'Asia/Jakarta',
    'Europe/London',
    'America/New_York',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Europe/Berlin',
    'Africa/Cairo',
    'America/Los_Angeles',
  ];

  @override
  void initState() {
    super.initState();
    _timezones.sort(); // Sort timezones for better UX
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _convert() {
    setState(() {
      _result = null;
      _error = null;
    });

    try {
      if (_timeController.text.isEmpty) {
        setState(() => _error = 'Please enter a time (HH:mm).');
        return;
      }

      final parts = _timeController.text.split(':');
      if (parts.length != 2) {
        setState(() => _error = 'Invalid time format. Use HH:mm.');
        return;
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        setState(
          () => _error = 'Invalid time. Please use HH:mm (e.g., 14:30).',
        );
        return;
      }

      // Simple mock conversion logic based on offsets relative to UTC
      // For a real app, you'd use a dedicated timezone conversion library
      // e.g., intl package for DateTime.fromMillisecondsSinceEpoch and formatting.
      int fromOffset = _getTimezoneOffset(_from);
      int toOffset = _getTimezoneOffset(_to);

      // Convert input time to UTC
      int utcHour = hour - fromOffset;
      utcHour = (utcHour % 24 + 24) % 24; // Ensure positive hour

      // Convert UTC time to target timezone
      int targetHour = (utcHour + toOffset) % 24;

      _result =
          '${targetHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Conversion failed: ${e.toString()}';
      });
    }
  }

  // Simple mock for timezone offsets (hours relative to UTC)
  int _getTimezoneOffset(String timezone) {
    switch (timezone) {
      case 'UTC':
        return 0;
      case 'Asia/Jakarta':
        return 7; // UTC+7
      case 'Europe/London':
        return 0; // UTC in winter, UTC+1 in summer (simplified)
      case 'America/New_York':
        return -5; // EST, UTC-5
      case 'Asia/Tokyo':
        return 9; // UTC+9
      case 'Australia/Sydney':
        return 10; // AEST, UTC+10
      case 'Europe/Berlin':
        return 1; // CET, UTC+1
      case 'Africa/Cairo':
        return 2; // EET, UTC+2
      case 'America/Los_Angeles':
        return -8; // PST, UTC-8
      default:
        return 0; // Default to UTC
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _timeController,
            keyboardType: TextInputType.datetime, // Suggests date/time keyboard
            decoration: inputDecoration.copyWith(
              labelText: 'Time (HH:mm)',
              hintText: 'e.g., 14:30',
              prefixIcon: const Icon(Icons.schedule_rounded),
            ),
            onTap: () async {
              // Show a time picker for better UX
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                _timeController.text =
                    '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
              }
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: inputDecoration.copyWith(
                    labelText: 'From Timezone',
                    prefixIcon: const Icon(Icons.travel_explore_rounded),
                  ),
                  items:
                      _timezones
                          .map(
                            (tz) =>
                                DropdownMenuItem(value: tz, child: Text(tz)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _from = v!),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_right_alt_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _to,
                  decoration: inputDecoration.copyWith(
                    labelText: 'To Timezone',
                    prefixIcon: const Icon(Icons.travel_explore_rounded),
                  ),
                  items:
                      _timezones
                          .map(
                            (tz) =>
                                DropdownMenuItem(value: tz, child: Text(tz)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _to = v!),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _convert,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
            ),
            child: const Text(
              'Convert Timezone',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          if (_result != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Converted Time:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _result!,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// --- Unit Converter Widget ---
class UnitConverterWidget extends StatefulWidget {
  const UnitConverterWidget({super.key}); // Added key
  @override
  State<UnitConverterWidget> createState() => _UnitConverterWidgetState();
}

class _UnitConverterWidgetState extends State<UnitConverterWidget> {
  final TextEditingController _valueController = TextEditingController();
  String _from = 'km';
  String _to = 'mi';
  double? _result;
  String? _error; // For error messages

  // Define supported unit types and their conversions
  final Map<String, List<String>> _unitTypes = {
    'Length': ['m', 'km', 'mi', 'ft', 'yd', 'in'],
    'Weight': ['kg', 'lb', 'g', 'oz'],
    'Temperature': ['C', 'F', 'K'],
  };

  String _selectedUnitType = 'Length'; // Default unit type
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _convert() {
    setState(() {
      _result = null;
      _error = null;
    });

    final value = double.tryParse(_valueController.text);
    if (value == null) {
      setState(() {
        _error = 'Please enter a valid number.';
      });
      return;
    }
    try {
      double convertedValue;
      switch (_selectedUnitType) {
        case 'Length':
          convertedValue = _apiService.convertLength(value, _from, _to);
          break;
        case 'Weight':
          convertedValue = _apiService.convertWeight(value, _from, _to);
          break;
        case 'Temperature':
          convertedValue = _apiService.convertTemperature(value, _from, _to);
          break;
        default:
          throw 'Unsupported unit type';
      }
      setState(() {
        _result = convertedValue;
      });
    } catch (e) {
      setState(() {
        _error = 'Conversion failed: \\${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
    );

    List<String> currentUnits = _unitTypes[_selectedUnitType] ?? [];
    if (!currentUnits.contains(_from)) {
      _from = currentUnits.isNotEmpty ? currentUnits.first : '';
    }
    if (!currentUnits.contains(_to)) {
      _to = currentUnits.isNotEmpty ? currentUnits.first : '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unit Type Selection
          DropdownButtonFormField<String>(
            value: _selectedUnitType,
            decoration: inputDecoration.copyWith(
              labelText: 'Select Unit Type',
              prefixIcon: const Icon(Icons.category_rounded),
            ),
            items:
                _unitTypes.keys
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (type) {
              setState(() {
                _selectedUnitType = type!;
                // Reset 'from' and 'to' to the first unit of the new type
                _from = _unitTypes[type]!.first;
                _to = _unitTypes[type]!.first;
                _result = null; // Clear previous result
                _error = null; // Clear previous error
              });
            },
            isExpanded: true,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration.copyWith(
              labelText: 'Value',
              hintText: 'Enter value to convert',
              prefixIcon: const Icon(Icons.numbers_rounded),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _from,
                  decoration: inputDecoration.copyWith(
                    labelText: 'From Unit',
                    prefixIcon: const Icon(Icons.arrow_circle_up_rounded),
                  ),
                  items:
                      currentUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _from = v!),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_right_alt_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _to,
                  decoration: inputDecoration.copyWith(
                    labelText: 'To Unit',
                    prefixIcon: const Icon(Icons.arrow_circle_down_rounded),
                  ),
                  items:
                      currentUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _to = v!),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _convert,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
            ),
            child: const Text(
              'Convert Unit',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          if (_result != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Converted Result:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '${_valueController.text} $_from = ${_result!.toStringAsFixed(2)} $_to',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
