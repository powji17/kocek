/// Web client ID untuk Google Sign-In di Android (PRD F1).
///
/// Cara mengambilnya (pilih salah satu):
/// 1. Buka android/app/google-services.json, cari entri "oauth_client"
///    yang punya "client_type": 3, lalu salin nilai "client_id"-nya.
/// 2. Firebase Console > Authentication > Sign-in method > Google >
///    "Web SDK configuration" > Web client ID.
///
/// Nilainya berakhiran `.apps.googleusercontent.com`. Ini bukan rahasia,
/// aman disimpan di kode.
const String kGoogleServerClientId = '690262764821-cvapne4en5b6eicq3jnq75hfilet22c2.apps.googleusercontent.com';

/// True bila nilai di atas belum diganti.
bool get isGoogleClientIdMissing => kGoogleServerClientId.startsWith('ISI_DENGAN');
