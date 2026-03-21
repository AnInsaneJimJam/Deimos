import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:mopro_flutter/mopro_flutter.dart';
import 'package:mopro_flutter/mopro_types.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:Deimos/channels/imp1_channel.dart';
import '../models/benchmark_item.dart';

class BenchmarkService {
  final MoproFlutter _moproFlutter = MoproFlutter();
  final Map<String, Uint8List> _noirVerificationKeys = {};

  Future<BenchmarkResult> runBenchmark(BenchmarkResult item, InputData inputData) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final updatedItem = item.copyWith(status: BenchmarkStatus.proving);
      
      final proofData = await _generateProof(item.framework, item.algorithm, item.inputName, inputData);
      final provingTime = stopwatch.elapsed;
      stopwatch.reset();
      stopwatch.start();
      
      final isValid = await _verifyProof(item.framework, item.algorithm, item.inputName, proofData);
      final verificationTime = stopwatch.elapsed;
      
      return item.copyWith(
        status: isValid ? BenchmarkStatus.completed : BenchmarkStatus.failed,
        provingTime: provingTime,
        verificationTime: verificationTime,
      );
    } catch (e) {
      return item.copyWith(
        status: BenchmarkStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<dynamic> _generateProof(String framework, String algorithm, String inputName, InputData inputData) async {
    switch (framework.toLowerCase()) {
      case 'arkworks':
      case 'rapidsnark':
        return await _generateGroth16Proof(framework, algorithm, inputName, inputData);
      case 'barretenberg':
        return await _generateBarretenbergProof(algorithm, inputName, inputData);
      case 'risc0':
        return await _generateRisc0Proof(inputData);
      case 'cairo':
        return await _generateCairoProof();
      case 'imp1':
        return await _generateIMP1Proof(algorithm, inputName);
      case 'provekit':
        return await _generateProveKitProof(algorithm, inputName, inputData);
      default:
        throw Exception('Unknown framework: $framework');
    }
  }

  Future<bool> _verifyProof(String framework, String algorithm, String inputName, dynamic proofData) async {
    switch (framework.toLowerCase()) {
      case 'arkworks':
      case 'rapidsnark':
        final proofLib = framework == 'rapidsnark' ? ProofLib.rapidsnark : ProofLib.arkworks;
        return await _moproFlutter.verifyGroth16Proof(_getZkeyPath(algorithm, inputName), proofData, proofLib);
      case 'barretenberg':
        final settings = await _getNoirSettings(algorithm, inputName);
        return await _moproFlutter.verifyBarretenbergProof(settings.circuitPath, proofData, settings.onChain, settings.vk, false);
      case 'risc0':
        final verifyResult = await _moproFlutter.verifyRisc0Proof(proofData.receipt);
        return verifyResult.isValid;
      case 'cairo':
        final verifyResult = await _moproFlutter.verifyCairoProof(proofData.proof);
        return verifyResult.isValid;
      case 'imp1':
        final verifyResult = await IMP1Channel.verifyProof(
          circuitName: _getImp1CircuitName(algorithm, inputName),
          proofData: proofData.proof,
          publicInputs: proofData.publicInputs,
        );
        return verifyResult.isValid;
      case 'provekit':
        final pkvPath = 'assets/provekit/${_getProveKitCircuitName(algorithm, inputName)}.pkv';
        final verifyResult = await _moproFlutter.verifyProveKitProof(pkvPath, proofData.proof);
        return verifyResult.isValid;
      default:
        return false;
    }
  }

  Future<Groth16ProofResult> _generateGroth16Proof(String framework, String algorithm, String inputName, InputData inputData) async {
    final inputs = '{"in": [${inputData.values.map((v) => '"$v"').join(', ')}]}';
    final zkeyPath = _getZkeyPath(algorithm, inputName);
    final proofLib = framework == 'rapidsnark' ? ProofLib.rapidsnark : ProofLib.arkworks;
    final result = await _moproFlutter.generateGroth16Proof(zkeyPath, inputs, proofLib);
    if (result == null) throw Exception('Failed to generate Groth16 proof');
    return result;
  }

  Future<Uint8List> _generateBarretenbergProof(String algorithm, String inputName, InputData inputData) async {
    final settings = await _getNoirSettings(algorithm, inputName);
    final noirInputs = _inputDataToNoirInput(inputData.values, settings.targetInputSize);
    return await _moproFlutter.generateBarretenbergProof(
      settings.circuitPath, settings.srsPath, noirInputs, settings.onChain, settings.vk, false
    );
  }

  Future<Risc0ProofOutput> _generateRisc0Proof(InputData inputData) async {
    int numericInput = int.tryParse(inputData.values.first) ?? 17;
    final result = await _moproFlutter.generateRisc0Proof(numericInput);
    if (result == null) throw Exception('Failed to generate RISC0 proof');
    return result;
  }

  Future<CairoProofOutput> _generateCairoProof() async {
    final inputsJson = await rootBundle.loadString('assets/cairo_input.json');
    final result = await _moproFlutter.generateCairoProof("assets/cairo_sha256.json", inputsJson);
    if (result == null) throw Exception('Failed to generate Cairo proof');
    return result;
  }

  Future<IMP1ProofResult> _generateIMP1Proof(String algorithm, String inputName) async {
    final circuitName = _getImp1CircuitName(algorithm, inputName);
    return await IMP1Channel.generateProof(circuitName: circuitName);
  }

  Future<ProveKitProofOutput> _generateProveKitProof(String algorithm, String inputName, InputData inputData) async {
    final circuitName = _getProveKitCircuitName(algorithm, inputName);
    final pkpPath = 'assets/provekit/$circuitName.pkp';
    final inputToml = 'input = [${inputData.values.map((v) => '"$v"').join(', ')}]\n';
    return await _moproFlutter.generateProveKitProof(pkpPath, inputToml);
  }

  String _getZkeyPath(String algorithm, String inputName) {
    String algoPrefix = algorithm.toLowerCase();
    if (algorithm == 'RescuePrime') algoPrefix = 'rescue-prime';
    else if (algorithm == 'Blake2s256') algoPrefix = 'blake2s256';
    final suffix = inputName.split(' ').last;
    return "assets/groth16/zkey/${algoPrefix}_$suffix.zkey";
  }

  String _getImp1CircuitName(String algorithm, String inputName) {
    String algoPrefix = algorithm.toLowerCase();
    if (algorithm == 'RescuePrime') algoPrefix = 'rescue-prime';
    else if (algorithm == 'Blake2s256') algoPrefix = 'blake2s256';
    final suffix = inputName.split(' ').last;
    return "${algoPrefix}_$suffix";
  }

  String _getProveKitCircuitName(String algorithm, String inputName) {
    String algoPrefix = algorithm.toLowerCase();
    if (algorithm == 'RescuePrime') algoPrefix = 'rescue_prime';
    final suffix = inputName.split(' ').last;
    if (['SHA256', 'Keccak256', 'Blake2', 'Blake3', 'Pedersen'].contains(algorithm)) {
      return "${algoPrefix}_bytes_$suffix";
    } else {
      return "${algoPrefix}_field_${suffix.replaceAll('f', '')}";
    }
  }

  List<String> _inputDataToNoirInput(List<String> inputData, int targetSize) {
    final paddedData = List<String>.from(inputData);
    while (paddedData.length < targetSize) paddedData.add('0');
    return paddedData.take(targetSize).toList();
  }

  Future<({String circuitPath, String srsPath, bool onChain, Uint8List vk, int targetInputSize})> _getNoirSettings(String algorithm, String inputName) async {
    final algorithmKey = algorithm.toLowerCase().replaceAll('rescueprime', 'rescue_prime');
    final suffix = inputName.split(' ').last.replaceAll('f', '');
    final rawInputSize = int.tryParse(suffix) ?? 0;
    
    int targetInputSize;
    String assetPath;
    String srsPath;
    bool onChain = true;
    String? vkAssetPath;

    if (['SHA256', 'Keccak256', 'Blake2', 'Blake3', 'Pedersen'].contains(algorithm)) {
      targetInputSize = rawInputSize <= 16 ? 16 : (rawInputSize <= 32 ? 32 : (rawInputSize <= 64 ? 64 : (rawInputSize <= 128 ? 128 : (rawInputSize <= 256 ? 256 : (rawInputSize <= 512 ? 512 : 1028)))));
      if (algorithm == 'Pedersen') {
        assetPath = 'assets/pedersen.json'; srsPath = 'assets/pedersen.srs'; vkAssetPath = 'assets/pedersen.vk';
      } else {
        assetPath = 'assets/barretenberg/${algorithmKey}_bytes_$targetInputSize.json';
        srsPath = 'assets/barretenberg/${algorithmKey}_bytes_$targetInputSize.srs';
      }
    } else {
      targetInputSize = rawInputSize <= 1 ? 1 : (rawInputSize <= 2 ? 2 : (rawInputSize <= 3 ? 3 : (rawInputSize <= 5 ? 5 : (rawInputSize <= 9 ? 9 : (rawInputSize <= 17 ? 17 : 34)))));
      assetPath = 'assets/barretenberg/${algorithmKey}_field_$targetInputSize.json';
      srsPath = 'assets/barretenberg/${algorithmKey}_field_$targetInputSize.srs';
      onChain = algorithm != 'Poseidon';
    }

    final cacheKey = '$assetPath|$srsPath|$onChain';
    if (_noirVerificationKeys.containsKey(cacheKey)) {
      return (circuitPath: assetPath, srsPath: srsPath, onChain: onChain, vk: _noirVerificationKeys[cacheKey]!, targetInputSize: targetInputSize);
    }

    Uint8List? vk;
    if (vkAssetPath != null) {
      try { vk = (await rootBundle.load(vkAssetPath)).buffer.asUint8List(); } catch (_) {}
    }
    vk ??= await _moproFlutter.getBarretenbergVerificationKey(assetPath, srsPath, onChain, false);
    _noirVerificationKeys[cacheKey] = vk;

    return (circuitPath: assetPath, srsPath: srsPath, onChain: onChain, vk: vk, targetInputSize: targetInputSize);
  }
}
