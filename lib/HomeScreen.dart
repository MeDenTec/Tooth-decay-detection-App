import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:object_detection/LoaderState.dart';
// New imports
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:convert';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:getwidget/getwidget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // WidgetsToImageController to access widget
  // WidgetsToImageController controller = WidgetsToImageController();
  // to save image bytes of widget
  // Uint8List? bytes;
  // File? capturedFile;
  List<String> views = [
    'Upper Occlusal',
    'Lower Occlusal',
    'Left Lateral',
    'Right Lateral',
    'Frontal'
  ];
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  String? file_name;
  String? age;
  String? location;
  // List? _prediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  bool next_step = false;
  bool check = false; //checks if camera button to activate or nex step button
  Completer<void> completer = Completer<void>();
  List<ResultObjectDetection?> objDetect = [];
  bool firststate = false;
  bool message = true;
// Button Controllers
  bool patReg = false;
  bool btn1 = false;
  bool btn2 = false;
  bool btn3 = false;
  bool btn4 = false;
  bool btn5 = false;
  int patCount = 0;
  int imgCount = 0;
  bool showLoader = false;

  // XFile? pickedImage;
  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/best.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
          // change the 2 with number of classes in your model I had almost 2 classes so I added 2 here.
          pathObjectDetectionModel,
          2,
          640,
          640,
          labelPath: "assets/labels/labels.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  void handleTimeout() {
    // callback function
    // Do some work.
    setState(() {
      firststate = true;
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) =>
      Timer(Duration(milliseconds: milliseconds), handleTimeout);

// Define a method to save the image to the specified directory
  Future<String> saveImageToDirectory(File image, String baseName) async {
    if (!await FlutterFileDialog.isPickDirectorySupported()) {
      print("Picking directory not supported");
      final params = SaveFileDialogParams(sourceFilePath: image.path);
      await FlutterFileDialog.saveFile(params: params);
      return baseName;
    }

    try {
      // Generate a unique file name for the image
      // String uniqueNum = '${DateTime.now().millisecondsSinceEpoch}';

      final pickedDirectory = await FlutterFileDialog.pickDirectory();
      final bytes = await image.readAsBytes(); // Use async read
      final finalPath = await FlutterFileDialog.saveFileToDirectory(
        directory: pickedDirectory!,
        data: bytes,
        fileName: baseName,
        mimeType: 'image/jpeg',
      );

      return baseName;
    } catch (error) {
      print("Error saving image: $error");
      // Handle the error appropriately (e.g., display an error message)
      return baseName;
    }
  }

  Future<void> saveTxtToPicked(List<dynamic> objDetect, String txtPath) async {
    final params = SaveFileDialogParams(sourceFilePath: txtPath);
    await FlutterFileDialog.saveFile(params: params);
  }

  Future<String> saveToFile(List<dynamic> objDetect, String baseName) async {
    // Get the directory for storing files
    Directory? appDir = await getTemporaryDirectory();

    // Define the directory where you want to save the image
    Directory targetDir = Directory('${appDir!.path}/DMFT/output');
    if (!targetDir.existsSync()) {
      // Create the directory if it doesn't exist
      targetDir.createSync(recursive: true);
    }
    // final baseNametxt = baseName.replaceAll('.jpg', '.txt');
    // String filePath = '${targetDir.path}/$baseNametxt';
    String filePath = '${targetDir.path}/$baseName.txt';

    // Open the file for writing
    File file = File(filePath);
    IOSink sink = file.openWrite(mode: FileMode.append);

    // Iterate through the objDetect list and write each element to the file
    objDetect.forEach((element) {
      // Convert element to a string representation
      String elementString = jsonEncode({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });

      // Write the string to the file
      sink.writeln(elementString);
    });

    // Close the file
    await sink.close();
    return filePath;
  }

  Future<Map<String, dynamic>?>? _openFileNameAndAgeDialog(
      BuildContext context) async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _ageController = TextEditingController();
    String? _selectedValue;

    Map<String, dynamic>? result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Enter Patient Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(hintText: "Enter name"),
              ),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(hintText: "Enter age"),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                value: _selectedValue,
                onChanged: (String? newValue) {
                  _selectedValue = newValue;
                },
                items: <String>['Mithi', 'Karachi', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Select a location',
                  // border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if cancelled
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String enteredName = _nameController.text;
                String enteredAge = _ageController.text;
                if (enteredName.isNotEmpty &&
                    enteredAge.isNotEmpty &&
                    _selectedValue != null) {
                  Navigator.of(context).pop({
                    'name': enteredName,
                    'age': enteredAge,
                    'selectedValue': _selectedValue,
                  }); // Return name, age, and selected value
                } else {
                  // You can handle validation or show an error message here
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<XFile?> cropImage(File pickedImage) async {
    CroppedFile? cropped = await ImageCropper()
        .cropImage(sourcePath: pickedImage.path, uiSettings: [
      AndroidUiSettings(
          toolbarTitle: 'Crop to focus bucal cavity',
          toolbarWidgetColor: Colors.black,
          toolbarColor: Colors.white)
    ]);

    // Convert CroppedFile to File
    // File croppedFile = File(cropped!.path);
    if (cropped == null) {
      return null;
    }
    // Convert File to XFile
    XFile croppedXF = XFile(cropped!.path);

    return croppedXF;
  }

  // Function to show dialog box
  void showResultDialog(
      BuildContext context, Map<String?, int?> classFrequencies) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Object Detection Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: classFrequencies.entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showLargeImageAlert(
      BuildContext context, Map<String?, int?> classFrequencies) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    // height: 50,
                    child: Text(
                      textAlign: TextAlign.start,
                      ' Prediction Results: \n ${classFrequencies.entries.map((entry) {
                            return '${entry.key}: ${entry.value}';
                          })
                          // .toList()

                          .toString().replaceAll('(', '').replaceAll(')', '')}',
                      style: TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),
                  ),
                  Container(
                      child: Expanded(
                          child: _objectModel.renderBoxesOnImage(
                              _image!, objDetect)))
                ],
              )),
          actions: <Widget>[
            GFButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showGalleryImage(BuildContext context) async {
    XFile? showImage = await _picker.pickImage(source: ImageSource.gallery);
    if (showImage != null) {
      File showImage1 = File(showImage!.path);
      ImageProvider imageProvider = FileImage(showImage1);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Container(
              child: Image(image: imageProvider),
            ),
            actions: <Widget>[
              GFButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  // Modify your runObjectDetection function to save the image before setting state
  Future<void> runObjectDetection(
      String patName, String age, String view, String location) async {
    setState(() {
      firststate = false;
      message = false;
    });
    String uniqueNum = '${DateTime.now().millisecondsSinceEpoch}';
    // Pick an image
    XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage == null) {
      return;
    }

    XFile? croppedImage = await cropImage(File(pickedImage!.path));
    if (croppedImage == null) {
      return;
    }

    // Perform object detection on the saved image
    objDetect = await _objectModel.getImagePrediction(
      await File(croppedImage!.path).readAsBytes(),
      minimumScore: 0.5,
      IOUThershold: 0.6,
    );

    Map<String?, int?> classFrequencies = {};

    objDetect.forEach((element) {
      // Update class frequencies
      classFrequencies[element?.className] =
          (classFrequencies[element?.className] ?? 0) + 1;
    });

    // Save the image to the specified directory
    String baseName = '$patName-$age-$view-$location-$uniqueNum';
    await saveImageToDirectory(File(croppedImage!.path), baseName);

    String txtPath = await saveToFile(objDetect, baseName);
    await saveTxtToPicked(objDetect, txtPath);

    // Show dialog with class frequencies
    // showResultDialog(context, classFrequencies);

    showLargeImageAlert(context, classFrequencies);
    scheduleTimeout(5 * 1000);

    setState(() {
      _image = File(croppedImage.path);
      imgCount += 1;
    });
  }

  void showRegisterPatientAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Alert"),
          content: Text("Register patient first"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _nextProcess() {
    setState(() {
      next_step = true;
      print('Variable changed to true');
      completer.complete(); // Completing the Future
    });
  }

  void _resetCompleter() {
    setState(() {
      next_step = false;
      completer = Completer<void>(); // Resetting the Completer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("DMFT App"),
          actions: [
            IconButton(
              icon: const Row(
                children: [
                  Text(
                    'New Patient', // Your text
                    style: TextStyle(
                      fontSize: 18, // Adjust font size as needed
                      fontWeight: FontWeight.bold, // Make the text bold
                      color: Colors.blueAccent,
                    ),
                  ),
                  Icon(
                    Icons.navigate_next_outlined,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              onPressed: () async {
                // Action for next button
                Map<String, dynamic>? patientInfo =
                    await _openFileNameAndAgeDialog(context);
                patientInfo != null
                    ? {
                        setState(() {
                          file_name = patientInfo['name']!;
                          age = patientInfo['age']!;
                          location = patientInfo['selectedValue'];
                          patReg = true;
                          btn1 = false;
                          btn2 = false;
                          btn3 = false;
                          btn4 = false;
                          btn5 = false;
                          patCount += 1;
                        })
                      }
                    : null;
                // Add your custom logic here for next button action
              },
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 223, 233, 237),

        // backgroundColor: Colors.blueGrey,
        body: !showLoader
            ? Container(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 25,
                    child: Text(
                      'Patient Data',
                      style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 86, 107, 143)),
                    ),
                  ),
                  Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color.fromARGB(255, 184, 214, 236),
                      ),
                      alignment: Alignment.topLeft,
                      // color: Color.fromARGB(255, 184, 214, 236),
                      // width: double.infinity,
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          file_name != null
                              ? Text(
                                  ' Name: $file_name \n Age: $age years \n Location: $location',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ), // Change the font size as needed
                                )
                              : const Text(
                                  ' No Active Patient',
                                  style: TextStyle(
                                      fontSize:
                                          20), // Change the font size as needed
                                ),
                          Text(
                            " Patients count: $patCount \n Images count: $imgCount  ",
                            style: TextStyle(
                                fontSize: 20), // Change the font size as needed
                          )
                        ],
                      )),
                  const SizedBox(
                    height: 25,
                    child: Text(
                      'Capture Photos',
                      style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 86, 107, 143)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Color.fromARGB(255, 234, 235, 230)
                          // color: Colors.transparent
                          ),
                      alignment: Alignment.centerLeft,
                      // color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 300,
                            child: GFButton(
                              position: GFPosition.end,
                              size: 60,
                              text: "Capture ${views[0]}",
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 18),
                              icon: btn1
                                  ? Icon(Icons.done_outline_outlined)
                                  : Image.asset('assets/images/occlusal.png'),
                              color: btn1
                                  ? Color.fromARGB(255, 200, 210, 190)
                                  : Color.fromARGB(255, 166, 186, 195),
                              onPressed: () async {
                                patReg
                                    ? {
                                        setState(() {
                                          showLoader = true;
                                        }),
                                        await runObjectDetection(file_name!,
                                            age!, views[0], location!),
                                        setState(() {
                                          btn1 = true;
                                          showLoader = false;
                                        })
                                      }
                                    : showRegisterPatientAlert(context);
                              },
                            ),
                          ),
                          // const SizedBox(height: 25),
                          Container(
                            width: 300,
                            child: GFButton(
                              position: GFPosition.end,
                              size: 60,
                              text: "Capture ${views[1]}",
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 18),
                              icon: btn2
                                  ? Icon(Icons.done_outline_outlined)
                                  : Image.asset('assets/images/occlusal.png'),
                              color: btn2
                                  ? Color.fromARGB(255, 200, 210, 190)
                                  : Color.fromARGB(255, 166, 186, 195),
                              onPressed: () async {
                                patReg
                                    ? {
                                        setState(() {
                                          showLoader = true;
                                        }),
                                        await runObjectDetection(file_name!,
                                            age!, views[1], location!),
                                        setState(() {
                                          btn2 = true;
                                          showLoader = false;
                                        })
                                      }
                                    : showRegisterPatientAlert(context);
                              },
                            ),
                          ),
                          // const SizedBox(height: 25),
                          Container(
                            width: 300,
                            child: GFButton(
                              position: GFPosition.end,
                              size: 60,
                              text: "Capture ${views[2]}",
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 18),
                              icon: btn3
                                  ? Icon(Icons.done_outline_outlined)
                                  : Image.asset('assets/images/occlusal.png'),
                              color: btn3
                                  ? Color.fromARGB(255, 200, 210, 190)
                                  : Color.fromARGB(255, 166, 186, 195),
                              onPressed: () async {
                                patReg
                                    ? {
                                        setState(() {
                                          showLoader = true;
                                        }),
                                        await runObjectDetection(file_name!,
                                            age!, views[2], location!),
                                        setState(() {
                                          btn3 = true;
                                          showLoader = false;
                                        })
                                      }
                                    : showRegisterPatientAlert(context);
                              },
                            ),
                          ),
                          // const SizedBox(height: 25),
                          Container(
                            width: 300,
                            child: GFButton(
                              position: GFPosition.end,
                              size: 60,
                              text: "Capture ${views[3]}",
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 18),
                              icon: btn4
                                  ? Icon(Icons.done_outline_outlined)
                                  : Image.asset('assets/images/occlusal.png'),
                              color: btn4
                                  ? Color.fromARGB(255, 200, 210, 190)
                                  : Color.fromARGB(255, 166, 186, 195),
                              onPressed: () async {
                                patReg
                                    ? {
                                        setState(() {
                                          showLoader = true;
                                        }),
                                        await runObjectDetection(file_name!,
                                            age!, views[3], location!),
                                        setState(() {
                                          btn4 = true;
                                          showLoader = false;
                                        })
                                      }
                                    : showRegisterPatientAlert(context);
                              },
                            ),
                          ),
                          // const SizedBox(height: 25),
                          Container(
                            width: 300,
                            child: GFButton(
                              position: GFPosition.end,
                              size: 60,
                              text: "Capture ${views[4]}",
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 18),
                              icon: btn5
                                  ? Icon(Icons.done_outline_outlined)
                                  : Image.asset('assets/images/occlusal.png'),
                              color: btn5
                                  ? Color.fromARGB(255, 200, 210, 190)
                                  : Color.fromARGB(255, 166, 186, 195),
                              onPressed: () async {
                                patReg
                                    ? {
                                        setState(() {
                                          showLoader = true;
                                        }),
                                        await runObjectDetection(file_name!,
                                            age!, views[4], location!),
                                        setState(() {
                                          btn5 = true;
                                          showLoader = false;
                                        })
                                      }
                                    : showRegisterPatientAlert(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  FloatingActionButton(
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        showGalleryImage(context);
                      },
                      child: Image.asset(
                        'assets/images/gallery.png',
                      )),
                  SizedBox(
                    height: 25,
                    child: Text('Gallery'),
                  ),
                  // SizedBox(
                  //   height: 15,
                  // )
                ],
              ))
            : Center(
                child: LoaderState(),
              ));
  }
}
