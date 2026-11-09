import 'dart:async';
import 'dart:collection';

import 'package:http/http.dart' as http;

/// User-Agent padrão do projeto. Identificar-se é parte do uso responsável
/// das fontes públicas (ver CONTRIBUTING.md).
const userAgentPadrao =
    'TransparenciaSJBV/0.1 (+https://github.com/NeoFusa/portal-transparencia)';

/// Cliente HTTP compartilhado por todas as fontes.
///
/// - Envia `User-Agent` identificado.
/// - Limita a concorrência **por host** (padrão: 2 requisições simultâneas),
///   para não sobrecarregar os sites da prefeitura/fornecedores.
/// - Faz retry simples com backoff em erros de rede e 5xx.
class ClienteHttp {
  ClienteHttp({
    http.Client? inner,
    this.userAgent = userAgentPadrao,
    this.maxConcorrenciaPorHost = 2,
    this.tentativas = 3,
    this.timeout = const Duration(seconds: 30),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final String userAgent;
  final int maxConcorrenciaPorHost;
  final int tentativas;
  final Duration timeout;

  final Map<String, _Semaforo> _semaforos = {};

  _Semaforo _semaforo(Uri uri) =>
      _semaforos.putIfAbsent(uri.host, () => _Semaforo(maxConcorrenciaPorHost));

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      _enviar(() => _inner.get(uri, headers: _headers(headers)), uri);

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _enviar(
        () => _inner.post(uri, headers: _headers(headers), body: body),
        uri,
      );

  Map<String, String> _headers(Map<String, String>? extra) => {
        'User-Agent': userAgent,
        'Accept-Language': 'pt-BR,pt;q=0.9',
        ...?extra,
      };

  Future<http.Response> _enviar(
    Future<http.Response> Function() enviar,
    Uri uri,
  ) async {
    final sem = _semaforo(uri);
    await sem.adquirir();
    try {
      Object? ultimoErro;
      for (var i = 0; i < tentativas; i++) {
        try {
          final resp = await enviar().timeout(timeout);
          if (resp.statusCode >= 500 && i < tentativas - 1) {
            ultimoErro = HttpStatusException(uri, resp.statusCode);
          } else {
            return resp;
          }
        } on TimeoutException catch (e) {
          ultimoErro = e;
        } on http.ClientException catch (e) {
          ultimoErro = e;
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * (1 << i)));
      }
      throw ultimoErro ?? StateError('falha desconhecida em $uri');
    } finally {
      sem.liberar();
    }
  }

  void close() => _inner.close();
}

class HttpStatusException implements Exception {
  HttpStatusException(this.uri, this.status);
  final Uri uri;
  final int status;
  @override
  String toString() => 'HTTP $status em $uri';
}

class _Semaforo {
  _Semaforo(this._livres);
  int _livres;
  final Queue<Completer<void>> _fila = Queue();

  Future<void> adquirir() {
    if (_livres > 0) {
      _livres--;
      return Future.value();
    }
    final c = Completer<void>();
    _fila.add(c);
    return c.future;
  }

  void liberar() {
    if (_fila.isNotEmpty) {
      _fila.removeFirst().complete();
    } else {
      _livres++;
    }
  }
}
