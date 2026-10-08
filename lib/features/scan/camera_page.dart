import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/image_crop_service.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../state/expense_store.dart';
import 'receipt_parser.dart';
import 'review_page.dart';

class CameraPage extends StatefulWidget{const CameraPage({super.key,required this.store});final ExpenseStore store;@override State<CameraPage> createState()=>_CameraPageState();}
class _CameraPageState extends State<CameraPage>{
  final _picker=ImagePicker();final _ocr=ReceiptOcrService();CameraController? _camera;bool _busy=false,_flash=false,_loading=true;String? _error;
  @override void initState(){super.initState();_init();}
  Future<void> _init()async{try{final cs=await availableCameras();if(cs.isEmpty)throw StateError('No camera available');final c=CameraController(cs.firstWhere((x)=>x.lensDirection==CameraLensDirection.back,orElse:()=>cs.first),ResolutionPreset.high,enableAudio:false);await c.initialize();await c.setFlashMode(FlashMode.off);if(mounted)setState(()=>_camera=c);}catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _flashToggle()async{final c=_camera;if(c==null)return;final v=!_flash;await c.setFlashMode(v?FlashMode.torch:FlashMode.off);if(mounted)setState(()=>_flash=v);}
  Future<void> _focus(TapUpDetails details) async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || renderBox.size.isEmpty) {
      return;
    }

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final point = Offset(
      (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0),
      (localPosition.dy / renderBox.size.height).clamp(0.0, 1.0),
    );

    try {
      await controller.setFocusPoint(point);
    } on CameraException {
      _msg('Manual focus is not supported by this camera.');
    }
  }

  Future<void> _pick(ImageSource source)async{if(_busy)return;setState(()=>_busy=true);try{final x=await _picker.pickImage(source:source,imageQuality:100);if(x!=null)await _process(File(x.path));}catch(e){_msg('OCR failed: $e');}finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _capture()async{final c=_camera;if(c==null||c.value.isTakingPicture||_busy)return;setState(()=>_busy=true);try{await _process(File((await c.takePicture()).path));}catch(e){_msg('Capture failed: $e');}finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _process(File source)async{final cropped=await ImageCropService.cropToReceiptFrame(source);final raw=await _ocr.recognize(cropped);final parsed=ReceiptParser().parse(raw);if(!mounted)return;final saved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>ReviewPage(store:widget.store,imageFile:cropped,rawText:raw,parsed:parsed)));if(saved==true&&mounted)Navigator.pop(context);}
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  @override void dispose(){_camera?.dispose();_ocr.dispose();super.dispose();}
  @override Widget build(BuildContext context){if(_loading)return const Scaffold(backgroundColor:Colors.black,body:Center(child:CircularProgressIndicator()));if(_error!=null)return Scaffold(backgroundColor:Colors.black,body:Center(child:Text(_error!,style:const TextStyle(color:Colors.white))));final c=_camera;return Scaffold(backgroundColor:Colors.black,body:SafeArea(child:GestureDetector(onTapUp:_focus,child:Stack(fit:StackFit.expand,children:[if(c!=null)CameraPreview(c),const IgnorePointer(child:CustomPaint(painter:_FramePainter())),Positioned(top:12,left:12,child:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close,color:Colors.white))),Positioned(top:12,right:12,child:IconButton(onPressed:_flashToggle,icon:Icon(_flash?Icons.flash_on:Icons.flash_off,color:Colors.white))),Positioned(bottom:24,left:20,right:20,child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[IconButton(onPressed:()=>_pick(ImageSource.gallery),icon:const Icon(Icons.photo_library,color:Colors.white,size:30)),FloatingActionButton(onPressed:_busy?null:_capture,child:_busy?const CircularProgressIndicator():const Icon(Icons.camera_alt)),IconButton(onPressed:()=>_pick(ImageSource.camera),icon:const Icon(Icons.document_scanner,color:Colors.white,size:30))]))])));}
}
class _FramePainter extends CustomPainter{const _FramePainter();@override void paint(Canvas c,Size s){final w=s.width*.86,h=s.height*.46,r=Rect.fromCenter(center:s.center,width:w,height:h);c.drawRect(Offset.zero& s,Paint()..color=Colors.black.withOpacity(.35));final clear=Paint()..blendMode=BlendMode.clear;c.saveLayer(Offset.zero&s,Paint());c.drawRect(Offset.zero&s,Paint()..color=Colors.black54);c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(22)),clear);c.restore();c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(22)),Paint()..style=PaintingStyle.stroke..strokeWidth=3..color=Colors.white);}@override bool shouldRepaint(covariant _FramePainter oldDelegate)=>false;}
