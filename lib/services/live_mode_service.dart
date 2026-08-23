import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveModeService {
  Stream<bool> get liveModeStream async* {
    try {
      await for (final event
          in FirebaseDatabase.instance.ref('system/liveMode').onValue) {
        yield _readEnabled(event.snapshot.value);
      }
    } catch (error) {
      await for (final snapshot in FirebaseFirestore.instance
          .collection('system')
          .doc('liveMode')
          .snapshots()) {
        yield _readEnabled(snapshot.data());
      }
    }
  }

  bool _readEnabled(Object? value) {
    if (value is bool) return value;
    if (value is Map) {
      final enabled = value['enabled'];
      if (enabled is bool) return enabled;
      if (enabled is String) return enabled.toLowerCase() == 'true';
    }
    return false;
  }
}
