import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import '../models/story_mode.dart';
import '../localization/app_localizations.dart';

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
  int _selectedOutfitIndex = 0;
  int _selectedAccessoryIndex = 0;

  final List<String> _skinColors = ['🧒🏻', '🧒🏼', '🧒🏽', '🧒🏾', '🧒🏿'];
  final List<String> _hairStyles = ['💇', '💇‍♀️', '👨‍🦱', '👩‍🦱', '👨‍🦰', '👩‍🦰', '👱', '👱‍♀️'];
  final List<Color> _hairColors = [
    Colors.black,
    Colors.brown,
    Colors.amber,
    Colors.red,
    Colors.blue,
    Colors.purple,
    Colors.pink,
  ];
  final List<String> _outfits = ['👕', '👚', '🥋', '🎽', '👔', '🧥', '🦺', '👗'];
  final List<String> _accessories = ['❌', '🎩', '👑', '🎀', '🧢', '🎭', '👓', '🦸'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    if (widget.isEditing) {
      _loadExistingAvatar();
    }
  }

  void _loadExistingAvatar() {
    final storyService = Provider.of<StoryService>(context, listen: false);
    final avatar = storyService.progress?.avatar;
    if (avatar != null) {
      _nameController.text = avatar.odername;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentLocale = authService.currentUser?.selectedLanguage ?? 'tr';
    final localizations = AppLocalizations(Locale(currentLocale));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        localizations.get('create_avatar'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Avatar Preview
              _buildAvatarPreview(),

              const SizedBox(height: 16),

              // Name input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: localizations.get('enter_name'),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Customization tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  isScrollable: true,
                  tabs: [
                    Tab(text: localizations.get('skin')),
                    Tab(text: localizations.get('hair')),
                    Tab(text: localizations.get('hair_color')),
                    Tab(text: localizations.get('outfit')),
                    Tab(text: localizations.get('accessory')),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSkinSelector(),
                    _buildHairStyleSelector(),
                    _buildHairColorSelector(),
                    _buildOutfitSelector(),
                    _buildAccessorySelector(),
                  ],
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isEditing
                              ? localizations.get('save_changes')
                              : localizations.get('start_adventure'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
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

  Widget _buildAvatarPreview() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base character
          Text(
            _skinColors[_selectedSkinIndex],
            style: const TextStyle(fontSize: 70),
          ),
          // Accessory
          if (_selectedAccessoryIndex != 0)
            Positioned(
              top: 10,
              child: Text(
                _accessories[_selectedAccessoryIndex],
                style: const TextStyle(fontSize: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkinSelector() {
    return _buildItemGrid(
      items: _skinColors,
      selectedIndex: _selectedSkinIndex,
      onSelect: (index) => setState(() => _selectedSkinIndex = index),
      isEmoji: true,
    );
  }

  Widget _buildHairStyleSelector() {
    return _buildItemGrid(
      items: _hairStyles,
      selectedIndex: _selectedHairStyleIndex,
      onSelect: (index) => setState(() => _selectedHairStyleIndex = index),
      isEmoji: true,
    );
  }

  Widget _buildHairColorSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _hairColors.length,
      itemBuilder: (context, index) {
        final isSelected = index == _selectedHairColorIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedHairColorIndex = index),
          child: Container(
            decoration: BoxDecoration(
              color: _hairColors[index],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _hairColors[index].withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutfitSelector() {
    return _buildItemGrid(
      items: _outfits,
      selectedIndex: _selectedOutfitIndex,
      onSelect: (index) => setState(() => _selectedOutfitIndex = index),
      isEmoji: true,
    );
  }

  Widget _buildAccessorySelector() {
    return _buildItemGrid(
      items: _accessories,
      selectedIndex: _selectedAccessoryIndex,
      onSelect: (index) => setState(() => _selectedAccessoryIndex = index),
      isEmoji: true,
    );
  }

  Widget _buildItemGrid({
    required List<String> items,
    required int selectedIndex,
    required Function(int) onSelect,
    required bool isEmoji,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                items[index],
                style: const TextStyle(fontSize: 35),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAvatar() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<AuthService>(context, listen: false)
                    .currentUser
                    ?.selectedLanguage ==
                'en'
                ? 'Please enter a name'
                : 'Lütfen bir isim girin',
          ),
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
      skinColor: _skinColors[_selectedSkinIndex],
      hairStyle: _hairStyles[_selectedHairStyleIndex],
      hairColor: _hairColors[_selectedHairColorIndex].value.toString(),
      outfit: _outfits[_selectedOutfitIndex],
      accessory: _accessories[_selectedAccessoryIndex],
      level: storyService.progress?.avatar.level ?? 1,
      experience: storyService.progress?.avatar.experience ?? 0,
    );

    await storyService.updateAvatar(avatar);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}

