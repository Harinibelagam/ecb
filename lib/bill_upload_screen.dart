// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// class BillUploadScreen extends StatefulWidget {
//   const BillUploadScreen({super.key});

//   @override
//   State<BillUploadScreen> createState() => _BillUploadScreenState();
// }

// class _BillUploadScreenState extends State<BillUploadScreen> {
//   File? _selectedImage;
//   double? _billAmount;
//   String? _selectedTicket;
//   String? _suggestedTicket;
//   double? _ticketCost;
//   String? _errorMessage;
//   bool _agreedToTerms = false;

//   final Map<String, Map<String, double>> tickets = {
//     'T1': {'min': 0.0, 'max': 2500.0, 'cost': 15.0},
//     'T2': {'min': 2501.0, 'max': 5000.0, 'cost': 25.0},
//     'T3': {'min': 5001.0, 'max': 7500.0, 'cost': 35.0},
//     'T4': {'min': 7501.0, 'max': 10000.0, 'cost': 45.0},
//   };

//   // ----------------- pick image -----------------
//   Future<void> _pickImage() async {
//     if (_selectedTicket == null) {
//       setState(() {
//         _errorMessage = "⚠️ Please select a ticket first.";
//       });
//       return;
//     }

//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked == null) return;

//     setState(() {
//       _selectedImage = File(picked.path);
//       _billAmount = null;
//       _ticketCost = null;
//       _suggestedTicket = null;
//       _errorMessage = null;
//     });

//     await _extractBillAmount(File(picked.path));
//   }

//   // ----------------- OCR extraction -----------------
//   Future<void> _extractBillAmount(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);
//     final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
//     final RecognizedText recognizedText =
//         await textRecognizer.processImage(inputImage);
//     await textRecognizer.close();

//     final regex = RegExp(r'(?:₹|Rs\.?\s?)?[\d,]+(?:\.\d{1,2})?');
//     final List<double> candidates = [];

//     for (final block in recognizedText.blocks) {
//       for (final line in block.lines) {
//         final matches = regex.allMatches(line.text);
//         for (final match in matches) {
//           final raw = match.group(0) ?? '';
//           final clean = raw.replaceAll(RegExp(r'[^\d.]'), '');
//           final value = double.tryParse(clean);
//           if (value != null && value > 0 && value <= 100000) {
//             candidates.add(value);
//           }
//         }
//       }
//     }

//     if (candidates.isEmpty) {
//       setState(() {
//         _billAmount = null;
//         _ticketCost = null;
//         _suggestedTicket = null;
//         _errorMessage = "❌ Could not detect any valid bill amount in image.";
//       });
//     } else {
//       candidates.sort((a, b) => b.compareTo(a)); 
//       setState(() {
//         _billAmount = candidates.first;
//         _errorMessage = null;
//       });
//       _validateBillAmount();
//     }
//   }

//   // ----------------- validate -----------------
//   void _validateBillAmount() {
//     if (_billAmount == null) return;

//     String? found;
//     for (final entry in tickets.entries) {
//       final key = entry.key;
//       final min = entry.value['min']!;
//       final max = entry.value['max']!;
//       if (_billAmount! >= min && _billAmount! <= max) {
//         found = key;
//         break;
//       }
//     }

//     setState(() {
//       _suggestedTicket = found;
//     });

//     if (_selectedTicket == null) {
//       setState(() {
//         _ticketCost = null;
//         _errorMessage =
//             '⚠️ Please select a ticket (suggested: ${found ?? "none"}).';
//       });
//       return;
//     }

//     final min = tickets[_selectedTicket]!['min']!;
//     final max = tickets[_selectedTicket]!['max']!;
//     final cost = tickets[_selectedTicket]!['cost']!;

//     if (_billAmount! < min || _billAmount! > max) {
//       setState(() {
//         _errorMessage =
//             '❌ Detected ₹${_billAmount!.toInt()} does NOT match $_selectedTicket (allowed ₹${min.toInt()} - ₹${max.toInt()}). Suggested: ${found ?? "none"}.';
//         _ticketCost = null;
//       });
//     } else {
//       setState(() {
//         _errorMessage = null;
//         _ticketCost = cost;
//       });
//     }
//   }

//   // ----------------- actions -----------------
//   void _selectTicket(String ticket) {
//     setState(() {
//       _selectedTicket = ticket;
//       _billAmount = null;
//       _ticketCost = null;
//       _errorMessage = null;
//       _selectedImage = null;
//       _suggestedTicket = null;
//     });
//   }

//   void _applySuggestedTicket() {
//     if (_suggestedTicket == null) return;
//     setState(() {
//       _selectedTicket = _suggestedTicket;
//       _validateBillAmount();
//     });
//   }

//   void _submit() {
//     if (_selectedTicket == null ||
//         _selectedImage == null ||
//         _billAmount == null ||
//         _errorMessage != null ||
//         !_agreedToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("⚠️ Please complete all steps and agree to Terms."),
//         backgroundColor: Colors.red,
//       ));
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(
//           "✅ Submitted! Ticket: $_selectedTicket, Bill: ₹${_billAmount!.toInt()}, Cost: ₹${_ticketCost!.toInt()}"),
//       backgroundColor: Colors.green,
//     ));
//   }

//   void _logout() {
//     // Example: Navigate back to login or exit
//     Navigator.of(context).pop();
//   }

//   void _showFullImage(File image) {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: GestureDetector(
//           onTap: () => Navigator.of(context).pop(),
//           child: InteractiveViewer(
//             child: Image.file(image, fit: BoxFit.contain),
//           ),
//         ),
//       ),
//     );
//   }

//   // ----------------- UI -----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue.shade50,
//       appBar: AppBar(
//         title: const Text('💰 Earn Cash Back'),
//         centerTitle: true,
//         elevation: 4,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//             tooltip: 'Logout',
//           )
//         ],
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.blue, Colors.purple],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               elevation: 5,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("🎟️ Select Ticket",
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 8,
//                       children: tickets.keys.map((t) {
//                         final selected = _selectedTicket == t;
//                         return ChoiceChip(
//                           label: Text(t),
//                           selected: selected,
//                           onSelected: (_) => _selectTicket(t),
//                           selectedColor: Colors.purple,
//                           backgroundColor: Colors.grey.shade200,
//                           labelStyle: TextStyle(
//                             color: selected ? Colors.white : Colors.black,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _pickImage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//               ),
//               icon: const Icon(Icons.photo, size: 22),
//               label: const Text('Upload Bill Image',
//                   style: TextStyle(fontSize: 16)),
//             ),
//             const SizedBox(height: 16),
//             if (_selectedImage != null)
//               GestureDetector(
//                 onTap: () => _showFullImage(_selectedImage!),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: Image.file(_selectedImage!,
//                       height: 220, fit: BoxFit.cover),
//                 ),
//               ),
//             const SizedBox(height: 16),
//             if (_errorMessage != null)
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade100,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(_errorMessage!,
//                     style: const TextStyle(
//                         color: Colors.red, fontWeight: FontWeight.w600)),
//               ),
//             if (_billAmount != null && _errorMessage == null) ...[
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     children: [
//                       Text("✅ Bill Amount: ₹${_billAmount!.toInt()}",
//                           style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green)),
//                       if (_ticketCost != null)
//                         Text("🎟️ Ticket Cost: ₹${_ticketCost!.toInt()}",
//                             style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue)),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             if (_suggestedTicket != null &&
//                 _selectedTicket != _suggestedTicket) ...[
//               const SizedBox(height: 10),
//               Text("💡 Suggested Ticket: $_suggestedTicket",
//                   style: const TextStyle(fontWeight: FontWeight.w600)),
//               const SizedBox(height: 6),
//               OutlinedButton(
//                   onPressed: _applySuggestedTicket,
//                   style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Colors.purple),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12))),
//                   child: Text('Switch to $_suggestedTicket')),
//             ],
//             const Divider(height: 32, thickness: 1),
//             CheckboxListTile(
//               title: const Text("I agree to Terms & Conditions"),
//               activeColor: Colors.purple,
//               value: _agreedToTerms,
//               onChanged: (val) =>
//                   setState(() => _agreedToTerms = val ?? false),
//             ),
//             ExpansionTile(
//               title: const Text("📄 View Terms & Conditions",
//                   style: TextStyle(fontWeight: FontWeight.w600)),
//               children: const [
//                 Padding(
//                   padding: EdgeInsets.all(12.0),
//                   child: Text(
//                     "1. The uploaded bill must be authentic.\n"
//                     "2. Only PhonePe / UPI screenshots are accepted.\n"
//                     "3. Ticket selection must match bill amount range.\n"
//                     "4. Submissions without agreement will be rejected.",
//                     style: TextStyle(fontSize: 14),
//                   ),
//                 )
//               ],
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _submit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 55),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14)),
//               ),
//               child: const Text('Submit',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BillUploadScreen extends StatefulWidget {
  const BillUploadScreen({super.key});

  @override
  State<BillUploadScreen> createState() => _BillUploadScreenState();
}

class _BillUploadScreenState extends State<BillUploadScreen> {
  File? _selectedImage;
  double? _billAmount;
  String? _selectedTicket;
  double? _ticketCost;
  String? _errorMessage;
  String? _suggestedTicket;
  bool _agreedToTerms = false;

  final TextEditingController _manualAmountController = TextEditingController();

  final Map<String, Map<String, double>> tickets = {
    'T1': {'min': 0.0, 'max': 2500.0, 'cost': 15.0},
    'T2': {'min': 2501.0, 'max': 5000.0, 'cost': 25.0},
    'T3': {'min': 5001.0, 'max': 7500.0, 'cost': 35.0},
    'T4': {'min': 7501.0, 'max': 10000.0, 'cost': 45.0},
  };

  // ----------------- pick image -----------------
  Future<void> _pickImage() async {
    if (_selectedTicket == null) {
      setState(() {
        _errorMessage = "⚠️ Please select a ticket first.";
      });
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _errorMessage = null;
    });
  }

  // ----------------- manual bill entry -----------------
  void _setManualBillAmount() {
    final input = _manualAmountController.text.trim();
    if (input.isEmpty) return;

    final value = double.tryParse(input);
    if (value == null || value <= 0) {
      setState(() {
        _errorMessage = "❌ Invalid manual amount entered.";
        _billAmount = null;
        _ticketCost = null;
        _suggestedTicket = null;
      });
      return;
    }

    setState(() {
      _billAmount = value;
      _errorMessage = null;
      _suggestedTicket = null;
    });
    _validateBillAmount();
  }

  // ----------------- validate -----------------
  void _validateBillAmount() {
    if (_billAmount == null || _selectedTicket == null) return;

    final min = tickets[_selectedTicket]!['min']!;
    final max = tickets[_selectedTicket]!['max']!;
    final cost = tickets[_selectedTicket]!['cost']!;

    if (_billAmount! < min || _billAmount! > max) {
      // Find correct ticket suggestion
      String? suggestion;
      for (var entry in tickets.entries) {
        final tMin = entry.value['min']!;
        final tMax = entry.value['max']!;
        if (_billAmount! >= tMin && _billAmount! <= tMax) {
          suggestion = entry.key;
          break;
        }
      }

      setState(() {
        _errorMessage =
            '❌ Entered ₹${_billAmount!.toInt()} does NOT match $_selectedTicket (₹${min.toInt()} - ₹${max.toInt()}).'
            '\n👉 This bill suits ${suggestion ?? "no available ticket"}.';
        _ticketCost = null;
        _suggestedTicket = suggestion;
      });
    } else {
      setState(() {
        _errorMessage = null;
        _ticketCost = cost;
        _suggestedTicket = null;
      });
    }
  }

  // ----------------- actions -----------------
  void _selectTicket(String ticket) {
    setState(() {
      _selectedTicket = ticket;
      _billAmount = null;
      _ticketCost = null;
      _errorMessage = null;
      _selectedImage = null;
      _manualAmountController.clear();
      _suggestedTicket = null;
    });
  }

  void _switchToSuggested() {
    if (_suggestedTicket != null) {
      _selectTicket(_suggestedTicket!);
      _setManualBillAmount(); // re-validate with correct ticket
    }
  }

  void _submit() {
    if (_selectedTicket == null ||
        _selectedImage == null ||
        _billAmount == null ||
        _errorMessage != null ||
        !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ Please complete all steps and agree to Terms."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // ✅ Show success popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("✅ Success"),
          content: Text(
            "Your submission is successful!\n\n"
            "🎟️ Ticket: $_selectedTicket\n"
            "💰 Bill Amount: ₹${_billAmount!.toInt()}\n"
            "🏷️ Ticket Cost: ₹${_ticketCost!.toInt()}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close popup

                // ✅ Reset the form after closing popup
                setState(() {
                  _selectedImage = null;
                  _billAmount = null;
                  _selectedTicket = null;
                  _ticketCost = null;
                  _errorMessage = null;
                  _suggestedTicket = null;
                  _agreedToTerms = false;
                  _manualAmountController.clear();
                });
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pop();
  }

  void _showFullImage(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.file(image, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('💰 Earn Cash Back'),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ticket selection
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🎟️ Select Ticket",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: tickets.keys.map((t) {
                        final selected = _selectedTicket == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: selected,
                          onSelected: (_) => _selectTicket(t),
                          selectedColor: Colors.purple,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Upload screenshot
            ElevatedButton.icon(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.photo, size: 22),
              label: const Text('Upload Bill Screenshot',
                  style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            if (_selectedImage != null)
              GestureDetector(
                onTap: () => _showFullImage(_selectedImage!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedImage!,
                      height: 220, fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 20),

            // Manual amount entry
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("✍️ Enter Bill Amount Manually",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Bill Amount",
                              prefixText: "₹ ",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _setManualBillAmount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Apply"),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600)),
                    if (_suggestedTicket != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _switchToSuggested,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Switch to $_suggestedTicket"),
                      )
                    ]
                  ],
                ),
              ),

            if (_billAmount != null && _errorMessage == null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text("✅ Bill Amount: ₹${_billAmount!.toInt()}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      if (_ticketCost != null)
                        Text("🎟️ Ticket Cost: ₹${_ticketCost!.toInt()}",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 32, thickness: 1),

            // Terms
            CheckboxListTile(
              title: const Text("I agree to Terms & Conditions"),
              activeColor: Colors.purple,
              value: _agreedToTerms,
              onChanged: (val) =>
                  setState(() => _agreedToTerms = val ?? false),
            ),
            ExpansionTile(
              title: const Text("📄 View Terms & Conditions",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "1. The uploaded bill screenshot must be authentic.\n"
                    "2. Only PhonePe / UPI screenshots are accepted.\n"
                    "3. Ticket selection must match bill amount range.\n"
                    "4. Submissions without agreement will be rejected.",
                    style: TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // Submit
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

