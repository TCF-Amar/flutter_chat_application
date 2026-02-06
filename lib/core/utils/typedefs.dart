import 'package:chat_kare/core/errors/failure.dart';
import 'package:dartz/dartz.dart';

typedef Result<T> = Either<Failure, T>;
