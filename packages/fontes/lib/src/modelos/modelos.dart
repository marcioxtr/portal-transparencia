import 'package:meta/meta.dart';

/// De onde um dado veio e quando foi obtido. Todo registro exibido no app
/// carrega isso, para o cidadão saber a procedência.
enum Fonte { smarapd, prefeitura, ecrie, intertec, tceSp }

@immutable
class Procedencia {
  const Procedencia({
    required this.fonte,
    required this.url,
    required this.obtidoEm,
  });
  final Fonte fonte;
  final Uri url;
  final DateTime obtidoEm;
}

/// Página de uma listagem paginada.
@immutable
class Pagina<T> {
  const Pagina({
    required this.itens,
    required this.paginaAtual,
    required this.totalPaginas,
    this.totalRegistros,
  });
  final List<T> itens;
  final int paginaAtual;
  final int totalPaginas;

  /// Nem toda fonte informa o total de registros.
  final int? totalRegistros;

  bool get temProxima => paginaAtual < totalPaginas;
}

// ─── Contratos (site da prefeitura) ─────────────────────────────────────────

@immutable
class ContratoResumo {
  const ContratoResumo({
    required this.id,
    required this.titulo,
    required this.objeto,
  });

  /// Id numérico global do CMS (ex.: 26048). Chave de cache.
  final int id;
  final String titulo;
  final String objeto;
}

@immutable
class Contrato {
  const Contrato({
    required this.id,
    required this.titulo,
    required this.objeto,
    required this.contratado,
    required this.cpfCnpj,
    required this.licitacao,
    required this.valorCentavos,
    required this.ano,
    required this.dataAssinatura,
    required this.dataInicio,
    required this.dataFim,
    required this.urlDocumento,
    required this.camposExtras,
  });

  final int id;
  final String titulo;
  final String objeto;
  final String? contratado;
  final String? cpfCnpj;
  final String? licitacao;

  /// Valor em centavos para evitar erro de ponto flutuante. `null` se ausente.
  final int? valorCentavos;
  final int? ano;
  final DateTime? dataAssinatura;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final Uri? urlDocumento;

  /// Qualquer par `Rótulo: valor` que o parser não reconheceu — garante que
  /// nada se perde se o CMS adicionar campos.
  final Map<String, String> camposExtras;
}

/// Tipos aceitos pelo filtro `tipo` de /contratos (valores exatos do site).
const tiposContrato = <String>[
  'Acordo de Cooperação',
  'Apostilamento',
  'Ata de Registro de Preço',
  'Contrato',
  'Convênio',
  'Registro Inicial',
  'Termo Aditivo',
  'Termo de Cessão',
  'Termo de Cessão de Uso de Bem Móvel',
  'Termo de Colaboração',
  'Termo de Compromisso',
  'Termo de Cooperação Técnica',
  'Termo de Credenciamento',
  'Termo de Doação',
  'Termo de Fomento',
  'Termo de Permissão',
  'Termo de Uso de Bem Imóvel',
];

// ─── Emendas parlamentares (site da prefeitura) ─────────────────────────────

@immutable
class EmendaResumo {
  const EmendaResumo({
    required this.slug,
    required this.titulo,
    required this.publicadoEm,
  });

  /// Último segmento da URL (ex.: `emenda-n-202550410002`).
  final String slug;
  final String titulo;
  final DateTime? publicadoEm;
}

@immutable
class Emenda {
  const Emenda({
    required this.slug,
    required this.titulo,
    required this.numero,
    required this.origemRecurso,
    required this.tipo,
    required this.autoria,
    required this.formaRepasse,
    required this.valorCentavos,
    required this.objetivo,
    required this.funcaoGoverno,
    required this.beneficiario,
    required this.camposExtras,
  });

  final String slug;
  final String titulo;
  final String? numero;
  final String? origemRecurso;
  final String? tipo;
  final String? autoria;
  final String? formaRepasse;
  final int? valorCentavos;
  final String? objetivo;
  final String? funcaoGoverno;
  final String? beneficiario;
  final Map<String, String> camposExtras;
}

// ─── Arquivos legados (eCrie) ───────────────────────────────────────────────

/// Nó da árvore de documentos até 2022. Pastas têm [filhos]; arquivos têm [url].
@immutable
class NoArquivo {
  const NoArquivo.pasta({
    required this.nome,
    required this.caminho,
    required this.filhos,
  }) : url = null;

  const NoArquivo.arquivo({
    required this.nome,
    required this.caminho,
    required Uri this.url,
  }) : filhos = const [];

  final String nome;

  /// Caminho relativo à raiz do cliente eCrie (ex.: `rh/Despesas .../2013`).
  final String caminho;
  final List<NoArquivo> filhos;
  final Uri? url;

  bool get ehArquivo => url != null;

  String get extensao {
    final i = nome.lastIndexOf('.');
    return i < 0 ? '' : nome.substring(i + 1).toLowerCase();
  }

  /// Percorre em profundidade devolvendo só os arquivos.
  Iterable<NoArquivo> get arquivos sync* {
    if (ehArquivo) yield this;
    for (final f in filhos) {
      yield* f.arquivos;
    }
  }
}
