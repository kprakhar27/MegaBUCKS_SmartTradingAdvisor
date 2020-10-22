import 'package:flutter/material.dart';
import 'package:smart_trading_advisor/analysis/analysis.dart';
import 'package:smart_trading_advisor/assets/app_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_trading_advisor/screens/home.dart';

class MyStocksList extends StatefulWidget {
  static const routeName = '/stocklist';
  @override
  _MyStocksListState createState() => _MyStocksListState();
}

class _MyStocksListState extends State<MyStocksList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Firestore db = Firestore.instance;
  FirebaseUser newUser;
  bool isloggedin = false;

  var jsonResponse;
  // int _itemcount = 0;

  // Future<void> getQuotes(String _symbol) async {
  //   String url = "http://10.0.2.2:5000/api?Symbol=$_symbol";
  //   http.Response response = await http.get(url);
  //   if (response.statusCode == 200) {
  //     setState(() {
  //       jsonResponse = convert.jsonDecode(response.body);
  //       _itemcount = jsonResponse.length;
  //     });
  //     debugPrint('Hello $_itemcount');
  //   } else {
  //     debugPrint("Request failed with status: ${response.statusCode}");
  //   }
  // }

  checkAuthentication() async {
    _auth.onAuthStateChanged.listen((newUser) {
      if (newUser == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    });
  }

  getUser() async {
    FirebaseUser firebaseUser = await _auth.currentUser();
    await firebaseUser?.reload();
    firebaseUser = await _auth.currentUser();

    if (firebaseUser != null) {
      setState(() {
        this.newUser = firebaseUser;
        this.isloggedin = true;
      });
    }
  }

  signOut() async {
    _auth.signOut();
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentication();
    this.getUser();
  }

  Widget _stockList(BuildContext context, DocumentSnapshot document) {
    return ListTile(
      leading: IconButton(
          icon: Icon(Icons.analytics_outlined),
          onPressed: () async {
            try {
              if (newUser != null) {
                var firebaseUser = await _auth.currentUser();
                data(firebaseUser, document['stock-symbol'],
                    document['stock-name']);
              }
            } catch (e) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Error!!!'),
                      content: Text('$e'),
                      actions: <Widget>[
                        FlatButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'))
                      ],
                    );
                  });
            }
          }),
      title: Text(document['stock-name']),
      subtitle: Text(document['stock-symbol']),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () async {
          try {
            if (newUser != null) {
              var firebaseUser = await _auth.currentUser();
              delete(firebaseUser, document['stock-symbol']);
            }
          } catch (e) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Error!!!'),
                    content: Text('$e'),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'))
                    ],
                  );
                });
          }
        },
      ),
      onTap: () async {
        try {
          if (newUser != null) {
            // _launchURL(document['stock-symbol']);
            // String url = "http://10.0.2.2/api?Symbol=$document['stock-symbol']";
            // html.window.open(url, name);

            // var firebaseUser = await _auth.currentUser();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Analysis(
                          url: document['stock-symbol'],
                        )));
            // analysis(firebaseUser, document['stock-symbol']);
          }
        } catch (e) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error!!!'),
                  content: Text('$e'),
                  actions: <Widget>[
                    FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'))
                  ],
                );
              });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return !isloggedin
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: appBarBuilder("My Stocks List"),
            bottomNavigationBar: BottomNav(),
            body: StreamBuilder(
                stream: db
                    .collection('user')
                    .document(newUser.uid)
                    .collection('stocklist')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text("No Stocks");
                  }
                  return ListView.builder(
                    // itemExtent: 50.0,
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, index) {
                      return _stockList(
                          context, snapshot.data.documents[index]);
                    },
                  );
                }));
  }

  void delete(FirebaseUser firebaseUser, String _symbol) {
    db
        .collection("user")
        .document(firebaseUser.uid)
        .collection("stocklist")
        .document(_symbol)
        .delete();
    db
        .collection("user")
        .document(firebaseUser.uid)
        .collection("dashboard")
        .document(_symbol)
        .delete();
  }

  // void analysis(FirebaseUser firebaseUser, String _symbol) {
  //   db.collection("user").document(firebaseUser.uid).updateData({
  //     "analysis-stock": _symbol,
  //   }).then((_) {
  //     String _analysisstock = _symbol;
  //   });
  // }

  void data(FirebaseUser firebaseUser, String _symbol, String _stockname) {
    db
        .collection("user")
        .document(firebaseUser.uid)
        .collection("dashboard")
        .document(_symbol)
        .setData({
      "stock-name": _stockname,
      "stock-symbol": _symbol,
    }).then((_) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success!!!'),
              content: Text('Successfully added stock to dashboard'),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'))
              ],
            );
          });
    });
  }
}
