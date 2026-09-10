import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(const CreativeCalculatorApp());
}

class CreativeCalculatorApp extends StatelessWidget {
  const CreativeCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Creativa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        primaryColor: const Color(0xFFD81B60),
        scaffoldBackgroundColor: const Color(0xFFFFF5F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60),
          primary: const Color(0xFFD81B60),
        ),
        useMaterial3: true,
      ),
      home: const MainWrapper(),
    );
  }
}

// ---------------------------------------------------------------------------
// MODELS & TYPES
// ---------------------------------------------------------------------------

enum FlowerType { TULIP, DAHLIA, ROSE, SUNFLOWER, DAISY, LEAF }

const Map<FlowerType, String> flowerTypeLabels = {
  FlowerType.TULIP: 'Tulipanes',
  FlowerType.DAHLIA: 'Dalias',
  FlowerType.ROSE: 'Rosas',
  FlowerType.SUNFLOWER: 'Girasoles',
  FlowerType.DAISY: 'Margaritas',
  FlowerType.LEAF: 'Hojas',
};

class FlowerSettings {
  double cmPerPetal;
  int petalsPerFlower;
  double siliconePerFlower;

  FlowerSettings({
    this.cmPerPetal = 0.0,
    this.petalsPerFlower = 0,
    this.siliconePerFlower = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'cmPerPetal': cmPerPetal,
        'petalsPerFlower': petalsPerFlower,
        'siliconePerFlower': siliconePerFlower,
      };

  factory FlowerSettings.fromJson(Map<String, dynamic> json) {
    return FlowerSettings(
      cmPerPetal: (json['cmPerPetal'] ?? 0).toDouble(),
      petalsPerFlower: json['petalsPerFlower'] ?? 0,
      siliconePerFlower: (json['siliconePerFlower'] ?? 0).toDouble(),
    );
  }
}

class DatabaseSettings {
  // Globals
  double tapePrice;
  double tapeLength;
  double siliconeBarPrice;
  double koreanPaperPrice;
  double sticksPackPrice;
  double pearlsPackPrice;
  double printingCost;
  double butterflyPackPrice;
  int butterfliesPerPack;

  // Specifics
  Map<String, FlowerSettings> flowerSettings;

  DatabaseSettings({
    this.tapePrice = 0.0,
    this.tapeLength = 0.0,
    this.siliconeBarPrice = 0.0,
    this.koreanPaperPrice = 0.0,
    this.sticksPackPrice = 0.0,
    this.pearlsPackPrice = 0.0,
    this.printingCost = 0.0,
    this.butterflyPackPrice = 0.0,
    this.butterfliesPerPack = 0,
    Map<String, FlowerSettings>? flowerSettings,
  }) : flowerSettings = flowerSettings ??
            {
              for (var t in FlowerType.values)
                t.toString(): FlowerSettings()
            };

  Map<String, dynamic> toJson() => {
        'tapePrice': tapePrice,
        'tapeLength': tapeLength,
        'siliconeBarPrice': siliconeBarPrice,
        'koreanPaperPrice': koreanPaperPrice,
        'sticksPackPrice': sticksPackPrice,
        'pearlsPackPrice': pearlsPackPrice,
        'printingCost': printingCost,
        'butterflyPackPrice': butterflyPackPrice,
        'butterfliesPerPack': butterfliesPerPack,
        'flowerSettings': flowerSettings.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory DatabaseSettings.fromJson(Map<String, dynamic> json) {
    var rawMap = json['flowerSettings'] as Map<String, dynamic>?;
    Map<String, FlowerSettings> parsedMap = {};
    if (rawMap != null) {
      rawMap.forEach((key, value) {
        parsedMap[key] = FlowerSettings.fromJson(value);
      });
    } else {
      for (var t in FlowerType.values) {
        parsedMap[t.toString()] = FlowerSettings();
      }
    }

    return DatabaseSettings(
      tapePrice: (json['tapePrice'] ?? 0).toDouble(),
      tapeLength: (json['tapeLength'] ?? 0).toDouble(),
      siliconeBarPrice: (json['siliconeBarPrice'] ?? 0).toDouble(),
      koreanPaperPrice: (json['koreanPaperPrice'] ?? 0).toDouble(),
      sticksPackPrice: (json['sticksPackPrice'] ?? 0).toDouble(),
      pearlsPackPrice: (json['pearlsPackPrice'] ?? 0).toDouble(),
      printingCost: (json['printingCost'] ?? 0).toDouble(),
      butterflyPackPrice: (json['butterflyPackPrice'] ?? 0).toDouble(),
      butterfliesPerPack: json['butterfliesPerPack'] ?? 0,
      flowerSettings: parsedMap,
    );
  }
}

class CalculationInput {
  Map<FlowerType, int> quantities;
  bool useKoreanPaper;
  int paperSheetsCount;
  bool useButterflies;
  int butterflyCount;
  bool useCrown;
  double crownCost;
  bool useCustomRibbon;
  double customRibbonCM;
  bool useAdditionalCosts;
  double additionalCosts;

  CalculationInput({
    required this.quantities,
    this.useKoreanPaper = false,
    this.paperSheetsCount = 0,
    this.useButterflies = false,
    this.butterflyCount = 0,
    this.useCrown = false,
    this.crownCost = 0.0,
    this.useCustomRibbon = false,
    this.customRibbonCM = 0.0,
    this.useAdditionalCosts = false,
    this.additionalCosts = 0.0,
  });
}

// ---------------------------------------------------------------------------
// STATE & LOGIC
// ---------------------------------------------------------------------------

class AppState extends ChangeNotifier {
  DatabaseSettings _settings = DatabaseSettings();
  bool _isLoading = true;
  bool _hasData = false;
  CalculationInput? currentInput;

  DatabaseSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get hasData => _hasData;

  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('creative_calc_settings_v1_1');
    
    if (data != null) {
      try {
        _settings = DatabaseSettings.fromJson(jsonDecode(data));
        _hasData = true;
      } catch (e) {
        _hasData = false;
      }
    } else {
      _hasData = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(DatabaseSettings newSettings) async {
    _settings = newSettings;
    _hasData = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('creative_calc_settings_v1_1', jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  void setCalculationInputs(CalculationInput input) {
    currentInput = input;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// UI HELPERS
// ---------------------------------------------------------------------------

class CommaTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    if (newText.contains(',')) {
      newText = newText.replaceAll(',', '.');
    }
    if ('.'.allMatches(newText).length > 1) {
       return oldValue;
    }
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CreativeBackground extends StatelessWidget {
  final Widget child;
  const CreativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFFFFF5F8), Color(0xFFF9A8D4)],
          center: Alignment.center,
          radius: 1.2,
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        elevation: 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isInteger;
  
  const CustomTextField({
    super.key, 
    required this.label, 
    required this.controller,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2D3436))),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(isInteger ? r'[0-9]' : r'[0-9.,]')),
              if (!isInteger) CommaTextInputFormatter(),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN SCREEN WRAPPER
// ---------------------------------------------------------------------------

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_appState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD81B60))));
    }
    return Scaffold(
      body: !_appState.hasData 
          ? DatabaseScreen(appState: _appState, isEditMode: false)
          : CalculatorScreen(appState: _appState),
      bottomNavigationBar: !_appState.hasData || _appState.isLoading ? null : Container(
        color: const Color(0xFFFFF5F8),
        padding: const EdgeInsets.all(16),
        child: const Text(
          "@Lanetting_ Creative Solutions 2026",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATABASE SCREEN
// ---------------------------------------------------------------------------

class DatabaseScreen extends StatefulWidget {
  final AppState appState;
  final bool isEditMode;
  const DatabaseScreen({super.key, required this.appState, this.isEditMode = true});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  // Mode selection
  String selectedSection = 'Globales';

  // Global Controllers
  final tapePriceCtrl = TextEditingController();
  final tapeLengthCtrl = TextEditingController();
  final siliconeBarPriceCtrl = TextEditingController();
  final koreanPaperPriceCtrl = TextEditingController();
  final sticksPackPriceCtrl = TextEditingController();
  final pearlsPackPriceCtrl = TextEditingController();
  final printingCostCtrl = TextEditingController();
  final butterflyPackPriceCtrl = TextEditingController();
  final butterfliesPerPackCtrl = TextEditingController();

  // Map of Map of Controllers for specific flowers [FlowerTypeString][Field]
  Map<String, Map<String, TextEditingController>> flowerCtrls = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final s = widget.appState.settings;
    
    // Globals
    tapePriceCtrl.text = _formatVal(s.tapePrice);
    tapeLengthCtrl.text = _formatVal(s.tapeLength);
    siliconeBarPriceCtrl.text = _formatVal(s.siliconeBarPrice);
    koreanPaperPriceCtrl.text = _formatVal(s.koreanPaperPrice);
    sticksPackPriceCtrl.text = _formatVal(s.sticksPackPrice);
    pearlsPackPriceCtrl.text = _formatVal(s.pearlsPackPrice);
    printingCostCtrl.text = _formatVal(s.printingCost);
    butterflyPackPriceCtrl.text = _formatVal(s.butterflyPackPrice);
    butterfliesPerPackCtrl.text = s.butterfliesPerPack.toString();

    // Specifics
    for (var type in FlowerType.values) {
      final key = type.toString();
      final setting = s.flowerSettings[key] ?? FlowerSettings();
      
      flowerCtrls[key] = {
        'cm': TextEditingController(text: _formatVal(setting.cmPerPetal)),
        'petals': TextEditingController(text: setting.petalsPerFlower.toString()),
        'silicone': TextEditingController(text: _formatVal(setting.siliconePerFlower)),
      };
    }
  }

  String _formatVal(double val) {
    if (val == 0) return "";
    return val.toString().replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
  }

  void _save() {
    // 1. Save Globals
    try {
      final newSettings = DatabaseSettings(
        tapePrice: double.tryParse(tapePriceCtrl.text) ?? 0,
        tapeLength: double.tryParse(tapeLengthCtrl.text) ?? 0,
        siliconeBarPrice: double.tryParse(siliconeBarPriceCtrl.text) ?? 0,
        koreanPaperPrice: double.tryParse(koreanPaperPriceCtrl.text) ?? 0,
        sticksPackPrice: double.tryParse(sticksPackPriceCtrl.text) ?? 0,
        pearlsPackPrice: double.tryParse(pearlsPackPriceCtrl.text) ?? 0,
        printingCost: double.tryParse(printingCostCtrl.text) ?? 0,
        butterflyPackPrice: double.tryParse(butterflyPackPriceCtrl.text) ?? 0,
        butterfliesPerPack: int.tryParse(butterfliesPerPackCtrl.text) ?? 0,
      );

      // 2. Save Specifics
      flowerCtrls.forEach((key, ctrls) {
        newSettings.flowerSettings[key] = FlowerSettings(
          cmPerPetal: double.tryParse(ctrls['cm']!.text) ?? 0,
          petalsPerFlower: int.tryParse(ctrls['petals']!.text) ?? 0,
          siliconePerFlower: double.tryParse(ctrls['silicone']!.text) ?? 0,
        );
      });

      // Basic Validation
      if (newSettings.tapePrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El precio de la cinta es obligatorio.')));
        return;
      }

      widget.appState.saveSettings(newSettings);
      
      if (widget.isEditMode && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar. Revisa los números.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = ['Globales', ...FlowerType.values.map((e) => flowerTypeLabels[e]!)];

    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          value: selectedSection,
          dropdownColor: Colors.white,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD81B60)),
          style: const TextStyle(color: Color(0xFFD81B60), fontSize: 20, fontWeight: FontWeight.bold),
          onChanged: (String? newValue) {
            setState(() {
              selectedSection = newValue!;
            });
          },
          items: menuItems.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: widget.isEditMode ? const BackButton(color: Colors.black) : null,
      ),
      body: CreativeBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (selectedSection == 'Globales') ...[
                    _buildSectionHeader("Materiales Generales"),
                    CustomTextField(label: 'Precio de la Cinta (\$)', controller: tapePriceCtrl),
                    CustomTextField(label: 'Largo de Cinta (Metros)', controller: tapeLengthCtrl),
                    CustomTextField(label: 'Precio Barra Silicón (\$)', controller: siliconeBarPriceCtrl),
                    CustomTextField(label: 'Precio Papel Coreano (\$)', controller: koreanPaperPriceCtrl),
                    CustomTextField(label: 'Precio Paquete Palitos (\$)', controller: sticksPackPriceCtrl),
                    CustomTextField(label: 'Precio Paquete Perlas (\$)', controller: pearlsPackPriceCtrl),
                    const SizedBox(height: 20),
                    _buildSectionHeader("Adicionales"),
                    CustomTextField(label: 'Costo de Impresión (\$)', controller: printingCostCtrl),
                    CustomTextField(label: 'Precio Paquete Mariposas (\$)', controller: butterflyPackPriceCtrl),
                    CustomTextField(label: 'Mariposas por Paquete', controller: butterfliesPerPackCtrl, isInteger: true),
                  ] else ...[
                     _buildFlowerInputs(selectedSection),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(label: 'Guardar Configuración', icon: Icons.save, onPressed: _save),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
    );
  }

  Widget _buildFlowerInputs(String label) {
    // Find enum from label
    final typeEntry = flowerTypeLabels.entries.firstWhere((e) => e.value == label);
    final key = typeEntry.key.toString();
    final ctrls = flowerCtrls[key]!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text("Configuración específica para $label", style: const TextStyle(fontSize: 14, color: Color(0xFFD81B60))),
        ),
        CustomTextField(label: 'CM de Cinta por Pétalo', controller: ctrls['cm']!),
        CustomTextField(label: 'Pétalos por Flor (Entero)', controller: ctrls['petals']!, isInteger: true),
        CustomTextField(label: 'Silicón por Flor (Barra)', controller: ctrls['silicone']!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CALCULATOR SCREEN
// ---------------------------------------------------------------------------

class CalculatorScreen extends StatefulWidget {
  final AppState appState;
  const CalculatorScreen({super.key, required this.appState});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Quantities Map
  Map<FlowerType, int> quantities = {
    for (var t in FlowerType.values) t: 0
  };

  // Controllers for direct numeric input
  final Map<FlowerType, TextEditingController> _qtyControllers = {};

  // Optionals
  bool useKoreanPaper = false;
  final papersCtrl = TextEditingController();
  
  bool useButterflies = false;
  final butterflyCountCtrl = TextEditingController();

  bool useCrown = false;
  final crownCostCtrl = TextEditingController();

  bool useCustomRibbon = false;
  final customRibbonCMCtrl = TextEditingController();

  bool useAdditionalCosts = false;
  final additionalCostsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with "0"
    for (var t in FlowerType.values) {
      _qtyControllers[t] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateQuantity(FlowerType type, int newValue) {
    if (newValue < 0) return;
    setState(() {
      quantities[type] = newValue;
      // Update text field if the value differs to avoid cursor issues,
      // but strictly needed for +/- buttons
      if (_qtyControllers[type]!.text != newValue.toString()) {
        _qtyControllers[type]!.text = newValue.toString();
      }
    });
  }

  void _calculate() {
    int totalItems = quantities.values.fold(0, (sum, val) => sum + val);
    
    if (totalItems == 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos una flor.')));
       return;
    }

    final input = CalculationInput(
      quantities: quantities,
      useKoreanPaper: useKoreanPaper,
      paperSheetsCount: useKoreanPaper ? (int.tryParse(papersCtrl.text) ?? 0) : 0,
      useButterflies: useButterflies,
      butterflyCount: useButterflies ? (int.tryParse(butterflyCountCtrl.text) ?? 0) : 0,
      useCrown: useCrown,
      crownCost: useCrown ? (double.tryParse(crownCostCtrl.text.replaceAll(',', '.')) ?? 0) : 0,
      useCustomRibbon: useCustomRibbon,
      customRibbonCM: useCustomRibbon ? (double.tryParse(customRibbonCMCtrl.text.replaceAll(',', '.')) ?? 0) : 0,
      useAdditionalCosts: useAdditionalCosts,
      additionalCosts: useAdditionalCosts ? (double.tryParse(additionalCostsCtrl.text.replaceAll(',', '.')) ?? 0) : 0,
    );
    
    widget.appState.setCalculationInputs(input);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CalculatingScreen(appState: widget.appState)));
  }

  Widget _buildCheckField({required String label, required bool value, required Function(bool?) onChanged, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white)),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
            value: value,
            activeColor: const Color(0xFFD81B60),
            onChanged: onChanged,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          if (value) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calculadora Creativa', style: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFD81B60)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DatabaseScreen(appState: widget.appState)));
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CreativeBackground(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 60),
            const Text('Nueva Cuenta', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
            const SizedBox(height: 8),
            const Text('Selecciona cantidades por tipo', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2D3436))),
            const SizedBox(height: 20),
            
            // Grid of Flowers
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: FlowerType.values.length,
              itemBuilder: (context, index) {
                final type = FlowerType.values[index];
                final qty = quantities[type]!;
                return Container(
                  decoration: BoxDecoration(
                    color: qty > 0 ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: qty > 0 ? Border.all(color: const Color(0xFFD81B60), width: 2) : Border.all(color: Colors.transparent),
                    boxShadow: qty > 0 ? [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.2), blurRadius: 4)] : [],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(flowerTypeLabels[type]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _updateQuantity(type, qty - 1),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.remove_circle_outline, color: Color(0xFFD81B60), size: 28),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // REPLACED TEXT WITH TEXTFIELD
                          SizedBox(
                            width: 50,
                            child: TextField(
                              controller: _qtyControllers[type],
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  setState(() { quantities[type] = 0; });
                                  return;
                                }
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  setState(() { quantities[type] = parsed; });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _updateQuantity(type, qty + 1),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.add_circle, color: Color(0xFFD81B60), size: 28),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _buildCheckField(
              label: "¿Ocupa papel coreano?",
              value: useKoreanPaper,
              onChanged: (v) => setState(() => useKoreanPaper = v!),
              child: CustomTextField(label: 'Cantidad de Pliegos', controller: papersCtrl, isInteger: true),
            ),

            _buildCheckField(
              label: "¿Ocupa mariposas?",
              value: useButterflies,
              onChanged: (v) => setState(() => useButterflies = v!),
              child: CustomTextField(label: 'Número de Mariposas', controller: butterflyCountCtrl, isInteger: true),
            ),

            _buildCheckField(
              label: "¿Ocupa corona?",
              value: useCrown,
              onChanged: (v) => setState(() => useCrown = v!),
              child: CustomTextField(label: 'Costo de Corona (\$)', controller: crownCostCtrl),
            ),

            _buildCheckField(
              label: "¿Ocupa cinta personalizada?",
              value: useCustomRibbon,
              onChanged: (v) => setState(() => useCustomRibbon = v!),
              child: CustomTextField(label: 'CM de Cinta', controller: customRibbonCMCtrl),
            ),

            _buildCheckField(
              label: "¿Ocupa costos adicionales?",
              value: useAdditionalCosts,
              onChanged: (v) => setState(() => useAdditionalCosts = v!),
              child: CustomTextField(label: 'Costos Adicionales (\$)', controller: additionalCostsCtrl),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: 'Calcular', icon: Icons.calculate, onPressed: _calculate),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RESULTS SCREEN
// ---------------------------------------------------------------------------

class CalculatingScreen extends StatefulWidget {
  final AppState appState;
  const CalculatingScreen({super.key, required this.appState});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultsScreen(appState: widget.appState)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CreativeBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD81B60)),
              const SizedBox(height: 24),
              Text('calculando...', style: GoogleFonts.nunitoSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFD81B60), letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final AppState appState;
  const ResultsScreen({super.key, required this.appState});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  // Helper to generate decoration list
  List<String> getDecorationItems(CalculationInput i) {
    List<String> parts = [];
    if (i.useCrown) parts.add("Corona");
    if (i.useButterflies) parts.add("Mariposas");
    if (i.useKoreanPaper) parts.add("Papel Coreano");
    if (i.useCustomRibbon) parts.add("Cinta Personalizada");
    return parts;
  }

  Future<void> _shareImage(double suggestedPrice, CalculationInput inputs) async {
    try {
      final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
      
      final decorationItems = getDecorationItems(inputs);

      final widgetToCapture = Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            color: const Color(0xFFFFF5F8),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Manos Creativas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
                  const Text("Presupuesto Estimado", style: TextStyle(color: Colors.grey)),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  const Text("Precio de Referencia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  // Updated: Center alignment for price text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFD81B60), borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text(currency.format(suggestedPrice), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text("Detalles del Arreglo", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
                        const Divider(),
                        
                        // Flowers
                        ...FlowerType.values.where((t) => inputs.quantities[t]! > 0).map((t) {
                          return _buildShareRow(flowerTypeLabels[t]!, "${inputs.quantities[t]} pzas");
                        }),

                        // Grouped Decorations - Invisible Table Layout
                        if (decorationItems.isNotEmpty) ...[
                           const SizedBox(height: 12),
                           Row(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text("Decoraciones", style: TextStyle(fontSize: 12)),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.end,
                                 children: decorationItems.map((item) => Padding(
                                   padding: const EdgeInsets.only(bottom: 2),
                                   child: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                 )).toList(),
                               )
                             ],
                           )
                        ],

                        if (inputs.useAdditionalCosts) ...[
                          const SizedBox(height: 8),
                          _buildShareRow("Extras", currency.format(inputs.additionalCosts)),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("¡Gracias por confiar en Manos Creativas!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
                  const Text("Síguenos como @manoscreativas.arr en todas las redes", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );

      final Uint8List capturedImage = await screenshotController.captureFromWidget(
        widgetToCapture,
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileDate = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final imagePath = '${directory.path}/Presupuesto_Manos_Creativas_$fileDate.png';
      final file = File(imagePath);
      await file.writeAsBytes(capturedImage);

      await Share.shareXFiles([XFile(imagePath)], text: 'Presupuesto Manos Creativas');

    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  Widget _buildShareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Increased padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.appState.settings;
    final inputs = widget.appState.currentInput!;

    // Math Logic v1.1.2
    final costStick = s.sticksPackPrice / 100;
    final costPearl = s.pearlsPackPrice / 100;
    final costPerMeter = s.tapePrice / s.tapeLength;
    final costButterflyUnit = (s.butterfliesPerPack > 0) ? s.butterflyPackPrice / s.butterfliesPerPack : 0.0;

    double totalFlowersCost = 0;
    double totalSiliconeCost = 0;
    double totalStickCost = 0;
    double totalPearlCost = 0;
    int totalFlowerCount = 0;

    inputs.quantities.forEach((type, qty) {
      if (qty > 0) {
        totalFlowerCount += qty;
        final key = type.toString();
        final config = s.flowerSettings[key]!;
        
        // Flower Base
        final metersPerPetal = config.cmPerPetal / 100;
        final costPetal = costPerMeter * metersPerPetal;
        final costOneFlower = (costPetal * config.petalsPerFlower);
        totalFlowersCost += (costOneFlower * qty);
        
        // Silicone
        totalSiliconeCost += (config.siliconePerFlower * s.siliconeBarPrice * qty);

        // Sticks & Pearls (Apply stick to all, Pearl to all except leaf if desired, but sticking to prompt logic)
        totalStickCost += (costStick * qty);
        if (type != FlowerType.LEAF) {
           totalPearlCost += (costPearl * qty);
        }
      }
    });
    
    final totalPaperCost = (inputs.useKoreanPaper ? inputs.paperSheetsCount : 0) * s.koreanPaperPrice;
    final totalButterflyCost = (inputs.useButterflies ? inputs.butterflyCount : 0) * costButterflyUnit;
    
    final ribbonCM = inputs.useCustomRibbon ? inputs.customRibbonCM : 0;
    final printing = inputs.useCustomRibbon ? s.printingCost : 0;
    final ribbonCost = ((ribbonCM / 100) * costPerMeter) + printing;

    final crown = inputs.useCrown ? inputs.crownCost : 0;
    final additional = inputs.useAdditionalCosts ? inputs.additionalCosts : 0;

    final arrangementCost = totalFlowersCost + totalPearlCost + totalStickCost + totalSiliconeCost + 
                            totalPaperCost + totalButterflyCost + crown + ribbonCost + additional;
    
    final services = arrangementCost * 0.15;
    final labor = (totalFlowerCount * 6) / 60;
    final profit = (arrangementCost + services + labor) * 0.5;
    final suggestedPrice = arrangementCost + services + labor + profit;

    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');

    return Scaffold(
      body: CreativeBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(child: Text("Precio de Referencia", style: TextStyle(fontSize: 18, color: Color(0xFF2D3436)))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD81B60),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(
                    currency.format(suggestedPrice),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Desglose Financiero", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                            const Divider(),
                            _buildRow("Costo del Arreglo", currency.format(arrangementCost), isBold: true),
                            const Divider(),
                            _buildRow("Servicios (15%)", currency.format(services)),
                            _buildRow("Mano de Obra", currency.format(labor)),
                            Text("Basado en ${(totalFlowerCount * 6) / 60} horas", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            _buildRow("Ganancia (50%)", currency.format(profit), color: const Color(0xFFD81B60)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Materiales", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                            const SizedBox(height: 8),
                            
                            ...FlowerType.values.where((t) => inputs.quantities[t]! > 0).map((t) {
                               return _buildRow(flowerTypeLabels[t]!, "${inputs.quantities[t]}");
                            }),

                            // RESTORED UI ROWS FOR DETAILS
                            if (inputs.useKoreanPaper) _buildRow("Papel Coreano", "${inputs.paperSheetsCount} pliegos"),
                            if (inputs.useButterflies) _buildRow("Mariposas", "${inputs.butterflyCount} pzas"),
                            if (inputs.useCrown) _buildRow("Corona", currency.format(inputs.crownCost)),
                            if (inputs.useCustomRibbon) _buildRow("Cinta Personalizada", "${inputs.customRibbonCM} cm"),
                            if (inputs.useAdditionalCosts) _buildRow("Adicionales", currency.format(inputs.additionalCosts)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _shareImage(suggestedPrice, inputs),
                icon: const Icon(Icons.share),
                label: const Text("Compartir"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Hacer otra cuenta"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD81B60),
                  side: const BorderSide(color: Color(0xFFD81B60), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? const Color(0xFF2D3436))),
          Text(value, style: TextStyle(fontSize: isBold ? 20 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? const Color(0xFF2D3436))),
        ],
      ),
    );
  }
}