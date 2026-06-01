// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TorError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TorErrorCopyWith<$Res> {
  factory $TorErrorCopyWith(TorError value, $Res Function(TorError) then) =
      _$TorErrorCopyWithImpl<$Res, TorError>;
}

/// @nodoc
class _$TorErrorCopyWithImpl<$Res, $Val extends TorError>
    implements $TorErrorCopyWith<$Res> {
  _$TorErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TorError_BootstrapErrorImplCopyWith<$Res> {
  factory _$$TorError_BootstrapErrorImplCopyWith(
          _$TorError_BootstrapErrorImpl value,
          $Res Function(_$TorError_BootstrapErrorImpl) then) =
      __$$TorError_BootstrapErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TorError_BootstrapErrorImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_BootstrapErrorImpl>
    implements _$$TorError_BootstrapErrorImplCopyWith<$Res> {
  __$$TorError_BootstrapErrorImplCopyWithImpl(
      _$TorError_BootstrapErrorImpl _value,
      $Res Function(_$TorError_BootstrapErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TorError_BootstrapErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TorError_BootstrapErrorImpl extends TorError_BootstrapError {
  const _$TorError_BootstrapErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TorError.bootstrapError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_BootstrapErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TorError_BootstrapErrorImplCopyWith<_$TorError_BootstrapErrorImpl>
      get copyWith => __$$TorError_BootstrapErrorImplCopyWithImpl<
          _$TorError_BootstrapErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return bootstrapError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return bootstrapError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (bootstrapError != null) {
      return bootstrapError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return bootstrapError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return bootstrapError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (bootstrapError != null) {
      return bootstrapError(this);
    }
    return orElse();
  }
}

abstract class TorError_BootstrapError extends TorError {
  const factory TorError_BootstrapError(final String field0) =
      _$TorError_BootstrapErrorImpl;
  const TorError_BootstrapError._() : super._();

  String get field0;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TorError_BootstrapErrorImplCopyWith<_$TorError_BootstrapErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TorError_ProxyStartErrorImplCopyWith<$Res> {
  factory _$$TorError_ProxyStartErrorImplCopyWith(
          _$TorError_ProxyStartErrorImpl value,
          $Res Function(_$TorError_ProxyStartErrorImpl) then) =
      __$$TorError_ProxyStartErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TorError_ProxyStartErrorImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_ProxyStartErrorImpl>
    implements _$$TorError_ProxyStartErrorImplCopyWith<$Res> {
  __$$TorError_ProxyStartErrorImplCopyWithImpl(
      _$TorError_ProxyStartErrorImpl _value,
      $Res Function(_$TorError_ProxyStartErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TorError_ProxyStartErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TorError_ProxyStartErrorImpl extends TorError_ProxyStartError {
  const _$TorError_ProxyStartErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TorError.proxyStartError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_ProxyStartErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TorError_ProxyStartErrorImplCopyWith<_$TorError_ProxyStartErrorImpl>
      get copyWith => __$$TorError_ProxyStartErrorImplCopyWithImpl<
          _$TorError_ProxyStartErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return proxyStartError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return proxyStartError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (proxyStartError != null) {
      return proxyStartError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return proxyStartError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return proxyStartError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (proxyStartError != null) {
      return proxyStartError(this);
    }
    return orElse();
  }
}

abstract class TorError_ProxyStartError extends TorError {
  const factory TorError_ProxyStartError(final String field0) =
      _$TorError_ProxyStartErrorImpl;
  const TorError_ProxyStartError._() : super._();

  String get field0;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TorError_ProxyStartErrorImplCopyWith<_$TorError_ProxyStartErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TorError_ProxyStopErrorImplCopyWith<$Res> {
  factory _$$TorError_ProxyStopErrorImplCopyWith(
          _$TorError_ProxyStopErrorImpl value,
          $Res Function(_$TorError_ProxyStopErrorImpl) then) =
      __$$TorError_ProxyStopErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TorError_ProxyStopErrorImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_ProxyStopErrorImpl>
    implements _$$TorError_ProxyStopErrorImplCopyWith<$Res> {
  __$$TorError_ProxyStopErrorImplCopyWithImpl(
      _$TorError_ProxyStopErrorImpl _value,
      $Res Function(_$TorError_ProxyStopErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TorError_ProxyStopErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TorError_ProxyStopErrorImpl extends TorError_ProxyStopError {
  const _$TorError_ProxyStopErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TorError.proxyStopError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_ProxyStopErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TorError_ProxyStopErrorImplCopyWith<_$TorError_ProxyStopErrorImpl>
      get copyWith => __$$TorError_ProxyStopErrorImplCopyWithImpl<
          _$TorError_ProxyStopErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return proxyStopError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return proxyStopError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (proxyStopError != null) {
      return proxyStopError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return proxyStopError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return proxyStopError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (proxyStopError != null) {
      return proxyStopError(this);
    }
    return orElse();
  }
}

abstract class TorError_ProxyStopError extends TorError {
  const factory TorError_ProxyStopError(final String field0) =
      _$TorError_ProxyStopErrorImpl;
  const TorError_ProxyStopError._() : super._();

  String get field0;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TorError_ProxyStopErrorImplCopyWith<_$TorError_ProxyStopErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TorError_ClientNotInitializedImplCopyWith<$Res> {
  factory _$$TorError_ClientNotInitializedImplCopyWith(
          _$TorError_ClientNotInitializedImpl value,
          $Res Function(_$TorError_ClientNotInitializedImpl) then) =
      __$$TorError_ClientNotInitializedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TorError_ClientNotInitializedImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_ClientNotInitializedImpl>
    implements _$$TorError_ClientNotInitializedImplCopyWith<$Res> {
  __$$TorError_ClientNotInitializedImplCopyWithImpl(
      _$TorError_ClientNotInitializedImpl _value,
      $Res Function(_$TorError_ClientNotInitializedImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TorError_ClientNotInitializedImpl
    extends TorError_ClientNotInitialized {
  const _$TorError_ClientNotInitializedImpl() : super._();

  @override
  String toString() {
    return 'TorError.clientNotInitialized()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_ClientNotInitializedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return clientNotInitialized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return clientNotInitialized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (clientNotInitialized != null) {
      return clientNotInitialized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return clientNotInitialized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return clientNotInitialized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (clientNotInitialized != null) {
      return clientNotInitialized(this);
    }
    return orElse();
  }
}

abstract class TorError_ClientNotInitialized extends TorError {
  const factory TorError_ClientNotInitialized() =
      _$TorError_ClientNotInitializedImpl;
  const TorError_ClientNotInitialized._() : super._();
}

/// @nodoc
abstract class _$$TorError_RuntimeErrorImplCopyWith<$Res> {
  factory _$$TorError_RuntimeErrorImplCopyWith(
          _$TorError_RuntimeErrorImpl value,
          $Res Function(_$TorError_RuntimeErrorImpl) then) =
      __$$TorError_RuntimeErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TorError_RuntimeErrorImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_RuntimeErrorImpl>
    implements _$$TorError_RuntimeErrorImplCopyWith<$Res> {
  __$$TorError_RuntimeErrorImplCopyWithImpl(_$TorError_RuntimeErrorImpl _value,
      $Res Function(_$TorError_RuntimeErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TorError_RuntimeErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TorError_RuntimeErrorImpl extends TorError_RuntimeError {
  const _$TorError_RuntimeErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TorError.runtimeError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_RuntimeErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TorError_RuntimeErrorImplCopyWith<_$TorError_RuntimeErrorImpl>
      get copyWith => __$$TorError_RuntimeErrorImplCopyWithImpl<
          _$TorError_RuntimeErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return runtimeError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return runtimeError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (runtimeError != null) {
      return runtimeError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return runtimeError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return runtimeError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (runtimeError != null) {
      return runtimeError(this);
    }
    return orElse();
  }
}

abstract class TorError_RuntimeError extends TorError {
  const factory TorError_RuntimeError(final String field0) =
      _$TorError_RuntimeErrorImpl;
  const TorError_RuntimeError._() : super._();

  String get field0;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TorError_RuntimeErrorImplCopyWith<_$TorError_RuntimeErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TorError_ConfigErrorImplCopyWith<$Res> {
  factory _$$TorError_ConfigErrorImplCopyWith(_$TorError_ConfigErrorImpl value,
          $Res Function(_$TorError_ConfigErrorImpl) then) =
      __$$TorError_ConfigErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$TorError_ConfigErrorImplCopyWithImpl<$Res>
    extends _$TorErrorCopyWithImpl<$Res, _$TorError_ConfigErrorImpl>
    implements _$$TorError_ConfigErrorImplCopyWith<$Res> {
  __$$TorError_ConfigErrorImplCopyWithImpl(_$TorError_ConfigErrorImpl _value,
      $Res Function(_$TorError_ConfigErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TorError_ConfigErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TorError_ConfigErrorImpl extends TorError_ConfigError {
  const _$TorError_ConfigErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'TorError.configError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TorError_ConfigErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TorError_ConfigErrorImplCopyWith<_$TorError_ConfigErrorImpl>
      get copyWith =>
          __$$TorError_ConfigErrorImplCopyWithImpl<_$TorError_ConfigErrorImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) bootstrapError,
    required TResult Function(String field0) proxyStartError,
    required TResult Function(String field0) proxyStopError,
    required TResult Function() clientNotInitialized,
    required TResult Function(String field0) runtimeError,
    required TResult Function(String field0) configError,
  }) {
    return configError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? bootstrapError,
    TResult? Function(String field0)? proxyStartError,
    TResult? Function(String field0)? proxyStopError,
    TResult? Function()? clientNotInitialized,
    TResult? Function(String field0)? runtimeError,
    TResult? Function(String field0)? configError,
  }) {
    return configError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? bootstrapError,
    TResult Function(String field0)? proxyStartError,
    TResult Function(String field0)? proxyStopError,
    TResult Function()? clientNotInitialized,
    TResult Function(String field0)? runtimeError,
    TResult Function(String field0)? configError,
    required TResult orElse(),
  }) {
    if (configError != null) {
      return configError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TorError_BootstrapError value) bootstrapError,
    required TResult Function(TorError_ProxyStartError value) proxyStartError,
    required TResult Function(TorError_ProxyStopError value) proxyStopError,
    required TResult Function(TorError_ClientNotInitialized value)
        clientNotInitialized,
    required TResult Function(TorError_RuntimeError value) runtimeError,
    required TResult Function(TorError_ConfigError value) configError,
  }) {
    return configError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TorError_BootstrapError value)? bootstrapError,
    TResult? Function(TorError_ProxyStartError value)? proxyStartError,
    TResult? Function(TorError_ProxyStopError value)? proxyStopError,
    TResult? Function(TorError_ClientNotInitialized value)?
        clientNotInitialized,
    TResult? Function(TorError_RuntimeError value)? runtimeError,
    TResult? Function(TorError_ConfigError value)? configError,
  }) {
    return configError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TorError_BootstrapError value)? bootstrapError,
    TResult Function(TorError_ProxyStartError value)? proxyStartError,
    TResult Function(TorError_ProxyStopError value)? proxyStopError,
    TResult Function(TorError_ClientNotInitialized value)? clientNotInitialized,
    TResult Function(TorError_RuntimeError value)? runtimeError,
    TResult Function(TorError_ConfigError value)? configError,
    required TResult orElse(),
  }) {
    if (configError != null) {
      return configError(this);
    }
    return orElse();
  }
}

abstract class TorError_ConfigError extends TorError {
  const factory TorError_ConfigError(final String field0) =
      _$TorError_ConfigErrorImpl;
  const TorError_ConfigError._() : super._();

  String get field0;

  /// Create a copy of TorError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TorError_ConfigErrorImplCopyWith<_$TorError_ConfigErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}
