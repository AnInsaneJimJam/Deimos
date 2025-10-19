import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  // Separate state for Keccak256 and SHA256 circuits
  CircomProofResult? _keccakProofResult;
  CircomProofResult? _sha256ProofResult;
  Halo2ProofResult? _halo2ProofResult;
  Uint8List? _noirProofResult;
  Uint8List? _noirVerificationKey;
  bool? _keccakValid;
  bool? _sha256Valid;
  bool? _halo2Valid;
  bool? _noirValid;
  final _moproFlutterPlugin = MoproFlutter();
  bool isProving = false;
  Exception? _error;
  late TabController _tabController;

  // Controllers to handle user input
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();
  final TextEditingController _controllerOut = TextEditingController();
  final TextEditingController _controllerNoirA = TextEditingController();
  final TextEditingController _controllerNoirB = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllerA.text = "5";
    _controllerB.text = "3";
    _controllerOut.text = "55";
    _controllerNoirA.text = "5";
    _controllerNoirB.text = "3";
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCircomTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isProving) const CircularProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error.toString()),
            ),
          
          // Keccak256 Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Keccak256 Proof Generation\nUsing hardcoded input: "Hello World! This is a test msg."',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      CircomProofResult? proofResult;
                      try {
                        // Hardcoded Keccak input: "Hello World! This is a test msg." as byte array
                        var inputs = '''{
    "in": [
        "72",
        "101",
        "108",
        "108",
        "111",
        "32",
        "87",
        "111",
        "114",
        "108",
        "100",
        "33",
        "32",
        "84",
        "104",
        "105",
        "115",
        "32",
        "105",
        "115",
        "32",
        "97",
        "32",
        "116",
        "101",
        "115",
        "116",
        "32",
        "109",
        "115",
        "103",
        "46"
    ]
}''';
                        proofResult =
                            await _moproFlutterPlugin.generateCircomProof(
                                "assets/keccak.zkey", inputs, ProofLib.arkworks);  // Using Keccak zkey
                      } on Exception catch (e) {
                        print("Error: $e");
                        proofResult = null;
                        setState(() {
                          _error = e;
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _keccakProofResult = proofResult;
                      });
                    },
                    child: const Text("Prove Keccak")),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      bool? valid;
                      try {
                        var proofResult = _keccakProofResult;
                        valid = await _moproFlutterPlugin.verifyCircomProof(
                            "assets/keccak.zkey", proofResult!, ProofLib.arkworks); // Using Keccak zkey
                      } on Exception catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = e;
                        });
                      } on TypeError catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = Exception(e.toString());
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _keccakValid = valid;
                      });
                    },
                    child: const Text("Verify Keccak")),
              ),
            ],
          ),
          if (_keccakProofResult != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Keccak Proof is valid: ${_keccakValid ?? false}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      Text('Keccak Proof inputs: ${_keccakProofResult?.inputs ?? ""}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Keccak Proof: ${_keccakProofResult?.proof ?? ""}'),
                ),
              ],
            ),
          
          // Visual divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
            child: Divider(
              thickness: 2,
              color: Colors.grey[400],
            ),
          ),
          
          // SHA256 Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'SHA256 Proof Generation\nUsing hardcoded input: "Hello World! This is a test msg."',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      CircomProofResult? proofResult;
                      try {
                        // Hardcoded SHA256 input: "Hello World! This is a test msg." as byte array
                        var inputs = '''{
    "in": [
        "40",
        "202",
        "21",
        "44",
        "148",
        "225",
        "219",
        "127",
        "125",
        "137",
        "45",
        "39",
        "181",
        "182",
        "116",
        "221",
        "65",
        "64",
        "40",
        "99",
        "92",
        "60",
        "3",
        "33",
        "40",
        "159",
        "154",
        "251",
        "14",
        "238",
        "144",
        "106"
    ]
}''';
                        proofResult =
                            await _moproFlutterPlugin.generateCircomProof(
                                "assets/sha256.zkey", inputs, ProofLib.arkworks);  // Using SHA256 zkey
                      } on Exception catch (e) {
                        print("Error: $e");
                        proofResult = null;
                        setState(() {
                          _error = e;
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _sha256ProofResult = proofResult;
                      });
                    },
                    child: const Text("Prove SHA256")),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      bool? valid;
                      try {
                        var proofResult = _sha256ProofResult;
                        valid = await _moproFlutterPlugin.verifyCircomProof(
                            "assets/sha256.zkey", proofResult!, ProofLib.arkworks); // Using SHA256 zkey
                      } on Exception catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = e;
                        });
                      } on TypeError catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = Exception(e.toString());
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _sha256Valid = valid;
                      });
                    },
                    child: const Text("Verify SHA256")),
              ),
            ],
          ),
          if (_sha256ProofResult != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('SHA256 Proof is valid: ${_sha256Valid ?? false}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      Text('SHA256 Proof inputs: ${_sha256ProofResult?.inputs ?? ""}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('SHA256 Proof: ${_sha256ProofResult?.proof ?? ""}'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHalo2Tab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isProving) const CircularProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error.toString()),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _controllerOut,
              decoration: const InputDecoration(
                labelText: "Public input `out`",
                hintText: "For example, 55",
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (_controllerOut.text.isEmpty || isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      Halo2ProofResult? halo2ProofResult;
                      try {
                        var inputs = {
                          "out": [(_controllerOut.text)]
                        };
                        halo2ProofResult =
                            await _moproFlutterPlugin.generateHalo2Proof(
                                "assets/plonk_fibonacci_srs.bin",
                                "assets/plonk_fibonacci_pk.bin",
                                inputs);
                      } on Exception catch (e) {
                        print("Error: $e");
                        halo2ProofResult = null;
                        setState(() {
                          _error = e;
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _halo2ProofResult = halo2ProofResult;
                      });
                    },
                    child: const Text("Generate Proof")),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (_controllerOut.text.isEmpty || isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      bool? valid;
                      try {
                        var proofResult = _halo2ProofResult;
                        valid = await _moproFlutterPlugin.verifyHalo2Proof(
                            "assets/plonk_fibonacci_srs.bin",
                            "assets/plonk_fibonacci_vk.bin",
                            proofResult!.proof,
                            proofResult.inputs);
                      } on Exception catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = e;
                        });
                      } on TypeError catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = Exception(e.toString());
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        _halo2Valid = valid;
                        isProving = false;
                      });
                    },
                    child: const Text("Verify Proof")),
              ),
            ],
          ),
          if (_halo2ProofResult != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Proof is valid: ${_halo2Valid ?? false}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      Text('Proof inputs: ${_halo2ProofResult?.inputs ?? ""}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Proof: ${_halo2ProofResult?.proof ?? ""}'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoirTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isProving) const CircularProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error.toString()),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _controllerNoirA,
              decoration: const InputDecoration(
                labelText: "Public input `a`",
                hintText: "For example, 3",
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _controllerNoirB,
              decoration: const InputDecoration(
                labelText: "Public input `b`",
                hintText: "For example, 5",
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (_controllerNoirA.text.isEmpty || _controllerNoirB.text.isEmpty || isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      Uint8List? noirProofResult;
                      try {
                        var inputs = [
                          _controllerNoirA.text,
                          _controllerNoirB.text
                        ];
                        
                        // Constants for Noir proof generation
                        const bool onChain = true;  // Use Keccak for Solidity compatibility
                        const bool lowMemoryMode = false;
                        
                        // Get or generate verification key if not already available
                        if (_noirVerificationKey == null) {
                          setState(() {
                            _error = null;
                          });
                          // Try to load existing VK from assets, or generate new one
                          try {
                            // First try to load existing VK from assets
                            final vkAsset = await rootBundle.load('assets/noir_multiplier2.vk');
                            _noirVerificationKey = vkAsset.buffer.asUint8List();
                          } catch (e) {
                            // If VK doesn't exist in assets, generate it
                            _noirVerificationKey = await _moproFlutterPlugin.getNoirVerificationKey(
                              "assets/noir_multiplier2.json",
                              "assets/noir_multiplier2.srs",
                              onChain,
                              lowMemoryMode
                            );
                          }
                        }
                        
                        noirProofResult =
                            await _moproFlutterPlugin.generateNoirProof(
                                "assets/noir_multiplier2.json",
                                "assets/noir_multiplier2.srs",
                                inputs,
                                onChain,
                                _noirVerificationKey!,
                                lowMemoryMode);
                      } on Exception catch (e) {
                        print("Error: $e");
                        noirProofResult = null;
                        setState(() {
                          _error = e;
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        isProving = false;
                        _noirProofResult = noirProofResult;
                      });
                    },
                    child: const Text("Generate Proof")),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                    onPressed: () async {
                      if (_controllerNoirA.text.isEmpty || _controllerNoirB.text.isEmpty || isProving) {
                        return;
                      }
                      setState(() {
                        _error = null;
                        isProving = true;
                      });

                      FocusManager.instance.primaryFocus?.unfocus();
                      bool? valid;
                      try {
                        var proofResult = _noirProofResult;
                        var vk = _noirVerificationKey;
                        
                        if (vk == null) {
                          throw Exception("Verification key not available. Generate proof first.");
                        }
                        
                        // Constants for Noir proof verification
                        const bool onChain = true;  // Use Keccak for Solidity compatibility
                        const bool lowMemoryMode = false;
                        
                        valid = await _moproFlutterPlugin.verifyNoirProof(
                            "assets/noir_multiplier2.json",
                            proofResult!,
                            onChain,
                            vk,
                            lowMemoryMode);
                      } on Exception catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = e;
                        });
                      } on TypeError catch (e) {
                        print("Error: $e");
                        valid = false;
                        setState(() {
                          _error = Exception(e.toString());
                        });
                      }

                      if (!mounted) return;

                      setState(() {
                        _noirValid = valid;
                        isProving = false;
                      });
                    },
                    child: const Text("Verify Proof")),
              ),
            ],
          ),
          if (_noirProofResult != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Proof is valid: ${_noirValid ?? false}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      Text('Proof: ${_noirProofResult ?? ""}'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter App With MoPro'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Circom'),
              Tab(text: 'Halo2'),
              Tab(text: 'Noir'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCircomTab(),
            _buildHalo2Tab(),
            _buildNoirTab(),
          ],
        ),
      ),
    );
  }
}
