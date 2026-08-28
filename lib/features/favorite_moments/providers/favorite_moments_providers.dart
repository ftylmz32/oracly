/// Favorite moments — Riverpod wiring.

library;



import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../app/providers/app_providers.dart';

import '../data/local_favorite_moments_repository.dart';

import '../models/favorite_moment.dart';

import '../services/favorite_moments_service.dart';



final favoriteMomentsRepositoryProvider =

    Provider<LocalFavoriteMomentsRepository>((ref) {

  return LocalFavoriteMomentsRepository(ref.watch(localStorageProvider));

});



final favoriteMomentsServiceProvider = Provider<FavoriteMomentsService>((ref) {

  return FavoriteMomentsService(ref.watch(favoriteMomentsRepositoryProvider));

});



final favoriteMomentsProvider =

    AsyncNotifierProvider<FavoriteMomentsNotifier, List<FavoriteMoment>>(

  FavoriteMomentsNotifier.new,

);



final favoriteMomentSavedProvider =

    Provider.family<bool, String>((ref, id) {

  final items = ref.watch(favoriteMomentsProvider).valueOrNull ?? const [];

  return items.any((item) => item.id == id);

});



class FavoriteMomentsNotifier extends AsyncNotifier<List<FavoriteMoment>> {

  @override

  Future<List<FavoriteMoment>> build() =>

      ref.read(favoriteMomentsServiceProvider).all();



  Future<void> save(FavoriteMoment moment) async {

    await ref.read(favoriteMomentsServiceProvider).save(moment);

    ref.invalidateSelf();

  }



  Future<void> remove(String id) async {

    await ref.read(favoriteMomentsServiceProvider).remove(id);

    ref.invalidateSelf();

  }

}


