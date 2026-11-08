import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';
import 'fighter_entity.dart';
import 'player_entity.dart';
import 'mosquito_entity.dart';
import 'grunt_entity.dart';

/// The composition boundary is the only place that selects an entity by type.
FighterEntity<FighterModel> createFighterEntity(FighterModel model,
        FighterCacheService cache, bool Function() showDebug) =>
    switch (model) {
      PlayerModel() => PlayerEntity(model, cache, showDebug),
      MosquitoModel() => MosquitoEntity(model, cache, showDebug),
      GruntModel() => GruntEntity(model, cache, showDebug),
    };
