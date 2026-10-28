import 'package:flutter/material.dart';

/// Kategori grubu (seçicide başlık olarak görünür).
class EventCategoryGroup {
  const EventCategoryGroup(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

/// Etkinlik kategorisi. `id` Firestore'a yazılan değerdir, DEĞİŞTİRME (yalnızca yeni kimlik ekle).
/// Profildeki ilgi alanları da aynı kimlikleri kullanır. Kimlikler 1-30 karakter (firestore.rules).
class EventCategory {
  const EventCategory(this.id, this.label, this.icon, this.group);

  final String id;
  final String label;
  final IconData icon;
  final EventCategoryGroup group;

  static const EventCategoryGroup _gsports =
      EventCategoryGroup('sports', 'Spor ve hareket', Icons.sports_soccer);
  static const EventCategoryGroup _goutdoor =
      EventCategoryGroup('outdoor', 'Doğa ve açık hava', Icons.park);
  static const EventCategoryGroup _gfood =
      EventCategoryGroup('food', 'Yeme içme', Icons.local_cafe);
  static const EventCategoryGroup _gsocial =
      EventCategoryGroup('social', 'Sosyal ve eğlence', Icons.groups);
  static const EventCategoryGroup _garts =
      EventCategoryGroup('arts', 'Müzik ve sanat', Icons.palette);
  static const EventCategoryGroup _glearning =
      EventCategoryGroup('learning', 'Öğrenme ve kariyer', Icons.school);
  static const EventCategoryGroup _gwellness =
      EventCategoryGroup('wellness', 'Sağlıklı yaşam', Icons.favorite);
  static const EventCategoryGroup _gpets =
      EventCategoryGroup('pets', 'Evcil hayvan', Icons.pets);
  static const EventCategoryGroup _gvolunteer =
      EventCategoryGroup('volunteer', 'Gönüllülük', Icons.volunteer_activism);
  static const EventCategoryGroup _gtravel =
      EventCategoryGroup('travel', 'Gezi ve seyahat', Icons.flight);
  static const EventCategoryGroup _ghobby =
      EventCategoryGroup('hobby', 'Hobi ve tutku', Icons.collections);

  static const List<EventCategoryGroup> groups = <EventCategoryGroup>[
    _gsports,
    _goutdoor,
    _gfood,
    _gsocial,
    _garts,
    _glearning,
    _gwellness,
    _gpets,
    _gvolunteer,
    _gtravel,
    _ghobby,
  ];

  static const List<EventCategory> all = <EventCategory>[
    EventCategory('sport', 'Spor (genel)', Icons.sports_soccer, _gsports),
    EventCategory('football', 'Futbol', Icons.sports_soccer, _gsports),
    EventCategory('basketball', 'Basketbol', Icons.sports_basketball, _gsports),
    EventCategory('volleyball', 'Voleybol', Icons.sports_volleyball, _gsports),
    EventCategory('tennis', 'Tenis', Icons.sports_tennis, _gsports),
    EventCategory('padel', 'Padel', Icons.sports_tennis, _gsports),
    EventCategory('badminton', 'Badminton', Icons.sports_tennis, _gsports),
    EventCategory('table_tennis', 'Masa tenisi', Icons.sports_tennis, _gsports),
    EventCategory('handball', 'Hentbol', Icons.sports_handball, _gsports),
    EventCategory('baseball', 'Beyzbol', Icons.sports_baseball, _gsports),
    EventCategory('american_football', 'Amerikan futbolu', Icons.sports_football, _gsports),
    EventCategory('rugby', 'Ragbi', Icons.sports_rugby, _gsports),
    EventCategory('hockey', 'Hokey', Icons.sports_hockey, _gsports),
    EventCategory('golf', 'Golf', Icons.sports_golf, _gsports),
    EventCategory('running', 'Koşu', Icons.directions_run, _gsports),
    EventCategory('swimming', 'Yüzme', Icons.pool, _gsports),
    EventCategory('fitness', 'Fitness', Icons.fitness_center, _gsports),
    EventCategory('crossfit', 'CrossFit', Icons.fitness_center, _gsports),
    EventCategory('zumba', 'Zumba', Icons.music_note, _gsports),
    EventCategory('pilates', 'Pilates', Icons.self_improvement, _gsports),
    EventCategory('yoga', 'Yoga', Icons.self_improvement, _gsports),
    EventCategory('boxing', 'Boks', Icons.sports_mma, _gsports),
    EventCategory('martial_arts', 'Dövüş sanatları', Icons.sports_martial_arts, _gsports),
    EventCategory('climbing', 'Tırmanış', Icons.terrain, _gsports),
    EventCategory('skating', 'Paten', Icons.roller_skating, _gsports),
    EventCategory('skateboard', 'Kaykay', Icons.skateboarding, _gsports),
    EventCategory('ice_skating', 'Buz pateni', Icons.ice_skating, _gsports),
    EventCategory('skiing', 'Kayak', Icons.downhill_skiing, _gsports),
    EventCategory('snowboard', 'Snowboard', Icons.snowboarding, _gsports),
    EventCategory('cycling', 'Bisiklet', Icons.directions_bike, _gsports),
    EventCategory('mountain_bike', 'Dağ bisikleti', Icons.pedal_bike, _gsports),
    EventCategory('kayaking', 'Kano ve kürek', Icons.kayaking, _gsports),
    EventCategory('surfing', 'Sörf', Icons.surfing, _gsports),
    EventCategory('sailing', 'Yelken', Icons.sailing, _gsports),
    EventCategory('diving', 'Dalış', Icons.scuba_diving, _gsports),
    EventCategory('archery', 'Okçuluk', Icons.my_location, _gsports),
    EventCategory('horse_riding', 'Binicilik', Icons.pets, _gsports),
    EventCategory('cricket', 'Kriket', Icons.sports_cricket, _gsports),
    EventCategory('walking', 'Yürüyüş', Icons.directions_walk, _goutdoor),
    EventCategory('hiking', 'Doğa yürüyüşü', Icons.hiking, _goutdoor),
    EventCategory('camping', 'Kamp', Icons.nights_stay, _goutdoor),
    EventCategory('picnic', 'Piknik', Icons.park, _goutdoor),
    EventCategory('fishing', 'Balık tutma', Icons.phishing, _goutdoor),
    EventCategory('bird_watching', 'Kuş gözlemi', Icons.visibility, _goutdoor),
    EventCategory('stargazing', 'Yıldız gözlemi', Icons.star_border, _goutdoor),
    EventCategory('photo_walk', 'Fotoğraf yürüyüşü', Icons.photo_camera, _goutdoor),
    EventCategory('beach', 'Plaj', Icons.beach_access, _goutdoor),
    EventCategory('paragliding', 'Yamaç paraşütü', Icons.paragliding, _goutdoor),
    EventCategory('caravan', 'Karavan', Icons.rv_hookup, _goutdoor),
    EventCategory('gardening', 'Bahçecilik', Icons.yard, _goutdoor),
    EventCategory('nature_cleanup', 'Doğa temizliği', Icons.recycling, _goutdoor),
    EventCategory('coffee', 'Kahve ve sohbet', Icons.local_cafe, _gfood),
    EventCategory('tea', 'Çay sohbeti', Icons.emoji_food_beverage, _gfood),
    EventCategory('breakfast', 'Kahvaltı', Icons.free_breakfast, _gfood),
    EventCategory('brunch', 'Brunch', Icons.brunch_dining, _gfood),
    EventCategory('lunch', 'Öğle yemeği', Icons.lunch_dining, _gfood),
    EventCategory('dinner', 'Akşam yemeği', Icons.dinner_dining, _gfood),
    EventCategory('street_food', 'Sokak lezzetleri', Icons.fastfood, _gfood),
    EventCategory('food_tour', 'Yemek turu', Icons.ramen_dining, _gfood),
    EventCategory('cooking', 'Yemek yapma', Icons.restaurant, _gfood),
    EventCategory('baking', 'Pasta ve fırın', Icons.bakery_dining, _gfood),
    EventCategory('dessert', 'Tatlı buluşması', Icons.cake, _gfood),
    EventCategory('bbq', 'Mangal', Icons.outdoor_grill, _gfood),
    EventCategory('vegan', 'Vegan ve vejetaryen', Icons.eco, _gfood),
    EventCategory('games', 'Oyun (genel)', Icons.sports_esports, _gsocial),
    EventCategory('board_games', 'Kutu oyunları', Icons.casino, _gsocial),
    EventCategory('card_games', 'Kart oyunları', Icons.style, _gsocial),
    EventCategory('chess', 'Satranç', Icons.grid_view, _gsocial),
    EventCategory('puzzle', 'Puzzle ve zeka oyunları', Icons.extension, _gsocial),
    EventCategory('video_games', 'Video oyunları', Icons.videogame_asset, _gsocial),
    EventCategory('trivia', 'Bilgi yarışması', Icons.quiz, _gsocial),
    EventCategory('escape_room', 'Kaçış odası', Icons.meeting_room, _gsocial),
    EventCategory('karaoke', 'Karaoke', Icons.mic, _gsocial),
    EventCategory('party', 'Parti ve kutlama', Icons.celebration, _gsocial),
    EventCategory('dance', 'Dans', Icons.nightlife, _gsocial),
    EventCategory('folk_dance', 'Halk oyunları', Icons.diversity_3, _gsocial),
    EventCategory('networking', 'Tanışma ve networking', Icons.handshake, _gsocial),
    EventCategory('new_in_town', 'Şehre yeni gelenler', Icons.waving_hand, _gsocial),
    EventCategory('language_exchange', 'Dil değişimi', Icons.translate, _gsocial),
    EventCategory('book_club', 'Kitap kulübü', Icons.menu_book, _gsocial),
    EventCategory('movie', 'Sinema', Icons.movie, _gsocial),
    EventCategory('series', 'Dizi ve film izleme', Icons.tv, _gsocial),
    EventCategory('theater', 'Tiyatro', Icons.theater_comedy, _gsocial),
    EventCategory('standup', 'Stand-up', Icons.mic_external_on, _gsocial),
    EventCategory('coworking', 'Birlikte çalışma', Icons.computer, _gsocial),
    EventCategory('chat', 'Sohbet ve tanışma', Icons.forum, _gsocial),
    EventCategory('music', 'Müzik (genel)', Icons.music_note, _garts),
    EventCategory('concert', 'Konser', Icons.queue_music, _garts),
    EventCategory('jam', 'Jam session', Icons.piano, _garts),
    EventCategory('choir', 'Koro', Icons.record_voice_over, _garts),
    EventCategory('music_lessons', 'Müzik pratiği', Icons.library_music, _garts),
    EventCategory('art', 'Sanat (genel)', Icons.palette, _garts),
    EventCategory('painting', 'Resim', Icons.brush, _garts),
    EventCategory('drawing', 'Çizim', Icons.draw, _garts),
    EventCategory('pottery', 'Seramik', Icons.auto_fix_high, _garts),
    EventCategory('crafts', 'El sanatları', Icons.content_cut, _garts),
    EventCategory('knitting', 'Örgü ve dikiş', Icons.checkroom, _garts),
    EventCategory('photography', 'Fotoğrafçılık', Icons.photo_camera, _garts),
    EventCategory('film_making', 'Film çekimi', Icons.movie_creation, _garts),
    EventCategory('writing', 'Yazarlık', Icons.edit_note, _garts),
    EventCategory('poetry', 'Şiir', Icons.auto_stories, _garts),
    EventCategory('museum', 'Müze gezisi', Icons.museum, _garts),
    EventCategory('exhibition', 'Sergi gezisi', Icons.image, _garts),
    EventCategory('history_tour', 'Tarihi gezi', Icons.account_balance, _garts),
    EventCategory('architecture', 'Mimari gezi', Icons.architecture, _garts),
    EventCategory('learning', 'Öğrenme (genel)', Icons.school, _glearning),
    EventCategory('study_group', 'Ders çalışma grubu', Icons.menu_book, _glearning),
    EventCategory('language', 'Dil pratiği', Icons.language, _glearning),
    EventCategory('coding', 'Yazılım', Icons.code, _glearning),
    EventCategory('electronics', 'Elektronik ve maker', Icons.developer_board, _glearning),
    EventCategory('robotics', 'Robotik', Icons.smart_toy, _glearning),
    EventCategory('ai', 'Yapay zeka', Icons.memory, _glearning),
    EventCategory('design', 'Tasarım', Icons.design_services, _glearning),
    EventCategory('startup', 'Girişimcilik', Icons.rocket_launch, _glearning),
    EventCategory('career', 'Kariyer sohbeti', Icons.work, _glearning),
    EventCategory('mentoring', 'Mentorluk', Icons.supervisor_account, _glearning),
    EventCategory('workshop', 'Atölye', Icons.construction, _glearning),
    EventCategory('seminar', 'Seminer ve konferans', Icons.co_present, _glearning),
    EventCategory('science', 'Bilim', Icons.science, _glearning),
    EventCategory('astronomy', 'Astronomi', Icons.public, _glearning),
    EventCategory('personal_dev', 'Kişisel gelişim', Icons.psychology, _glearning),
    EventCategory('investing', 'Yatırım sohbeti', Icons.trending_up, _glearning),
    EventCategory('diy', 'Kendin yap', Icons.handyman, _glearning),
    EventCategory('meditation', 'Meditasyon', Icons.self_improvement, _gwellness),
    EventCategory('breathwork', 'Nefes çalışması', Icons.air, _gwellness),
    EventCategory('wellness', 'Sağlıklı yaşam', Icons.favorite, _gwellness),
    EventCategory('stretching', 'Esneme', Icons.accessibility_new, _gwellness),
    EventCategory('dog_walk', 'Köpek gezdirme', Icons.pets, _gpets),
    EventCategory('pet_meetup', 'Evcil hayvan buluşması', Icons.pets, _gpets),
    EventCategory('volunteering', 'Gönüllülük (genel)', Icons.volunteer_activism, _gvolunteer),
    EventCategory('charity', 'Yardım etkinliği', Icons.redeem, _gvolunteer),
    EventCategory('animal_shelter', 'Hayvan barınağı', Icons.pets, _gvolunteer),
    EventCategory('tree_planting', 'Fidan dikimi', Icons.forest, _gvolunteer),
    EventCategory('community', 'Mahalle etkinliği', Icons.location_city, _gvolunteer),
    EventCategory('travel', 'Gezi (genel)', Icons.flight, _gtravel),
    EventCategory('road_trip', 'Yol gezisi', Icons.directions_car, _gtravel),
    EventCategory('city_tour', 'Şehir turu', Icons.tour, _gtravel),
    EventCategory('day_trip', 'Günübirlik gezi', Icons.wb_sunny, _gtravel),
    EventCategory('weekend_getaway', 'Hafta sonu kaçamağı', Icons.luggage, _gtravel),
    EventCategory('backpacking', 'Sırt çantalı gezi', Icons.backpack, _gtravel),
    EventCategory('cultural_trip', 'Kültür turu', Icons.temple_buddhist, _gtravel),
    EventCategory('collecting', 'Koleksiyon', Icons.collections, _ghobby),
    EventCategory('cars', 'Otomobil tutkunları', Icons.directions_car, _ghobby),
    EventCategory('motorcycle', 'Motosiklet', Icons.two_wheeler, _ghobby),
    EventCategory('drones', 'Dron ve RC', Icons.flight, _ghobby),
    EventCategory('astronomy_club', 'Teleskop buluşması', Icons.travel_explore, _ghobby),
    EventCategory('fashion', 'Moda ve stil', Icons.checkroom, _ghobby),
    EventCategory('other', 'Diğer', Icons.category, _ghobby),
  ];

  static final Map<String, EventCategory> _byId = <String, EventCategory>{
    for (final category in all) category.id: category,
  };

  /// Eski kodla uyumluluk için sık kullanılan kategoriler.
  static EventCategory get other => _byId['other']!;
  static EventCategory get yoga => _byId['yoga']!;

  /// Bilinmeyen kimlikte `other` döner (eski/hatalı veriye karşı güvenli).
  static EventCategory byId(String id) => _byId[id] ?? other;

  static bool isValidId(String id) => _byId.containsKey(id);

  static List<EventCategory> inGroup(EventCategoryGroup group) =>
      all.where((category) => category.group.id == group.id).toList();
}
