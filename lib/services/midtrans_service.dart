import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class MidtransService {
  static const String _serverKey =
      String.fromEnvironment('MIDTRANS_SERVER_KEY');
  static const String _snapUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String _apiUrl = 'https://api.sandbox.midtrans.com/v2';

  static String get _authHeader =>
      'Basic ${base64Encode(utf8.encode('$_serverKey:'))}';

  static bool get _hasServerKey {
    if (_serverKey.isNotEmpty) return true;
    dev.log(
      '[Midtrans] MIDTRANS_SERVER_KEY belum diset (--dart-define=MIDTRANS_SERVER_KEY=...)',
      name: 'MidtransService',
    );
    return false;
  }

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ─────────────────────────────────────────────
  // Generate Snap payment URL
  // ─────────────────────────────────────────────
  static Future<String?> generatePaymentUrl({
    required String idTransaksi,
    required int nominal,
  }) async {
    if (!_hasServerKey) return null;
    try {
      final response = await http.post(
        Uri.parse(_snapUrl),
        headers: {..._jsonHeaders, 'Authorization': _authHeader},
        body: jsonEncode({
          'transaction_details': {
            'order_id': idTransaksi,
            'gross_amount': nominal,
          },
          'credit_card': {'secure': true},
        }),
      );

      dev.log(
        '[Midtrans] generatePaymentUrl → ${response.statusCode}: ${response.body}',
        name: 'MidtransService',
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['redirect_url'] as String?;
      }
      return null;
    } catch (e) {
      dev.log('[Midtrans] generatePaymentUrl error: $e',
          name: 'MidtransService');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Cek status transaksi dari Midtrans
  //
  // Return values (dari Midtrans):
  //   'pending'    → belum dibayar
  //   'settlement' → transfer bank / QRIS berhasil
  //   'capture'    → kartu kredit berhasil
  //   'deny'       → ditolak
  //   'cancel'     → dibatalkan
  //   'expire'     → kadaluarsa
  //   null         → error / transaksi belum ada di Midtrans
  // ─────────────────────────────────────────────
  static Future<String?> cekStatusTransaksi(String orderId) async {
    if (!_hasServerKey) return null;
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/$orderId/status'),
        headers: {..._jsonHeaders, 'Authorization': _authHeader},
      );

      dev.log(
        '[Midtrans] cekStatus($orderId) → ${response.statusCode}: ${response.body}',
        name: 'MidtransService',
      );

      // 404 = transaksi belum terdaftar di Midtrans (terlalu cepat polling)
      // 200/201 = ada data status
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['transaction_status'] as String?;
      }

      // Status lain (404, 500, dll) → return null, polling akan retry
      return null;
    } catch (e) {
      dev.log('[Midtrans] cekStatusTransaksi error: $e',
          name: 'MidtransService');
      return null;
    }
  }
}
