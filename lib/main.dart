  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:image_picker/image_picker.dart';
  import 'package:intl/intl.dart';
  import 'package:pdf/pdf.dart';
  import 'package:pdf/widgets.dart' as pw;
  import 'package:path_provider/path_provider.dart';
  import 'package:printing/printing.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:flutter/services.dart';

  void main() => runApp(const ChapelApp());

  class ChapelApp extends StatelessWidget {
    const ChapelApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Chapel Tech Survey',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            primary: const Color(0xFF0D47A1),
            secondary: const Color(0xFFFFD600),
          ),
          textTheme: GoogleFonts.interTextTheme(),
        ),
        home: const ChapelFormScreen(),
      );
    }
  }

  class ChapelFormScreen extends StatefulWidget {
    const ChapelFormScreen({super.key});

    @override
    State<ChapelFormScreen> createState() => _ChapelFormScreenState();
  }

  class _ChapelFormScreenState extends State<ChapelFormScreen> {
    final _formKey = GlobalKey<FormState>();
    final ImagePicker _picker = ImagePicker();

    // --- Form Data ---
    String _currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    final TextEditingController _distritoController = TextEditingController();
    final TextEditingController _lokalController = TextEditingController();
    final TextEditingController _capacityController = TextEditingController();
    final TextEditingController _surveyorController = TextEditingController();
    String _chapelType = 'Standard';
    final TextEditingController _roomCurrentLocController = TextEditingController();
    final TextEditingController _roomRecController = TextEditingController();
    bool _hasTsvPanel = false;
    bool _hasCctv = false;
    final TextEditingController _cctvBrandModelController = TextEditingController();
    String _cameraType = 'Analog';
    final TextEditingController _cameraCountController = TextEditingController();

    final List<String> _photoRequirements = [
      "TSV Room", "Front of Chapel", "Entrance Gate", "Exit Gate", "Service Entrance",
      "Guard Post", "Generator House", "Male Side Driveway at Parking",
      "Female Side Driveway at Parking", "Rear Compound Driveway at Parking",
      "Arcade Porch", "Pastoral House", "Local Offices", "Office of the Resident Minister",
      "Receiving Room", "Main Nave", "Balcony", "Main Nave from Balcony/Rear Wall",
      "Kapulungan Shot (Female Side)", "Kapulungan Shot (Male Side)", "Lobby",
      "Conference Room", "Multipurpose Room", "Storage Room", "Electrical Room/Panel Board",
      "Male Dressing Room", "Female Dressing Room", "Secretariat Office",
      "Ilaw Office", "Finance Room", "P-9 Office (Lagakan)", "Hallways"
    ];

    final Map<String, XFile> _capturedPhotos = {};

    Future<void> _pickImage(String requirement, ImageSource source) async {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _capturedPhotos[requirement] = image;
        });
      }
    }

    Future<pw.MemoryImage> _getImage(XFile xFile) async {
      final bytes = await xFile.readAsBytes();
      return pw.MemoryImage(bytes);
    }

    Future<void> _generatePdf() async {
      final pdf = pw.Document();
      final navyBlue = PdfColors.blue900;

      // FOLIO SIZE (8.5" x 13")
      final folioFormat = PdfPageFormat(8.5 * PdfPageFormat.inch, 13 * PdfPageFormat.inch);
      final pageMargin = const pw.EdgeInsets.all(PdfPageFormat.inch * 0.5);

      pw.MemoryImage? logoImage;
      try {
        final byteData = await rootBundle.load('assets/TSV_LOGO1-removebg-preview.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint("Logo not found: $e");
      }

      final headerStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: navyBlue);
      final labelStyle = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700);
      final valueStyle = pw.TextStyle(fontSize: 11, color: PdfColors.black);

      // --- PAGE 1: DATA SUMMARY ---
      pdf.addPage(
        pw.Page(
          pageFormat: folioFormat,
          margin: pageMargin,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null) pw.Image(logoImage, width: 180, height: 50, fit: pw.BoxFit.contain),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("TECHNICAL SURVEY REPORT", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text("TRG-TSV", style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: navyBlue, thickness: 2),
                pw.SizedBox(height: 20),
                pw.Text("I. GENERAL INFORMATION", style: headerStyle),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _pdfRow("Date of Survey", _currentDate, labelStyle, valueStyle),
                    _pdfRow("Distrito", _distritoController.text, labelStyle, valueStyle),
                    _pdfRow("Lokal", _lokalController.text, labelStyle, valueStyle),
                    _pdfRow("Seating Capacity", _capacityController.text, labelStyle, valueStyle),
                    _pdfRow("Chapel Type", _chapelType, labelStyle, valueStyle),
                    _pdfRow("Surveyor", _surveyorController.text, labelStyle, valueStyle),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text("II. TECHNICAL SPECIFICATIONS", style: headerStyle),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _pdfRow("TSV Room Location", _roomCurrentLocController.text, labelStyle, valueStyle),
                    _pdfRow("Recommendation", _roomRecController.text, labelStyle, valueStyle),
                    _pdfRow("TSV Panel Present", _hasTsvPanel ? "YES" : "NO", labelStyle, valueStyle),
                    _pdfRow("CCTV System Present", _hasCctv ? "YES" : "NO", labelStyle, valueStyle),
                    if (_hasCctv) ...[
                      _pdfRow("CCTV Brand/Model", _cctvBrandModelController.text, labelStyle, valueStyle),
                      _pdfRow("Camera Type", _cameraType, labelStyle, valueStyle),
                      _pdfRow("Total Camera Count", _cameraCountController.text, labelStyle, valueStyle),
                    ],
                  ],
                ),
                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(width: 200, child: pw.Divider(thickness: 1)),
                        pw.Text(_surveyorController.text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Surveyor Signature over Printed Name", style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // --- PHOTO PAGES: 2 PHOTOS PER PAGE ---
      List<String> activePhotos = _photoRequirements.where((req) => _capturedPhotos.containsKey(req)).toList();

      for (int i = 0; i < activePhotos.length; i += 2) {
        String req1 = activePhotos[i];
        final img1 = await _getImage(_capturedPhotos[req1]!);

        String? req2;
        pw.MemoryImage? img2;
        if (i + 1 < activePhotos.length) {
          req2 = activePhotos[i + 1];
          img2 = await _getImage(_capturedPhotos[req2]!);
        }

        pdf.addPage(
          pw.Page(
            pageFormat: folioFormat,
            margin: pageMargin,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text("DOCUMENTATION: $req1", style: headerStyle),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: navyBlue, width: 1)),
                          child: pw.Image(img1, width: 480, height: 300, fit: pw.BoxFit.fill),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  if (req2 != null && img2 != null)
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text("DOCUMENTATION: $req2", style: headerStyle),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            decoration: pw.BoxDecoration(border: pw.Border.all(color: navyBlue, width: 1)),
                            child: pw.Image(img2, width: 480, height: 300, fit: pw.BoxFit.fill),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }

      String district = _distritoController.text.trim();
      String lokal = _lokalController.text.trim();
      String fileName = (district.isNotEmpty && lokal.isNotEmpty)
          ? "${district}_${lokal}.pdf"
          : "Chapel_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: fileName);
      } else {
        final output = await getApplicationDocumentsDirectory();
        final file = File("${output.path}/$fileName");
        await file.writeAsBytes(await pdf.save());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Saved as $fileName")));
      }
    }

    pw.TableRow _pdfRow(String label, String value, pw.TextStyle lStyle, pw.TextStyle vStyle) {
      return pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label, style: lStyle)),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value, style: vStyle)),
        ],
      );
    }

    void _submitForm() {
      if (_formKey.currentState!.validate()) {
        _generatePdf();
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text("CCTV Site Survey", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/TSV_LOGO1-removebg-preview.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              _buildModernSection("General Information", const Color(0xFF0D47A1), [
                _buildTextField(_distritoController, "District Name", Icons.location_city),
                _buildTextField(_lokalController, "Lokal Name", Icons.home),
                _buildTextField(_capacityController, "Seating Capacity", Icons.people, isNumber: true),
                _buildTextField(_surveyorController, "Surveyor's Full Name", Icons.person),
                _buildDropdown("Chapel Type", ['Standard', 'Large', 'Small', 'Special'], _chapelType, (val) => setState(() => _chapelType = val!)),
                _buildReadOnlyField(_currentDate, "Date of Survey", Icons.calendar_today),
              ]),
              const SizedBox(height: 25),
              _buildModernSection("TSV & CCTV Audit", const Color(0xFF2E7D32), [
                _buildTextField(_roomCurrentLocController, "TSV Room Current Location", Icons.settings_input_component),
                _buildTextField(_roomRecController, "Room Recommendation", Icons.edit_note),
                _buildModernSwitch("Is there TSV Panel?", _hasTsvPanel, (val) => setState(() => _hasTsvPanel = val!)),
                _buildModernSwitch("Is there existing CCTV System?", _hasCctv, (val) => setState(() => _hasCctv = val!)),
                if (_hasCctv) ...[
                  _buildTextField(_cctvBrandModelController, "CCTV Brand & Model", Icons.business),
                  _buildDropdown("Camera Type", ['Analog', 'IP'], _cameraType, (val) => setState(() => _cameraType = val!)),
                  _buildTextField(_cameraCountController, "Number of Cameras", Icons.camera, isNumber: true),
                ],
              ]),
              const SizedBox(height: 25),
              _buildModernSection("Photo Documentation", const Color(0xFFC62828), [
                ..._photoRequirements.map((req) => PhotoUploadCard(
                  requirement: req,
                  imagePath: _capturedPhotos[req]?.path,
                  onCamera: () => _pickImage(req, ImageSource.camera),
                  onGallery: () => _pickImage(req, ImageSource.gallery),
                )).toList(),
              ]),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: const Text("GENERATE OFFICIAL REPORT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      );
    }

    Widget _buildModernSection(String title, Color color, List<Widget> children) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: children),
            ),
          ],
        ),
      );
    }

    Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
          ),
        ),
      );
    }

    Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: DropdownButtonFormField<String>(
          value: value,
          items: options.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    Widget _buildReadOnlyField(String value, String label, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    Widget _buildModernSwitch(String label, bool value, Function(bool) onChanged) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SwitchListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  class PhotoUploadCard extends StatelessWidget {
    final String requirement;
    final String? imagePath;
    final VoidCallback onCamera;
    final VoidCallback onGallery;

    const PhotoUploadCard({super.key, required this.requirement, this.imagePath, required this.onCamera, required this.onGallery});

    @override
    Widget build(BuildContext context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(15),
          color: imagePath != null ? Colors.green[50] : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(requirement, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(imagePath != null ? "✓ Captured" : "Pending", style: TextStyle(color: imagePath != null ? Colors.green[700] : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            IconButton(onPressed: onCamera, icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D47A1))),
            IconButton(onPressed: onGallery, icon: const Icon(Icons.image_outlined, color: Color(0xFF0D47A1))),
          ],
        ),
      );
    }
  }