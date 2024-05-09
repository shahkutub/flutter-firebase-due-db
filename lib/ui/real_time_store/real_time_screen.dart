// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, unused_local_variable, unnecessary_string_interpolations, avoid_unnecessary_containers, unused_import

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/ui/real_time_store/add_post_due.dart';
import 'package:flutter_firebase/ui/auth/login_screen.dart';
import 'package:flutter_firebase/ui/firestore/firestore_list_screen.dart';
import 'package:flutter_firebase/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../widgets/round_button.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class HomePost extends StatefulWidget {
  @override
  State<HomePost> createState() => _HomePostState();
}

class _HomePostState extends State<HomePost> {
  final searchFilter = TextEditingController();
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final _dueTextController = TextEditingController();
  final _initialdueTextController = TextEditingController();
  final _duepayinfoTextController = TextEditingController();
  final _payTextController = TextEditingController();

  final databaseRef = FirebaseDatabase.instance.ref('Due');

  File? _image;
  final _picker = ImagePicker();

  String? due;

  Future getImageGally() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print("No Image Picked");
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _payTextController.addListener(() {
      if(_dueTextController.text.length>0 && _payTextController.text.length>0){

        _dueTextController.text = (int.parse(due!) - int.parse(_payTextController.text.toString())).toString();
      }else{
        _dueTextController.text = due!;
      }
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ignore: prefer_const_literals_to_create_immutables
        automaticallyImplyLeading: true,
        title: Text("Due"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut().then((value) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }).onError((error, stackTrace) {
                  Utils().toastMessage(error.toString());
                });
              },
              icon: Icon(Icons.login_outlined)),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
              onChanged: (String value) {
                setState(() {});
              },
              controller: searchFilter,
              keyboardType: TextInputType.text,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Search',
                // suffixIcon: Icon(Icons.search),
                prefixIcon: Icon(Icons.search),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),

          // !animated realtime data-------------------------
          Expanded(
            child: FirebaseAnimatedList(
              query: databaseRef, defaultChild: Text("Loading"),
              // reverse: _anchorToBottom,
              itemBuilder: (context, snapshot, animation, index) {
                final initialdue = snapshot.child("initialdue").value.toString();
                 due = snapshot.child("duetotal").value.toString();
                final payhistory = snapshot.child("payhistory").value.toString();
                final subtitle = snapshot.child("mobile").value.toString();
                final id = snapshot.child('id').value.toString();
                final image = snapshot.child('vawchar').value.toString();
                final name = snapshot.child('name').value.toString();

                if (searchFilter.text.isEmpty) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: InkWell(
                          onTap: (){
                            showVawcharDialog(image);
                          },
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(image),
                            radius: 20,
                          ),
                        ),
                        trailing: PopupMenuButton(
                            icon: Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 1,
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.pop(context);
                                        showMyDialog(
                                            initialdue, due!, payhistory,subtitle, id, image,name);
                                      },
                                      leading: Icon(Icons.edit),
                                      title: Text("Edit"),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: ListTile(
                                      onTap: () {
                                        databaseRef
                                            .child(id)
                                            .remove()
                                            .then((value) {
                                          Utils().toastMessage("Post Deleted");
                                          Navigator.pop(context);
                                        }).onError((error, stackTrace) {
                                          Utils()
                                              .toastMessage(error.toString());
                                        });
                                      },
                                      leading: Icon(Icons.delete),
                                      title: Text("Delete"),
                                    ),
                                  )
                                ]),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${snapshot.child('name').value.toString()}'),
                            Text('গ্রামঃ '+snapshot.child("village").value.toString()),
                            Row(
                              children: [
                                Text('মোবাইল নং: '+snapshot.child("mobile").value.toString()+'  '),
                                InkWell(child: Icon(Icons.phone_enabled),onTap: (){
                                  launchUrlString("tel://${snapshot.child("mobile").value.toString()}");
                                },)
                              ],
                            ),
                            Text('বাকি টাকা: '+snapshot.child("duetotal").value.toString()),
                            Text('বাকির তারিখ: ${snapshot.child('date').value.toString()}'),
                            Text('জামিনদার: ${snapshot.child('jamindarname').value.toString()}'),
                            Text('মোবাইল নং: ${snapshot.child('jamindarmobile').value.toString()}'),
                          ],
                        ),
                        // subtitle:
                        //     Text(snapshot.child("mobile").value.toString()),
                      ),
                    ),
                  );
                } else if (snapshot.child('name').value.toString()
                    .toLowerCase()
                    .contains(searchFilter.text.toLowerCase().toLowerCase())) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: ListTile(
                      iconColor: Colors.red,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${snapshot.child('name').value.toString()}'),
                          Text('গ্রামঃ '+snapshot.child("village").value.toString()),
                          Row(
                            children: [
                              Text('মোবাইল নং: '+snapshot.child("mobile").value.toString()+'  '),
                              InkWell(child: Icon(Icons.phone_enabled),onTap: (){
                                launchUrlString("tel://${snapshot.child("mobile").value.toString()}");
                              },)
                            ],
                          ),
                          Text('বাকি টাকা: '+snapshot.child("duetotal").value.toString()),
                          Text('বাকির তারিখ: ${snapshot.child('date').value.toString()}'),
                          Text('জামিনদার: ${snapshot.child('jamindarname').value.toString()}'),
                          Text('মোবাইল নং: ${snapshot.child('jamindarmobile').value.toString()}'),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddPostScreen()));
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> showMyDialog(
      String initialdue,String due,String payhistory, String subtitle, String id, String image,String name) async {
    _dueTextController.text = due;
    _initialdueTextController.text = initialdue;
    if(payhistory.length>0){
      _duepayinfoTextController.text = payhistory.trim().substring(1).replaceAll(',', '\n');
    }
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          double height = MediaQuery.of(context).size.height;
          double width = MediaQuery.of(context).size.width;
          return Scaffold(
            appBar: AppBar(title: Text(name),),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          // maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Text";
                            } else {
                              return null;
                            }
                          },
                          controller: _initialdueTextController,
                          decoration: InputDecoration(
                            //enabled: false,
                            hintText: '',
                            labelText: 'শুরুর বাকি',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 1.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                          // validator: (value) {
                          //   if (value == null || value.isEmpty) {
                          //     return "Enter Text";
                          //   } else {
                          //     return null;
                          //   }
                          // },
                          controller: _duepayinfoTextController,
                          decoration: InputDecoration(
                            enabled: false,
                            hintText: '',
                            labelText: 'বাকি প্রদান তথ্য',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 1.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          // maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Text";
                            } else {
                              return null;
                            }
                          },
                          controller: _dueTextController,
                          decoration: InputDecoration(
                            //enabled: false,
                            hintText: '',
                            labelText: 'বর্তমান বাকি টাকা',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 1.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                        ),


                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          // maxLines: 2,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter Text";
                            } else {
                              return null;
                            }
                          },
                          controller: _payTextController,
                          decoration: InputDecoration(
                            hintText: '',
                            labelText: 'আজকে পরিশোধ টাকার',
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 1.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                        ),

                        SizedBox(
                          height: 20,
                        ),
                        InkWell(
                          onTap: () {
                            getImageGally();
                          },
                          child: Container(
                            height: 100,
                            // width: 100,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green)),
                            child: _image != null
                                ? Image.file(_image!.absolute)
                                : Center(child: Icon(Icons.image))
                            ,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Cancle")),
                            SizedBox(
                              width: 10,
                            ),
                            TextButton(
                                onPressed: () async {
                                  final f = new DateFormat('dd-MM-yyyy');
                                  String todaydate = f.format(DateTime.now());
                                  String payhistoryy = payhistory+' , '+todaydate+' = '+_payTextController.text;
                                  if (_formKey.currentState!.validate()) {
                                    // firebase_storage.Reference ref =
                                    //     firebase_storage
                                    //         .FirebaseStorage.instance
                                    //         .ref('/kutub/' + id);
                                    // firebase_storage.UploadTask uploadTask =
                                    //     ref.putFile(_image!.absolute);
                                    //
                                    // await Future.value(uploadTask)
                                    //     .then((value) async {
                                    //   var newUrl = await ref.getDownloadURL();
                                    databaseRef.child(id).update({
                                      'duetotal': _dueTextController.text,
                                      'payhistory': '${payhistoryy}',
                                      //'image': newUrl.toString()
                                    }).then((value) {
                                      _payTextController.text = '';
                                      _dueTextController.text = '';

                                      Utils().toastMessage("Post Update");
                                      Navigator.pop(context);
                                    }).onError((error, stackTrace) {
                                      Utils()
                                          .toastMessage(error.toString());
                                    });
                                    //});
                                  }
                                },
                                child: Text("Update")),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> showVawcharDialog(String image) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          double height = MediaQuery.of(context).size.height;
          double width = MediaQuery.of(context).size.width;
          return Scaffold(
            //appBar: AppBar(title: Text('name'),),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.white,
                onPressed: (){
                Navigator.pop(context);
                },
              child: Icon(Icons.cancel_sharp,color: Colors.red,size: 30,),
            ),
            body: SingleChildScrollView(
              child: Container(
                child: Image.network(
                  image,
                ),
              )
            ),
          );
        });
  }
}

