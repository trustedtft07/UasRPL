import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import 'midtrans_service.dart';

/// PosService sebagai singleton — satu instance di seluruh app lifecycle.
/// Ini memastikan timer polling tidak hilang saat widget rebuild.
class PosService {
  PosService._internal();
  static final PosService _instance = PosService._internal();
  factory PosService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Session state
  static String activeRole = '';
  static String activeMerchantId = '';
  static String activeActorId = '';

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────
  Future<UserCredential?> registerMerchant({
    required String email,
    required String password,
    required String namaToko,
    required String telepon,
  }) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final m = MerchantModel(
        idMerchant: res.user!.uid,
        namaToko: namaToko,
        saldo: 1000000, // saldo awal 1 juta
        telepon: telepon,
        email: email,
      );
      await _db.collection('Merchant').doc(res.user!.uid).set(m.toMap());
      return res;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN MERCHANT
  // ─────────────────────────────────────────────
  Future<bool> loginMerchant(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      activeRole = 'merchant';
      activeMerchantId = res.user!.uid;
      activeActorId = res.user!.uid;
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN KASIR
  // ─────────────────────────────────────────────
  Future<bool> loginKasir(
      String idMerchant, String namaKasir, String pin) async {
    try {
      final res = await _db
          .collection('Kasir')
          .where('IdMerchant', isEqualTo: idMerchant)
          .where('NamaKasir', isEqualTo: namaKasir)
          .where('PinLogin', isEqualTo: pin)
          .where('IsActive', isEqualTo: true)
          .get();

      if (res.docs.isNotEmpty) {
        activeRole = 'kasir';
        activeMerchantId = idMerchant;
        activeActorId = res.docs.first.id;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // SIMPAN TRANSAKSI & RIWAYAT
  // ─────────────────────────────────────────────
  Future<void> simpanTransaksiDanRiwayat({
    required String idTransaksi,
    required int nominal,
    required String catatan,
    required String qrUrl,
  }) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('Transaksi').doc(idTransaksi),
      TransaksiModel(
        idTransaksi: idTransaksi,
        idKasir: activeActorId,
        idMerchant: activeMerchantId,
        nominal: nominal,
        catatan: catatan,
        statusTransaksi: 'pending',
      ).toMap(),
    );

    final rRef = _db.collection('RiwayatPembayaran').doc();
    batch.set(
      rRef,
      RiwayatPembayaranModel(
        idPayment: rRef.id,
        idTransaksi: idTransaksi,
        referenceId: 'MID-${DateTime.now().millisecondsSinceEpoch}',
        qrUrl: qrUrl,
      ).toMap(),
    );

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // SINKRONISASI STATUS + UPDATE WALLET
  // ─────────────────────────────────────────────
  Future<void> sinkronisasiStatus(
      String idTransaksi, String statusMidtrans) async {
    dev.log(
      '[PosService] sinkronisasiStatus: $idTransaksi → $statusMidtrans',
      name: 'PosService',
    );

    final Map<String, dynamic> updateData = {};

    if (statusMidtrans == 'settlement' || statusMidtrans == 'capture') {
      updateData['StatusTransaksi'] = 'success';
      updateData['WaktuSelesai'] = DateTime.now().millisecondsSinceEpoch;

      // Tambah saldo merchant sesuai nominal transaksi
      final txDoc =
          await _db.collection('Transaksi').doc(idTransaksi).get();
      if (txDoc.exists) {
        final data = txDoc.data()!;
        final nominal = (data['Nominal'] as num?)?.toInt() ?? 0;
        final merchantId = data['IdMerchant'] as String?;
        dev.log(
          '[PosService] Tambah saldo merchant $merchantId += $nominal',
          name: 'PosService',
        );
        if (nominal > 0 && merchantId != null && merchantId.isNotEmpty) {
          await _db
              .collection('Merchant')
              .doc(merchantId)
              .update({'Saldo': FieldValue.increment(nominal)});
        }
      }
    } else if (['deny', 'cancel', 'expire'].contains(statusMidtrans)) {
      updateData['StatusTransaksi'] = 'failed';
    }

    if (updateData.isNotEmpty) {
      await _db
          .collection('Transaksi')
          .doc(idTransaksi)
          .update(updateData);
      dev.log(
        '[PosService] Firestore updated: $idTransaksi → $updateData',
        name: 'PosService',
      );
    }
  }

  // ─────────────────────────────────────────────
  // POLLING STATUS PEMBAYARAN
  //
  // Menggunakan Map agar bisa pantau beberapa transaksi sekaligus
  // tanpa saling cancel. Setiap transaksi punya timer sendiri.
  // ─────────────────────────────────────────────
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, int> _pollCounts = {};
  static const int _maxPoll = 40;       // 40 × 5 detik = 3 menit 20 detik
  static const Duration _pollInterval = Duration(seconds: 5);

  void mulaiPantauStatus(String idTransaksi) {
    // Batalkan polling lama untuk transaksi yang sama jika ada
    _pollingTimers[idTransaksi]?.cancel();
    _pollCounts[idTransaksi] = 0;

    _pollingTimers[idTransaksi] =
        Timer.periodic(_pollInterval, (timer) async {
      final count = (_pollCounts[idTransaksi] ?? 0) + 1;
      _pollCounts[idTransaksi] = count;

      final st = await MidtransService.cekStatusTransaksi(idTransaksi);
      dev.log(
        '[PosService] poll #$count $idTransaksi → $st',
        name: 'PosService',
      );

      if (st != null) {
        final isTerminal = st == 'settlement' ||
            st == 'capture' ||
            ['deny', 'cancel', 'expire'].contains(st);

        if (isTerminal) {
          await sinkronisasiStatus(idTransaksi, st);
          _stopPolling(idTransaksi);
          return;
        }
      }

      if (count >= _maxPoll) {
        dev.log(
          '[PosService] polling habis untuk $idTransaksi',
          name: 'PosService',
        );
        _stopPolling(idTransaksi);
      }
    });
  }

  void _stopPolling(String idTransaksi) {
    _pollingTimers[idTransaksi]?.cancel();
    _pollingTimers.remove(idTransaksi);
    _pollCounts.remove(idTransaksi);
  }

  void hentikanPantauStatus() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _pollCounts.clear();
  }

  // ─────────────────────────────────────────────
  // SINKRONISASI MANUAL (dipanggil dari UI)
  // Cek status ke Midtrans dan update Firestore apapun hasilnya.
  // ─────────────────────────────────────────────
  Future<void> sinkronisasiManual(String idTransaksi) async {
    try {
      final st = await MidtransService.cekStatusTransaksi(idTransaksi);

      // null = Midtrans belum punya data (404) atau network error → skip
      if (st == null) return;

      // Apapun status terminal langsung sync ke Firestore
      final isTerminal = st == 'settlement' ||
          st == 'capture' ||
          ['deny', 'cancel', 'expire'].contains(st);

      if (isTerminal) {
        await sinkronisasiStatus(idTransaksi, st);
      }
      // 'pending' / 'authorize' → tidak perlu update, biarkan polling lanjut
    } catch (_) {
      // Jangan crash — ini background operation
    }
  }

  // ─────────────────────────────────────────────
  // AJUKAN PENARIKAN + POTONG SALDO
  // ─────────────────────────────────────────────
  Future<bool> ajukanPenarikan({
    required int nominal,
    required String bank,
    required String rekening,
  }) async {
    try {
      final merchantDoc =
          await _db.collection('Merchant').doc(activeMerchantId).get();
      final saldoSekarang =
          (merchantDoc.data()?['Saldo'] as num?)?.toInt() ?? 0;

      if (nominal > saldoSekarang) return false;

      final batch = _db.batch();

      batch.update(
        _db.collection('Merchant').doc(activeMerchantId),
        {'Saldo': FieldValue.increment(-nominal)},
      );

      final r = _db.collection('PenarikanDana').doc();
      batch.set(
        r,
        PenarikanDanaModel(
          idPencairan: r.id,
          idMerchant: activeMerchantId,
          nominalTarik: nominal,
          bankTujuan: bank,
          nomorRekening: rekening,
          statusPenarikan: 'Diproses',
        ).toMap(),
      );

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE PROFIL MERCHANT
  // ─────────────────────────────────────────────
  Future<bool> updateProfilMerchant({
    required String namaToko,
    required String telepon,
  }) async {
    try {
      await _db.collection('Merchant').doc(activeMerchantId).update({
        'NamaToko': namaToko,
        'Telepon': telepon,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // STREAM DATA MERCHANT
  // ─────────────────────────────────────────────
  Stream<MerchantModel?> streamMerchant() {
    return _db
        .collection('Merchant')
        .doc(activeMerchantId)
        .snapshots()
        .map((doc) => doc.exists ? MerchantModel.fromFirestore(doc) : null);
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  Future<void> logout() async {
    hentikanPantauStatus();
    await _auth.signOut();
    activeRole = '';
    activeMerchantId = '';
    activeActorId = '';
  }
}
