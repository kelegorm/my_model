library model.model;

import 'dart:async';

/// Model is a some data object, which can be like List or Map,
/// has changes stream.
///
/// It allows to have simple data classes and keep it observable.
///
/// Model may have any type of data in it values, but if value is
/// a Model too, it's called sub-model, and model can detect and
/// streams sub-model changes along with its own changes.
abstract class IModel {

  /// Stream with all model's changes and also sub-model changes.
  Stream<ModelChange> get modelChanges;

  operator ==(Object other);
}


/// Describes of [AnnotatedModel]'s property change.
///
/// it's base class for model changes.
abstract class ModelChange {
  ModelChange();
}


abstract class SubModelChange extends ModelChange {

}