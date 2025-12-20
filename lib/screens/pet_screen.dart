import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/avatar_customization.dart';
import '../localization/app_localizations.dart';

/// Evcil Hayvan Ekranı
class PetScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Pet? activePet;
  final List<Pet> ownedPets;
  final int userCoins;
  final Function(Pet)? onSelectPet;
  final Function(Pet)? onPurchasePet;

  const PetScreen({
    super.key,
    required this.onBack,
    this.activePet,
    this.ownedPets = const [],
    this.userCoins = 0,
    this.onSelectPet,
    this.onPurchasePet,
  });

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  Pet? _selectedPet;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.activePet;
    _coins = widget.userCoins;

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  bool _isPetOwned(Pet pet) {
    return widget.ownedPets.any((p) => p.id == pet.id);
  }

  void _feedPet() {
    if (_selectedPet == null || !_selectedPet!.isHungry) return;
    
    setState(() {
      _selectedPet!.feed();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedPet!.name} beslendi! +10 XP 🍎'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _playWithPet() {
    if (_selectedPet == null) return;
    
    setState(() {
      _selectedPet!.play();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedPet!.name} ile oynadın! +5 XP 🎾'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _purchasePet(Pet pet) {
    if (_coins < pet.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeterli altın yok! 😢'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(pet.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pet.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu evcil hayvanı satın almak ister misin?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '${pet.cost}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _coins -= pet.cost;
              });
              widget.onPurchasePet?.call(pet);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pet.name} ailene katıldı! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('SATIN AL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              _buildTopBar(),

              // Aktif evcil hayvan
              if (_selectedPet != null) _buildActivePetArea(),

              // Evcil hayvan listesi
              Expanded(
                child: _buildPetsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '🐾 Evcil Hayvanlarım',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePetArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Evcil hayvan animasyonu
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Text(
                  _selectedPet!.emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // İsim ve seviye
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedPet!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv.${_selectedPet!.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // XP barı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Deneyim',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    '${_selectedPet!.experience}/${_selectedPet!.experienceToNextLevel}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _selectedPet!.experienceProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.amber),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mutluluk barı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '❤️ Mutluluk',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    '${_selectedPet!.happiness}%',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _selectedPet!.happiness / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                    _selectedPet!.happiness > 50 ? Colors.green : Colors.red,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  emoji: '🍎',
                  text: 'Besle',
                  onTap: _selectedPet!.isHungry ? _feedPet : null,
                  color: _selectedPet!.isHungry ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  emoji: '🎾',
                  text: 'Oyna',
                  onTap: _playWithPet,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String text,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: onTap != null ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsList() {
    final allPets = Pet.allPets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🛒 Evcil Hayvan Mağazası',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: allPets.length,
          itemBuilder: (context, index) {
            final pet = allPets[index];
            final isOwned = _isPetOwned(pet);
            final isActive = _selectedPet?.id == pet.id;

            return GestureDetector(
              onTap: () {
                if (isOwned) {
                  final ownedPet = widget.ownedPets.firstWhere((p) => p.id == pet.id);
                  setState(() {
                    _selectedPet = ownedPet;
                  });
                  widget.onSelectPet?.call(ownedPet);
                } else {
                  _purchasePet(pet);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.amber.withOpacity(0.4)
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.amber : Colors.white.withOpacity(0.2),
                    width: isActive ? 3 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pet.emoji,
                            style: TextStyle(
                              fontSize: 48,
                              color: isOwned ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pet.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isOwned ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isOwned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '✓ Sahip',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 14)),
                                Text(
                                  '${pet.cost}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (pet.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

