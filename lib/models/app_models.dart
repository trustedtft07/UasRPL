import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODEL MERCHANT ---
class MerchantModel {
  final String idMerchant;
  final String namaToko;
  final int saldo;
  final String telepon;
  final String email;

  MerchantModel({
    required this.idMerchant,
    required this.namaToko,
    required this.saldo,
    required this.telepon,
    required this.email,
  });

  factory MerchantModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MerchantModel(
      idMerchant: doc.id,
      namaToko: data['NamaToko'] ?? '',
      saldo: data['Saldo'] ?? 0,
      telepon: data['Telepon'] ?? '',
      email: data['Email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'NamaToko': namaToko,
      'Saldo': saldo,
      'Telepon': telepon,
      'Email': email,
    };
  }
}

// --- MODEL KASIR ---
class KasirModel {
  final String idKasir;
  final String idMerchant;
  final String namaKasir;
  final String pinLogin;
  final bool isActive;

  KasirModel({
    required this.idKasir,
    required this.idMerchant,
    required this.namaKasir,
    required this.pinLogin,
    required this.isActive,
  });

  factory KasirModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return KasirModel(
      idKasir: doc.id,
      idMerchant: data['IdMerchant'] ?? '',
      namaKasir: data['NamaKasir'] ?? '',
      pinLogin: data['PinLogin'] ?? '',
      isActive: data['IsActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'IdMerchant': idMerchant,
      'NamaKasir': namaKasir,
      'PinLogin': pinLogin,
      'IsActive': isActive,
    };
  }
}

// --- MODEL TRANSAKSI ---
class TransaksiModel {
  final String idTransaksi;
  final String idKasir;
  final String idMerchant; // Penting untuk filter history Merchant
  final int nominal;
  final String catatan;
  final String statusTransaksi;
  final DateTime? waktuDibuat;

  TransaksiModel({
    required this.idTransaksi,
    required this.idKasir,
    required this.idMerchant,
    required this.nominal,
    required this.catatan,
    required this.statusTransaksi,
    this.waktuDibuat,
  });

  factory TransaksiModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransaksiModel(
      idTransaksi: data['IdTransaksi'] ?? doc.id,
      idKasir: data['IdKasir'] ?? '',
      idMerchant: data['IdMerchant'] ?? '',
      nominal: data['Nominal'] ?? 0,
      catatan: data['Catatan'] ?? '',
      statusTransaksi: data['StatusTransaksi'] ?? 'pending',
      waktuDibuat: (data['WaktuDibuat'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'IdTransaksi': idTransaksi,
      'IdKasir': idKasir,
      'IdMerchant': idMerchant,
      'Nominal': nominal,
      'Catatan': catatan,
      'StatusTransaksi': statusTransaksi,
      'WaktuDibuat': FieldValue.serverTimestamp(),
    };
  }
}

// --- MODEL RIWAYAT PEMBAYARAN ---
class RiwayatPembayaranModel {
  final String idPayment;
  final String idTransaksi;
  final String referenceId;
  final String qrUrl;
  final DateTime? waktuDibayar;

  RiwayatPembayaranModel({
    required this.idPayment,
    required this.idTransaksi,
    required this.referenceId,
    required this.qrUrl,
    this.waktuDibayar,
  });

  factory RiwayatPembayaranModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RiwayatPembayaranModel(
      idPayment: data['IdPayment'] ?? doc.id,
      idTransaksi: data['IdTransaksi'] ?? '',
      referenceId: data['ReferenceId'] ?? '',
      qrUrl: data['QrUrl'] ?? '',
      waktuDibayar: (data['WaktuDibayar'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'IdPayment': idPayment,
      'IdTransaksi': idTransaksi,
      'ReferenceId': referenceId,
      'QrUrl': qrUrl,
      'WaktuDibayar': FieldValue.serverTimestamp(),
    };
  }
}

// --- MODEL PENARIKAN DANA ---
class PenarikanDanaModel {
  final String idPencairan;
  final String idMerchant;
  final int nominalTarik;
  final String bankTujuan;
  final String nomorRekening;
  final String statusPenarikan;
  final DateTime? waktuPenarikan;

  PenarikanDanaModel({
    required this.idPencairan,
    required this.idMerchant,
    required this.nominalTarik,
    required this.bankTujuan,
    required this.nomorRekening,
    required this.statusPenarikan,
    this.waktuPenarikan,
  });

  factory PenarikanDanaModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PenarikanDanaModel(
      idPencairan: doc.id,
      idMerchant: data['IdMerchant'] ?? '',
      nominalTarik: data['NominalTarik'] ?? 0,
      bankTujuan: data['BankTujuan'] ?? '',
      nomorRekening: data['NomorRekening'] ?? '',
      statusPenarikan: data['StatusPenarikan'] ?? 'Diproses',
      waktuPenarikan: (data['WaktuPenarikan'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'IdMerchant': idMerchant,
      'NominalTarik': nominalTarik,
      'BankTujuan': bankTujuan,
      'NomorRekening': nomorRekening,
      'StatusPenarikan': statusPenarikan,
      'WaktuPenarikan': FieldValue.serverTimestamp(),
    };
  }
}