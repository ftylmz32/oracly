/// Save and remove favorite moments — never automatic.

library;



import '../data/local_favorite_moments_repository.dart';

import '../models/favorite_moment.dart';



class FavoriteMomentsService {

  FavoriteMomentsService(this._repository);



  final LocalFavoriteMomentsRepository _repository;



  Future<List<FavoriteMoment>> all() => _repository.getAll();



  Future<bool> isSaved(String id) => _repository.contains(id);



  Future<void> save(FavoriteMoment moment) => _repository.save(moment);



  Future<void> remove(String id) => _repository.remove(id);

  Future<void> clearAll() => _repository.clearAll();
}


