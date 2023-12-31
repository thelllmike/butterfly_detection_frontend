import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:foodie/api_service.dart';
import 'package:foodie/common_widgets/main_button.dart';
import 'package:foodie/common_widgets/snackbar.dart';
import 'package:foodie/constants.dart';
import 'package:foodie/main.dart';
import 'package:foodie/main_layout.dart';
import 'package:foodie/screens/function_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:foodie/screens/prediction_history.dart';
import 'package:image/image.dart' as img;

class ReminderScreen extends StatefulWidget {
  final String? diseases;

  ReminderScreen({Key? key, this.diseases}) : super(key: key);

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final ImagePicker picker = ImagePicker();
  String? imagePath;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _cameraLoading = false;
 
 //image validation
 bool isValidImage(File file) {
  try {
    final image = img.decodeImage(file.readAsBytesSync());
    return image != null;
  } catch (e) {
    return false;
  }
}

bool isValidExtension(String filePath) {
  String ext = filePath.split('.').last;
  return ext.toLowerCase() == 'jpg' || ext.toLowerCase() == 'png';
}


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras![0], ResolutionPreset.medium);

    await _controller!.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose(); // Using the null-safe call
    super.dispose();
  }

  Future<void> uploadFile(File image, {required Function(Map<String, dynamic> data) success, required Function(String message) failed}) async {
    try {
      Map<String, dynamic> response = await ApiService().uploadImage(image);

      if (response.containsKey('class')) {
        success(response);
      } else {
        failed('Failed to get the class from response.');
      }
    } catch (error) {
      failed(error.toString());
    }
  }

  Future<void> _analyseNutritions() async {
    setState(() {
      _isLoading = true;
    });
    await uploadFile(File(imagePath!), success: (data) {
      setState(() {
        _isLoading = false;
      });

      String? detected = data['class'];

      if (detected!= null && detected != "") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  ButterflyScreen(
              detected: detected,
          
            ),
          ),
        );
      } else {
        showSnackBar(isError: true, msg: 'Failed! try again.');
      }
      print(data['class']);
    }, failed: (msg) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(isError: true, msg: msg);
    });
  }

  Future<void> _takePicture() async {
    setState(() {
      _cameraLoading = true;
      imagePath = null;
    });
    if (!_controller!.value.isInitialized) {
      return;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_camera';

    await Directory(dirPath).create(recursive: true);

    if (_controller!.value.isTakingPicture) {
      return;
    }
//test image validation
    try {
      XFile picture = await _controller!.takePicture();
     if (isValidExtension(picture.path)) {
        if (isValidImage(File(picture.path))) {
          setState(() {
            imagePath = picture.path;
          });
        } else {
          showSnackBar(isError: true, msg: 'The image seems to be corrupt. Please try another.');
        }
      } else {
        showSnackBar(isError: true, msg: 'Only JPG and PNG formats are accepted. Please try another.');
      }
    } on CameraException catch (e) {
      print('Error taking picture: $e');
    }
    setState(() {
      _cameraLoading = false;
    });
  }

  Future<void> _selectImageFromGallery() async {
    setState(() {
      imagePath = null;
    });
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

     if (pickedFile != null) {
      if (isValidExtension(pickedFile.path)) {
        if (isValidImage(File(pickedFile.path))) {
          setState(() {
            imagePath = pickedFile.path;
          });
        } else {
          showSnackBar(isError: true, msg: 'The selected image seems to be corrupt. Please choose another.');
        }
      } else {
        showSnackBar(isError: true, msg: 'Only JPG and PNG formats are accepted. Please choose another.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MainLayout(
      title: '',

      
      customBody: Container(
        padding: EdgeInsets.only(top: 20),
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          children: [
            Container(
              width: size.width,
              child: SingleChildScrollView(
                child: Row(
                  children: [

                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 25),
                      width: size.width - 70,
                      height: size.width - 100,
                      decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(
                            20,
                          )),
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: (imagePath != null)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(imagePath!),
                            width: 400,
                            height: 400,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.circular(20),
                                child: CameraPreview(_controller!),
                              ),
                            ),
                            Positioned.fill(
                                child: Visibility(
                                  visible: _cameraLoading,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    IconButton(
                      onPressed: () {
                        _takePicture();
                      },
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 50,
                      ),
                    ),
                    MainButton(
                      size: size,
                      title: 'Upload Image',
                      onTap: () {
                        _selectImageFromGallery();
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    MainButton(
                      size: size,
                      title: 'Analyse Butterfly',
                      onTap: () {
                        if (imagePath != null) {
                          _analyseNutritions();
                        } else {
                          showSnackBar(
                              isError: true,
                              msg:
                              'Please select the image before analysis.');
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // MainButton(
                    //   size: size,
                    //   title: 'Prediction History',
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => HistoryScreen()), // or whatever the name of your prediction history screen class is
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _foodTypeShowingTile(String foodType, int btnIndex) {
    return Expanded(
      flex: 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = btnIndex;
          });
        },
        child: Container(
          margin: EdgeInsets.all(2),
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 2,
              color: _selectedIndex == btnIndex
                  ? AppColors.primaryColor
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2),
                child: _selectedIndex == btnIndex
                    ? Image.asset(
                  'assets/icons/on_switch.png',
                  height: 20,
                  width: 20,
                )
                    : Image.asset(
                  'assets/icons/off_switch.png',
                  height: 20,
                  width: 20,
                ),
              ),
              Text(
                foodType,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}