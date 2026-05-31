import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../models/part_model.dart';
import '../theme/app_theme.dart';
import '../utils/media_utils.dart';
import 'media_viewer_screen.dart';

class AddEditPartScreen extends StatefulWidget {
  final PartModel? part;
  const AddEditPartScreen({super.key, this.part});
  @override
  State<AddEditPartScreen> createState() => _State();
}

class _State extends State<AddEditPartScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name, _serial, _model, _years, _carModel, _price, _stock;
  late String _category, _brand;
  late List<String> _mediaPaths;
  bool _showNewCat = false, _showNewBrand = false;
  bool _saving = false;
  final _newCatCtrl = TextEditingController();
  final _newBrandCtrl = TextEditingController();
  static const int _maxMedia = 4;

  bool get _isEdit => widget.part != null;

  @override
  void initState() {
    super.initState();
    final p = widget.part;
    _name     = TextEditingController(text: p?.name ?? '');
    _serial   = TextEditingController(text: p?.serialNumber ?? '');
    _model    = TextEditingController(text: p?.modelNumber ?? '');
    _years    = TextEditingController(text: p?.years ?? '');
    _carModel = TextEditingController(text: p?.carModel ?? '');
    _price    = TextEditingController(text: p != null ? '${p.price}' : '');
    _stock    = TextEditingController(text: p != null ? '${p.stock}' : '');
    _category = p?.category ?? '';
    _brand    = p?.carBrand ?? '';
    _mediaPaths = List.from(p?.mediaPaths ?? []);
  }

  @override
  void dispose() {
    for (final c in [_name,_serial,_model,_years,_carModel,_price,_stock,_newCatCtrl,_newBrandCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(int slot, {required bool isVideo}) async {
    final picker = ImagePicker();
    final file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null && mounted) {
      setState(() {
        if (slot < _mediaPaths.length) _mediaPaths[slot] = file.path;
        else _mediaPaths.add(file.path);
      });
    }
  }

  void _showPickerSheet(int slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Container(width:40,height:40,decoration:BoxDecoration(color:AppColors.primarySurface,shape:BoxShape.circle),
                child:const Icon(Icons.photo_library_outlined,color:AppColors.primary)),
            title: const Text('Choose Photo', style: AppText.bodyBold),
            onTap: () { Navigator.pop(context); _pickMedia(slot, isVideo: false); },
          ),
          ListTile(
            leading: Container(width:40,height:40,decoration:BoxDecoration(color:AppColors.primarySurface,shape:BoxShape.circle),
                child:const Icon(Icons.videocam_outlined,color:AppColors.primary)),
            title: const Text('Choose Video', style: AppText.bodyBold),
            onTap: () { Navigator.pop(context); _pickMedia(slot, isVideo: true); },
          ),
          if (slot < _mediaPaths.length)
            ListTile(
              leading: Container(width:40,height:40,decoration:BoxDecoration(color:AppColors.dangerLight,shape:BoxShape.circle),
                  child:const Icon(Icons.delete_outline,color:AppColors.danger)),
              title: const Text('Remove', style: AppText.bodyBold),
              textColor: AppColors.danger,
              onTap: () { Navigator.pop(context); setState(() => _mediaPaths.removeAt(slot)); },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _save(AppProvider pv) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uploadedPaths = await pv.uploadMedia(_mediaPaths);

      if (_isEdit) {
        await pv.updatePart(widget.part!.copyWith(
          name: _name.text.trim(), serialNumber: _serial.text.trim(),
          modelNumber: _model.text.trim(), years: _years.text.trim(),
          category: _category, carBrand: _brand, carModel: _carModel.text.trim(),
          stock: int.parse(_stock.text), price: int.parse(_price.text),
          mediaPaths: uploadedPaths,
        ));
      } else {
        await pv.addPart(PartModel(
          name: _name.text.trim(), serialNumber: _serial.text.trim(),
          modelNumber: _model.text.trim(), years: _years.text.trim(),
          category: _category, carBrand: _brand, carModel: _carModel.text.trim(),
          stock: int.parse(_stock.text), price: int.parse(_price.text),
          mediaPaths: uploadedPaths,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── Validation Dialogs ──────────────────────────────────────────────────
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.danger)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Check & Delete Category ─────────────────────────────────────────────
  void _confirmDeleteCategory(AppProvider pv) {
    if (_category.isEmpty) return;
    // Check if category is used in any part
    final isUsed = pv.parts.any((p) => p.category == _category);
    if (isUsed) {
      _showErrorDialog('Cannot Delete', 'This category "$_category" is currently used by one or more parts. Please delete or update those parts first.');
      return;
    }
    _showConfirmDialog('Delete Category', 'Are you sure you want to delete "$_category"?', () {
      pv.deleteCategory(_category);
      setState(() {
        _category = pv.categories.isNotEmpty ? pv.categories.first : '';
      });
    });
  }

  // ── Check & Delete Brand ────────────────────────────────────────────────
  void _confirmDeleteBrand(AppProvider pv) {
    if (_brand.isEmpty) return;
    // Check if brand is used in any part
    final isUsed = pv.parts.any((p) => p.carBrand == _brand);
    if (isUsed) {
      _showErrorDialog('Cannot Delete', 'This car brand "$_brand" is currently used by one or more parts. Please delete or update those parts first.');
      return;
    }
    _showConfirmDialog('Delete Brand', 'Are you sure you want to delete "$_brand"?', () {
      pv.deleteBrand(_brand);
      setState(() {
        _brand = pv.brands.isNotEmpty ? pv.brands.first : '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    if (_category.isEmpty && pv.categories.isNotEmpty) _category = pv.categories.first;
    if (_brand.isEmpty && pv.brands.isNotEmpty) _brand = pv.brands.first;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Part' : 'Add New Part')),
      body: Stack(
        children: [
          Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Media grid
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Photos / Videos', style: AppText.label),
                  Text('${_mediaPaths.length} / $_maxMedia',
                      style: AppText.caption.copyWith(color: AppColors.primary)),
                ]),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(_maxMedia, _mediaSlot),
                ),
                Text('Tap to add · Tap filled to change/remove',
                    style: AppText.caption.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 16),

                // ── Fields
                _field(_name, 'Part Name', hint: 'e.g. Brake Pad Set', required: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_serial, 'Serial Number', hint: 'e.g. BP-2024-001', required: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_model, 'Model Number', hint: 'e.g. TRW-GDB1234', required: true)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_years, 'Compatible Years', hint: 'e.g. 2018-2023')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_carModel, 'Car Model', hint: 'e.g. Camry')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_price, 'Price (Ks)', hint: '45000', required: true, numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(_stock, _isEdit ? 'Stock Count' : 'Initial Stock', hint: '24', required: true, numeric: true)),
                ]),
                const SizedBox(height: 14),

                // ── Category
                const Text('Category', style: AppText.label),
                const SizedBox(height: 4),
                _showNewCat
                    ? _newItemRow(_newCatCtrl, 'New category...', () {
                  final v = _newCatCtrl.text.trim();
                  if (v.isNotEmpty) { pv.addCategory(v); setState(() { _category=v; _showNewCat=false; _newCatCtrl.clear(); }); }
                }, () => setState(() => _showNewCat = false))
                    : _dropdownRow(
                  value: pv.categories.contains(_category) ? _category : null,
                  items: pv.categories,
                  onChanged: (v)=>setState(()=>_category=v!),
                  onAdd: ()=>setState(()=>_showNewCat=true),
                  onDelete: pv.categories.isNotEmpty ? () => _confirmDeleteCategory(pv) : null,
                ),
                const SizedBox(height: 14),

                // ── Brand
                const Text('Car Brand', style: AppText.label),
                const SizedBox(height: 4),
                _showNewBrand
                    ? _newItemRow(_newBrandCtrl, 'New brand...', () {
                  final v = _newBrandCtrl.text.trim();
                  if (v.isNotEmpty) { pv.addBrand(v); setState(() { _brand=v; _showNewBrand=false; _newBrandCtrl.clear(); }); }
                }, () => setState(() => _showNewBrand = false))
                    : _dropdownRow(
                  value: pv.brands.contains(_brand) ? _brand : null,
                  items: pv.brands,
                  onChanged: (v)=>setState(()=>_brand=v!),
                  onAdd: ()=>setState(()=>_showNewBrand=true),
                  onDelete: pv.brands.isNotEmpty ? () => _confirmDeleteBrand(pv) : null,
                ),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: _saving?null:()=>Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(pv),
                    icon: _saving
                        ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_saving ? 'Uploading...' : (_isEdit ? 'Save Changes' : 'Add Part')),
                  )),
                ]),
              ],
            ),
          ),

          // Full-screen upload overlay
          if (_saving)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Uploading to cloud...', style: AppText.bodyBold),
                      SizedBox(height: 4),
                      Text('Please wait', style: AppText.small),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaSlot(int i) {
    final hasMedia = i < _mediaPaths.length;
    final path = hasMedia ? _mediaPaths[i] : null;
    final isVid = path != null && isVideoPath(path);
    return GestureDetector(
      onTap: () => _showPickerSheet(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hasMedia ? null : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasMedia ? AppColors.primary : AppColors.border, width: hasMedia?1.5:1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: hasMedia
              ? Stack(fit: StackFit.expand, children: [
            isVid
                ? Container(color:AppColors.textPrimary, child:const Icon(Icons.videocam_outlined,color:Colors.white,size:26))
                : buildMediaImage(path!, fit: BoxFit.cover),
            Positioned(bottom:3,right:3,child:GestureDetector(
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MediaViewerScreen(mediaPaths:_mediaPaths,initialIndex:i))),
              child:Container(padding:const EdgeInsets.all(3),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(4)),
                  child:const Icon(Icons.fullscreen,color:Colors.white,size:12)),
            )),
            if (isVid) Positioned(top:3,left:3,child:Container(padding:const EdgeInsets.symmetric(horizontal:4,vertical:2),
                decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(4)),
                child:const Text('VID',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w800)))),
          ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add,size:22,color:i==0?AppColors.primaryLight:AppColors.border),
            if (i==0) Text('Add',style:TextStyle(fontSize:8,fontWeight:FontWeight.w600,color:AppColors.primaryLight)),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? hint, bool required=false, bool numeric=false}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label, hintText: hint, isDense: true),
        style: AppText.body,
        validator: required ? (v) => (v==null||v.trim().isEmpty)?'Required':null : null,
      );

  // ── Modified DropdownRow (Added Delete Button) ───────────────────────────
  Widget _dropdownRow({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required VoidCallback onAdd,
    VoidCallback? onDelete,
  }) =>
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          value: value, items: items.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
          onChanged: onChanged, decoration: const InputDecoration(isDense:true),
        )),
        const SizedBox(width: 8),
        InkWell(onTap: onAdd, borderRadius: BorderRadius.circular(8),
            child: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color:AppColors.primarySurface,borderRadius:BorderRadius.circular(8),
                    border:Border.all(color:AppColors.primary.withOpacity(0.3))),
                child: const Icon(Icons.add, size:18, color:AppColors.primary))),
        // Show delete button if onDelete is provided
        if (onDelete != null) ...[
          const SizedBox(width: 6),
          InkWell(onTap: onDelete, borderRadius: BorderRadius.circular(8),
              child: Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color:AppColors.dangerLight,borderRadius:BorderRadius.circular(8),
                      border:Border.all(color:AppColors.danger.withOpacity(0.3))),
                  child: const Icon(Icons.delete_outline, size:18, color:AppColors.danger))),
        ]
      ]);

  Widget _newItemRow(TextEditingController ctrl, String hint, VoidCallback onAdd, VoidCallback onCancel) =>
      Row(children: [
        Expanded(child: TextField(controller:ctrl,autofocus:true,decoration:InputDecoration(hintText:hint,isDense:true))),
        const SizedBox(width:8),
        ElevatedButton(onPressed:onAdd,child:const Text('Add')),
        const SizedBox(width:6),
        IconButton(onPressed:onCancel,icon:const Icon(Icons.close,size:18),color:AppColors.textHint),
      ]);
}