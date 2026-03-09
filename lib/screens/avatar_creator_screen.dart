import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../models/story_mode.dart';

class AvatarCreatorScreen extends StatefulWidget {
  final AgeGroup ageGroup;
  final bool isEditing;

  const AvatarCreatorScreen({
    super.key,
    required this.ageGroup,
    this.isEditing = false,
  });

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();

  // Avatar özellikleri
  int _selectedSkinIndex = 0;
  int _selectedHairStyleIndex = 0;
  int _selectedHairColorIndex = 0;
  int _selectedAccessoryIndex = 0;
  int _selectedFaceIndex = 0;
  int _selectedShirtIndex = 0;
  int _selectedPantsIndex = 0;
  int _selectedShoesStyleIndex = 0;
  int _selectedShoesColorIndex = 0;

  // Cinsiyet seçimi
  bool _isMale = true;

  // Dosya adları listeleri
  final List<String> _skinTints = [
    'tint1', 'tint2', 'tint3', 'tint4',
    'tint5', 'tint6', 'tint7', 'tint8',
  ];

  final List<String> _faceTypes = [
    'Neutral', 'Happy', 'Sad', 'Angry',
    'Surprised', 'Wink', 'Smile', 'Thinking'
  ];

  final List<String> _hairColors = [
    'Black', 'Blonde', 'Brown 1', 'Brown 2',
    'Grey', 'Red', 'Tan', 'White'
  ];

  final List<String> _pantsColors = [
    'Blue 1', 'Blue 2', 'Brown', 'Green',
    'Grey', 'Light Blue', 'Navy', 'Pine',
    'Red', 'Tan', 'White', 'Yellow'
  ];

  final List<String> _shirtColors = [
    'Blue', 'Green', 'Grey', 'Navy',
    'Pine', 'Red', 'White', 'Yellow'
  ];

  final List<String> _shoesColors = [
    'Black', 'Blue', 'Brown 1', 'Brown 2',
    'Grey', 'Red', 'Tan'
  ];

  // Aksesuar listesi
  final List<Map<String, String>> _accessories = [
    {'emoji': '❌', 'name': 'Yok'},
    {'emoji': '🧢', 'name': 'Şapka'},
    {'emoji': '👓', 'name': 'Gözlük'},
    {'emoji': '😷', 'name': 'Maske'},
    {'emoji': '🎀', 'name': 'Bandana'},
    {'emoji': '👑', 'name': 'Taç'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _checkInitialValues();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingAvatar();
      });
    }
  }

  void _checkInitialValues() {
    setState(() {
      _selectedSkinIndex = _selectedSkinIndex.clamp(0, _skinTints.length - 1);
      _selectedHairColorIndex = _selectedHairColorIndex.clamp(0, _hairColors.length - 1);
      _selectedShirtIndex = _selectedShirtIndex.clamp(0, _shirtColors.length - 1);
      _selectedPantsIndex = _selectedPantsIndex.clamp(0, _pantsColors.length - 1);
      _selectedShoesColorIndex = _selectedShoesColorIndex.clamp(0, _shoesColors.length - 1);
      _selectedAccessoryIndex = _selectedAccessoryIndex.clamp(0, _accessories.length - 1);
    });
  }

  void _loadExistingAvatar() {
    try {
      final storyService = Provider.of<StoryService>(context, listen: false);
      final avatar = storyService.progress?.avatar;
      if (avatar != null) {
        _nameController.text = avatar.odername;

        setState(() {
          _selectedSkinIndex = (avatar.skinIndex).clamp(0, _skinTints.length - 1);
          _selectedFaceIndex = (avatar.faceIndex).clamp(0, _faceTypes.length - 1);
          _selectedHairStyleIndex = (avatar.hairStyleIndex).clamp(0, 7);

          // Saç rengini bul
          final hairColorIndex = _hairColors.indexWhere((color) =>
          color.toLowerCase().replaceAll(' ', '') ==
              avatar.hairColorName.toLowerCase().replaceAll(' ', ''));
          _selectedHairColorIndex = hairColorIndex >= 0 ? hairColorIndex : 0;

          _selectedShirtIndex = (avatar.shirtIndex).clamp(0, _shirtColors.length - 1);
          _selectedPantsIndex = (avatar.pantsIndex).clamp(0, _pantsColors.length - 1);

          _selectedShoesStyleIndex = (avatar.shoesIndex).clamp(0, 4);

          // Ayakkabı rengini bul
          final shoesColorIndex = _shoesColors.indexWhere((color) =>
          color.toLowerCase().replaceAll(' ', '') ==
              avatar.shoesColorName.toLowerCase().replaceAll(' ', ''));
          _selectedShoesColorIndex = shoesColorIndex >= 0 ? shoesColorIndex : 0;

          _selectedAccessoryIndex = (avatar.accessoryIndex).clamp(0, _accessories.length - 1);
        });
      }
    } catch (e) {
      print('Error loading existing avatar: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // DOSYA YOLU FONKSİYONLARI (gelecekte kullanım için)
  // ignore: unused_element
  String _getSkinPath() {
    return 'assets/avatar/skin/${_skinTints[_selectedSkinIndex]}.png';
  }

  // ignore: unused_element
  String _getHairPath() {
    final color = _hairColors[_selectedHairColorIndex].toLowerCase().replaceAll(' ', '');
    final style = _selectedHairStyleIndex + 1;
    final gender = _isMale ? 'man' : 'woman';
    return 'assets/avatar/hair/${color}${gender}$style.png';
  }

  String _getFacePath() {
    return 'assets/avatar/face/face${_selectedFaceIndex + 1}.png';
  }

  // ignore: unused_element
  String _getShirtPath() {
    final color = _shirtColors[_selectedShirtIndex].toLowerCase();
    final style = _selectedShirtIndex + 1;
    return 'assets/avatar/shirts/${color}shirt$style.png';
  }

  // ignore: unused_element
  String _getPantsPath() {
    final color = _pantsColors[_selectedPantsIndex].toLowerCase().replaceAll(' ', '');
    return 'assets/avatar/pants/${color}_pants.png';
  }

  // ignore: unused_element
  String _getShoesPath() {
    final color = _shoesColors[_selectedShoesColorIndex].toLowerCase().replaceAll(' ', '');
    final style = _selectedShoesStyleIndex + 1;
    return 'assets/avatar/shoes/${color}shoe$style.png';
  }

  String _getAccessoryPath() {
    if (_selectedAccessoryIndex == 0) return '';
    final accessoryName = _accessories[_selectedAccessoryIndex]['name']!.toLowerCase();
    return 'assets/avatar/accessories/$accessoryName.png';
  }

  String _getSafeItem(List<String> list, int index, String defaultValue) {
    if (list.isEmpty) return defaultValue;
    if (index < 0 || index >= list.length) {
      return list.isNotEmpty ? list[0] : defaultValue;
    }
    return list[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - ORJİNAL BOYUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                    ),
                    const Expanded(
                      child: Text(
                        'Avatar Oluştur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Avatar Preview - ORJİNAL BOYUT
              _buildAvatarPreview(),

              const SizedBox(height: 12),

              // Name input - ORJİNAL BOYUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'İsmini gir...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cinsiyet seçimi - ORJİNAL BOYUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGenderButton('👦 Erkek', true),
                    const SizedBox(width: 12),
                    _buildGenderButton('👧 Kız', false),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Customization tabs - ORJİNAL BOYUT
              SizedBox(
                height: 40,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Ten'),
                    Tab(text: 'Yüz'),
                    Tab(text: 'Saç'),
                    Tab(text: 'Gömlek'),
                    Tab(text: 'Pantolon'),
                    Tab(text: 'Ayakkabı'),
                    Tab(text: 'Aksesuar'),
                  ],
                ),
              ),

              // Tab content - SADECE GRID ÖĞELERİ KÜÇÜLTÜLDÜ
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSkinSelector(),
                    _buildFaceSelector(),
                    _buildHairSelector(),
                    _buildShirtSelector(),
                    _buildPantsSelector(),
                    _buildShoesSelector(),
                    _buildAccessorySelector(),
                  ],
                ),
              ),

              // Save button - ORJİNAL BOYUT
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Macaraya Başla!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label, bool isMale) {
    return GestureDetector(
      onTap: () => _changeGender(isMale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isMale == isMale
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isMale == isMale ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  void _changeGender(bool isMale) {
    setState(() {
      _isMale = isMale;
      _selectedHairStyleIndex = 0;
    });
  }

  Widget _buildAvatarPreview() {
    const double size = 200;
    final double centerX = size / 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // =====================
          // ARKA PLAN
          // =====================
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6E78D6),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),

          ClipOval(
            child: Stack(
              children: [
                // =====================
                // GÖVDE (MERKEZ)
                // =====================
                Positioned(
                  top: 80,
                  left: centerX - 30,
                  child: Container(
                    width: 60,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _getShirtColor(_selectedShirtIndex),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

                // =====================
                // KOLLAR (SİMETRİK)
                // =====================
                Positioned(
                  top: 85,
                  left: centerX - 48,
                  child: _arm(),
                ),
                Positioned(
                  top: 85,
                  left: centerX + 34,
                  child: _arm(),
                ),

                // =====================
                // PANTOLON
                // =====================
                Positioned(
                  top: 145,
                  left: centerX - 26,
                  child: Container(
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getPantsColor(_selectedPantsIndex),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // =====================
                // AYAKKABILAR
                // =====================
                Positioned(
                  top: 175,
                  left: centerX - 30,
                  child: _shoe(),
                ),
                Positioned(
                  top: 175,
                  left: centerX + 6,
                  child: _shoe(),
                ),

                // =====================
                // KAFA
                // =====================
                Positioned(
                  top: 30,
                  left: centerX - 22,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getSkinColor(_selectedSkinIndex),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // =====================
                // SAÇ
                // =====================
                Positioned(
                  top: 26,
                  left: centerX - 22,
                  child: Container(
                    width: 44,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _getHairColor(_selectedHairColorIndex),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                ),

                // =====================
                // YÜZ
                // =====================
                Positioned(
                  top: 36,
                  left: centerX - 16,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: _buildAssetImage(
                      _getFacePath(),
                      placeholder: _buildHumanFacePlaceholder(),
                    ),
                  ),
                ),

                // =====================
                // AKSESUAR
                // =====================
                if (_selectedAccessoryIndex > 0)
                  Positioned(
                    top: 24,
                    left: centerX - 18,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: _buildAssetImage(_getAccessoryPath()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _arm() {
    return Container(
      width: 14,
      height: 44,
      decoration: BoxDecoration(
        color: _getShirtColor(_selectedShirtIndex),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _shoe() {
    return Container(
      width: 24,
      height: 12,
      decoration: BoxDecoration(
        color: _getShoesColor(_selectedShoesColorIndex),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }






  Widget _buildHumanFacePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFFFDBB4),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gözler
          Positioned(
            top: 20,
            left: 15,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 15,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Ağız
          Positioned(
            bottom: 15,
            child: Container(
              width: 30,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetImage(String path, {Widget? placeholder}) {
    if (path.isEmpty) return Container();

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print('Asset not found: $path');
        return placeholder ?? Container();
      },
    );
  }

  // SADECE GRID ÖĞELERİ ÇOK KÜÇÜK
  Widget _buildSkinSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(6), // Küçültüldü
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3, // Küçültüldü
        crossAxisSpacing: 3, // Küçültüldü
        childAspectRatio: 6.7, // Daha dik
      ),
      itemCount: _skinTints.length,
      itemBuilder: (context, index) {
        return _buildSelectionItem(
          index: index,
          selectedIndex: _selectedSkinIndex,
          onTap: () => setState(() => _selectedSkinIndex = index),
          child: Container(
            width: 16, // ÇOK KÜÇÜK
            height: 16, // ÇOK KÜÇÜK
            decoration: BoxDecoration(
              color: _getSkinColor(index),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          label: '${index + 1}',
        );
      },
    );
  }

  Color _getSkinColor(int index) {
    final safeIndex = index.clamp(0, 7);
    final colors = [
      const Color(0xFFFFDBB4),
      const Color(0xFFE0AC69),
      const Color(0xFFC68642),
      const Color(0xFF8D5524),
      const Color(0xFFFFF8E1),
      const Color(0xFFD7CCC8),
      const Color(0xFFBCAAA4),
      const Color(0xFF8B6B61),
    ];
    return colors[safeIndex];
  }

  Widget _buildFaceSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(6), // Küçültüldü
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3, // Küçültüldü
        crossAxisSpacing: 3, // Küçültüldü
        childAspectRatio: 6.7, // Daha dik
      ),
      itemCount: _faceTypes.length,
      itemBuilder: (context, index) {
        return _buildSelectionItem(
          index: index,
          selectedIndex: _selectedFaceIndex,
          onTap: () => setState(() => _selectedFaceIndex = index),
          child: SizedBox(
            width: 16, // ÇOK KÜÇÜK
            height: 16, // ÇOK KÜÇÜK
            child: _buildAssetImage(
              _getFacePath(),
              placeholder: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBB4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          label: _faceTypes[index],
        );
      },
    );
  }

  Widget _buildHairSelector() {
    return Column(
      children: [

        // =========================
        // SAÇ RENGİ (YUKARIDA)
        // =========================
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Saç Rengi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _hairColors.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedHairColorIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedHairColorIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getHairColor(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _hairColors[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // =========================
        // SAÇ STİLİ BAŞLIK
        // =========================
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Saç Stili (${_isMale ? 'Erkek' : 'Kız'} 1-8)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // =========================
        // SAÇ STİLİ GRID (ORTADA)
        // =========================
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 6.5,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              final isSelected = _selectedHairStyleIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedHairStyleIndex = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _getHairColor(_selectedHairColorIndex),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Color _getHairColor(int index) {
    final safeIndex = index.clamp(0, _hairColors.length - 1);
    final colors = [
      Colors.black,
      const Color(0xFFD4B483),
      const Color(0xFF8B4513),
      const Color(0xFF654321),
      Colors.grey,
      Colors.red,
      const Color(0xFFD2691E),
      Colors.white,
    ];
    return safeIndex < colors.length ? colors[safeIndex] : Colors.black;
  }

  Widget _buildShirtSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(6), // Küçültüldü
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3, // Küçültüldü
        crossAxisSpacing: 3, // Küçültüldü
        childAspectRatio: 6.7, // Daha dik
      ),
      itemCount: _shirtColors.length,
      itemBuilder: (context, index) {
        return _buildSelectionItem(
          index: index,
          selectedIndex: _selectedShirtIndex,
          onTap: () => setState(() => _selectedShirtIndex = index),
          child: Container(
            width: 16, // ÇOK KÜÇÜK
            height: 16, // ÇOK KÜÇÜK
            decoration: BoxDecoration(
              color: _getShirtColor(index),
              borderRadius: BorderRadius.circular(3), // Küçültüldü
            ),
            child: Icon(
              Icons.checkroom,
              color: Colors.white.withOpacity(0.8),
              size: 12, // ÇOK KÜÇÜK
            ),
          ),
          label: _shirtColors[index],
        );
      },
    );
  }

  Color _getShirtColor(int index) {
    final safeIndex = index.clamp(0, _shirtColors.length - 1);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.grey,
      Colors.indigo,
      Colors.green.shade800,
      Colors.red,
      Colors.white,
      Colors.yellow,
    ];
    return safeIndex < colors.length ? colors[safeIndex] : Colors.blue;
  }

  Widget _buildPantsSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(6), // Küçültüldü
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3, // Küçültüldü
        crossAxisSpacing: 3, // Küçültüldü
        childAspectRatio: 6.7, // Daha dik
      ),
      itemCount: _pantsColors.length,
      itemBuilder: (context, index) {
        return _buildSelectionItem(
          index: index,
          selectedIndex: _selectedPantsIndex,
          onTap: () => setState(() => _selectedPantsIndex = index),
          child: Container(
            width: 16, // ÇOK KÜÇÜK
            height: 16, // ÇOK KÜÇÜK
            decoration: BoxDecoration(
              color: _getPantsColor(index),
              borderRadius: BorderRadius.circular(3), // Küçültüldü
            ),
            child: Icon(
              Icons.style,
              color: Colors.white.withOpacity(0.8),
              size: 12, // ÇOK KÜÇÜK
            ),
          ),
          label: _pantsColors[index],
        );
      },
    );
  }

  Color _getPantsColor(int index) {
    final safeIndex = index.clamp(0, _pantsColors.length - 1);
    final colors = [
      Colors.blue.shade300,
      Colors.blue.shade500,
      Colors.brown,
      Colors.green,
      Colors.grey,
      Colors.lightBlue,
      Colors.indigo,
      Colors.green.shade800,
      Colors.red,
      const Color(0xFFD2B48C),
      Colors.white,
      Colors.yellow,
    ];
    return safeIndex < colors.length ? colors[safeIndex] : Colors.blue;
  }

  Widget _buildShoesSelector() {
    return Column(
      children: [

        // =========================
        // AYAKKABI RENGİ (YUKARIDA)
        // =========================
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Ayakkabı Rengi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _shoesColors.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedShoesColorIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedShoesColorIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getShoesColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // =========================
        // AYAKKABI STİLİ BAŞLIK
        // =========================
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Ayakkabı Stili (1-5)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // =========================
        // AYAKKABI STİLİ GRID (ORTADA)
        // =========================
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 6.5,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final isSelected = _selectedShoesStyleIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedShoesStyleIndex = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.35)
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _getShoesColor(_selectedShoesColorIndex),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.directions_walk,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Color _getShoesColor(int index) {
    final safeIndex = index.clamp(0, _shoesColors.length - 1);
    final colors = [
      Colors.black,
      Colors.blue,
      Colors.brown,
      Colors.brown.shade800,
      Colors.grey,
      Colors.red,
      const Color(0xFFD2B48C),
    ];
    return safeIndex < colors.length ? colors[safeIndex] : Colors.black;
  }

  Widget _buildAccessorySelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(6), // Küçültüldü
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3, // Küçültüldü
        crossAxisSpacing: 3, // Küçültüldü
        childAspectRatio: 6.7, // Daha dik
      ),
      itemCount: _accessories.length,
      itemBuilder: (context, index) {
        final accessory = _accessories[index];
        return _buildSelectionItem(
          index: index,
          selectedIndex: _selectedAccessoryIndex,
          onTap: () => setState(() => _selectedAccessoryIndex = index),
          child: Text(
            accessory['emoji']!,
            style: const TextStyle(fontSize: 16), // Küçültüldü
          ),
          label: accessory['name']!,
        );
      },
    );
  }

  // Grid öğeleri için selection item - ÇOK KÜÇÜK
  Widget _buildSelectionItem({
    required int index,
    required int selectedIndex,
    required VoidCallback onTap,
    required Widget child,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2), // ÇOK KÜÇÜK
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5), // Küçültüldü
          border: Border.all(
            color: selectedIndex == index ? Colors.white : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18, // ÇOK KÜÇÜK
              height: 18, // ÇOK KÜÇÜK
              child: Center(child: child),
            ),
            const SizedBox(height: 1), // ÇOK KÜÇÜK
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7, // ÇOK KÜÇÜK
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAvatar() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir isim girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final storyService = Provider.of<StoryService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final avatar = PlayerAvatar(
      oderId: authService.currentUser?.uid ?? '',
      odername: name,

      // Avatar parçaları
      skinIndex: _selectedSkinIndex,
      faceIndex: _selectedFaceIndex,
      hairStyleIndex: _selectedHairStyleIndex,
      hairColorName: _getSafeItem(_hairColors, _selectedHairColorIndex, 'Black'),
      shirtIndex: _selectedShirtIndex,
      pantsIndex: _selectedPantsIndex,
      pantsColorName: _getSafeItem(_pantsColors, _selectedPantsIndex, 'Blue 1'),
      shoesIndex: _selectedShoesStyleIndex,
      shoesColorName: _getSafeItem(_shoesColors, _selectedShoesColorIndex, 'Black'),
      accessoryIndex: _selectedAccessoryIndex,

      // Seviye/exp
      level: storyService.progress?.avatar.level ?? 1,
      experience: storyService.progress?.avatar.experience ?? 0,
    );

    await storyService.updateAvatar(avatar);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}