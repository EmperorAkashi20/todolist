import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:todo/AddTask/Components/Body.dart';
import 'package:todo/Login.dart';
import 'package:todo/main.dart';

class Body extends StatefulWidget {
  static var title;
  static var documentId;
  static var desc;
  static var date;
  static var priority;

  const Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final _firestore = FirebaseFirestore.instance;
  var loggedInUser;
  bool completed = false;
  int completedTaskCount = 0;

  void showNotification() {
    flutterLocalNotificationsPlugin.show(
      0,
      "Testing",
      "Test going well",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channel.description,
          importance: Importance.high,
          color: Colors.blue,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  getUpdatedTaskInfo() {
    _firestore
        .collection("Users/" + MyApp.documentId + "/Tasks/")
        .where('currentStatus', isEqualTo: true)
        .get()
        .then((value) {
      completedTaskCount = value.size;
    });
  }

  @override
  void initState() {
    getUpdatedTaskInfo();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channel.description,
              color: Colors.blue,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('New event');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title.toString()),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.body.toString(),
                      ),
                    ],
                  ),
                ),
              );
            });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double windowHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // showNotification();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTask(),
            ),
          );
        },
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Users/' + MyApp.documentId + '/Tasks')
            .orderBy('Date')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.data == null) {
            return Container(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingDoubleFlipping.circle(
                      borderColor: Color(0xFF5B16D0),
                      borderSize: 2.0,
                      size: 40.0,
                      backgroundColor: Color(0xFF5B16D0),
                    ),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          } else if (snapshot.data!.docs.length == 0) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MyApp.userFirstName + "'s Tasks",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "No Tasks added",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyApp.userFirstName + "'s Tasks",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: windowHeight * 0.01,
                    ),
                    // Text(
                    //   '$completedTaskCount out of ${snapshot.data!.docs.length}',
                    //   style: TextStyle(
                    //     color: Colors.grey,
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    SizedBox(
                      height: windowHeight * 0.03,
                    ),
                    Expanded(
                      child: Column(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          DateFormat _dateFormat = DateFormat('y-MM-d');
                          String formattedDate =
                              _dateFormat.format(data['Date'].toDate());
                          return Column(
                            children: [
                              ListTile(
                                isThreeLine: true,
                                title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['Title'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          decoration:
                                              data['currentStatus'] == false
                                                  ? TextDecoration.none
                                                  : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        data['Description'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration:
                                              data['currentStatus'] == false
                                                  ? TextDecoration.none
                                                  : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ]),
                                subtitle: Text(
                                    "$formattedDate * ${data['Priority']}"),
                                trailing: Checkbox(
                                  checkColor: Colors.white,
                                  activeColor: Colors.redAccent,
                                  value: data['currentStatus'],
                                  onChanged: (value) async {
                                    setState(() {
                                      data['currentStatus'] = value!;
                                      _firestore
                                          .doc("Users/" +
                                              MyApp.documentId +
                                              "/Tasks/" +
                                              document.id)
                                          .update({
                                            'currentStatus':
                                                data['currentStatus']
                                          })
                                          .then((value) =>
                                              print('Status updated'))
                                          .catchError((error) => print(error));
                                      getUpdatedTaskInfo();
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    Body.title = data['Title'];
                                    Body.documentId = document.id;
                                    Body.desc = data['Description'];
                                    Body.priority = data['Priority'];
                                    Body.date = DateTime.parse(formattedDate);
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTask(),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                thickness: 1.2,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
