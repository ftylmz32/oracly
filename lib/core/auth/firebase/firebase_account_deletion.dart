/// Remote account deletion for [FirebaseAuthService] — no local wipe.
library;

import '../../network/api_result.dart';
import '../../network/network_exception.dart';
import '../auth_copy.dart';
import '../session_manager.dart';
import '../token_manager.dart';
import 'firebase_auth_errors.dart';
import 'firebase_auth_gateway.dart';

abstract final class FirebaseAccountDeletion {
  FirebaseAccountDeletion._();

  static Future<ApiResult<bool>> run({
    required FirebaseAuthGateway gateway,
    SessionManager? sessions,
    TokenManager? tokens,
  }) async {
    if (gateway.currentUser == null) {
      return ApiFailure(
        NetworkException.unauthorized(AuthCopy.noCurrentUser),
      );
    }
    try {
      await gateway.deleteCurrentUser();
      await sessions?.clearSession();
      await tokens?.clearTokens();
      return const ApiSuccess(true);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.mapDelete(e));
    } catch (_) {
      return ApiFailure(
        NetworkException.unauthorized(AuthCopy.deleteFailed),
      );
    }
  }
}