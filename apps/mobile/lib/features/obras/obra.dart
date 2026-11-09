import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';

/// Uma obra pública, como publicada em www.saojoao.sp.gov.br/obras
/// (coletada por dados/coletores/obras.py).
class Obra {
  const Obra({
    required this.slug,
    required this.titulo,
    required this.url,
    required this.secretaria,
    required this.situacao,
    this.responsavelTecnico,
    this.dataInicio,
    this.dataTerminoPrevista,
    this.endereco,
    this.bairro,
    this.empresa,
    this.cpfCnpj,
    this.valorContrato,
    this.valorExecutado,
    this.percentualExecucao,
    this.lat,
    this.lng,
    this.fotos = const [],
  });

  factory Obra.fromJson(Map<String, dynamic> j) => Obra(
        slug: j.str('slug'),
        titulo: j.str('titulo'),
        url: j.str('url'),
        secretaria: j.str('secretaria'),
        situacao: j.str('situacao', 'Não informada'),
        responsavelTecnico: j.strOuNulo('responsavelTecnico'),
        dataInicio: j.data('dataInicio'),
        dataTerminoPrevista: j.data('dataTerminoPrevista'),
        endereco: j.strOuNulo('endereco'),
        bairro: j.strOuNulo('bairro'),
        empresa: j.strOuNulo('empresa'),
        cpfCnpj: j.strOuNulo('cpfCnpj'),
        valorContrato: j.numOuNulo('valorContrato'),
        valorExecutado: j.numOuNulo('valorExecutado'),
        percentualExecucao: j.numOuNulo('percentualExecucao'),
        lat: j.numOuNulo('lat'),
        lng: j.numOuNulo('lng'),
        fotos: ((j['fotos'] as List?) ?? const []).cast<String>(),
      );

  static List<Obra> lista(Map<String, dynamic> dados) => [for (final o in dados.lista('obras')) Obra.fromJson(o)];

  final String slug, titulo, url, secretaria, situacao;
  final String? responsavelTecnico, endereco, bairro, empresa, cpfCnpj;
  final DateTime? dataInicio, dataTerminoPrevista;
  final double? valorContrato, valorExecutado, percentualExecucao;
  final double? lat, lng;
  final List<String> fotos;

  LatLng? get ponto => lat == null || lng == null ? null : LatLng(lat!, lng!);

  bool get concluida => situacao.toLowerCase().startsWith('conclu');
  bool get emAndamento => situacao.toLowerCase().contains('andamento');

  /// Prazo previsto já passou e a obra não foi concluída.
  bool get atrasada => !concluida && dataTerminoPrevista != null && dataTerminoPrevista!.isBefore(DateTime.now());

  Color get cor => corSituacao(situacao);
  IconData get icone => switch (situacao.toLowerCase()) {
        final s when s.startsWith('conclu') => Icons.check_rounded,
        final s when s.contains('andamento') => Icons.construction_rounded,
        final s when s.contains('suspens') => Icons.pause_rounded,
        final s when s.contains('projeto') => Icons.architecture_rounded,
        _ => Icons.place_rounded,
      };

  /// Título do site vem em CAIXA ALTA; deixamos legível.
  String get tituloBonito {
    final minus = {'de', 'da', 'do', 'das', 'dos', 'e', 'em', 'a', 'o', 'para', 'no', 'na', 'com', 'sp'};
    return titulo
        .toLowerCase()
        .replaceAll(RegExp(r'[,\s]+$'), '')
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty || minus.contains(w) ? (w == 'sp' ? 'SP' : w) : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static Color corSituacao(String s) => switch (s.toLowerCase()) {
        final x when x.startsWith('conclu') => Cores.verde,
        final x when x.contains('andamento') => Cores.laranja,
        final x when x.contains('suspens') => Cores.rosa,
        final x when x.contains('projeto') => Cores.violeta,
        _ => Cores.azulCeu,
      };

  static int ordem(String s) => switch (s.toLowerCase()) {
        final x when x.contains('andamento') => 0,
        final x when x.contains('suspens') => 1,
        final x when x.contains('projeto') => 2,
        final x when x.startsWith('conclu') => 3,
        _ => 9,
      };

  /// "Departamento de Obras e Serviços Públicos" → "Obras e Serviços Públicos".
  static String curto(String secretaria) => secretaria.replaceFirst(RegExp(r'^Departamento (de|da|do) ', caseSensitive: false), '');
}
