import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  print('Fetching all products...\n');
  
  final products = await firestore.collection('products').get();
  
  for (var doc in products.docs) {
    final data = doc.data();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Product ID: ${doc.id}');
    print('Title: ${data['title']}');
    print('Owner ID: "${data['ownerId']}"');
    print('Owner Name: ${data['ownerName']}');
    print('Status: ${data['status']}');
    print('Created: ${DateTime.fromMillisecondsSinceEpoch(data['createdAt'])}');
    print('');
  }
  
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Total products: ${products.docs.length}');
}
