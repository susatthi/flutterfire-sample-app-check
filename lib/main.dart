// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_sample_app_check/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('kReleaseMode = $kReleaseMode');

  // Firebase の初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check の初期化
  await FirebaseAppCheck.instance.activate(
    // Androidに適用する場合
    androidProvider:
        kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    // iOSに適用する場合
    appleProvider:
        kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
  );

  // FirebaseUser を取得する
  final firebaseUser = await FirebaseAuth.instance.userChanges().first;
  String? uid = firebaseUser?.uid;
  if (uid == null) {
    // 未サインインなら匿名ユーザーでサインインする
    final credential = await FirebaseAuth.instance.signInAnonymously();
    uid = credential.user!.uid;
    print('ログインしました: uid = $uid');
  } else {
    print('ログイン済みです: uid = $uid');
  }

  runApp(MyApp(uid: uid));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Check Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(uid: uid),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.uid,
  });

  final String uid;

  /// Firestoreに保存したカウント値のStream
  Stream<int?> get counterStream => FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .snapshots()
          .map((snapshot) {
        final json = snapshot.data();
        return json?['counter'];
      });

  /// カウント値を加算する
  Future<void> _incrementCounter() async {
    await FirebaseFirestore.instance.collection('user').doc(uid).set({
      'counter': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Check Sample'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text('アプリを再起動してください。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MODE: ${kReleaseMode ? 'RELEASE' : 'DEBUG'}'),
                Text('UID: $uid'),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                StreamBuilder<int?>(
                    stream: counterStream,
                    builder: (context, snapshot) {
                      final counter = snapshot.data;
                      return Text(
                        '${counter ?? 'Click add button!'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _incrementCounter();
          } catch (e) {
            print(e);
            if (!context.mounted) {
              return;
            }
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('エラー'),
                content: Text(e.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
