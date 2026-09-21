import 'package:kumo_ui/kumo_ui.dart';

import '../page_parts.dart';
import '../sample_data.dart';

/// The Sankey flow route.
///
/// Runs [KumoSankeySolver] directly alongside [KumoSankeyChart] so the layout it
/// derives — columns, scale, and each node's throughput — is on screen next to
/// the picture it produced.
class KumoExampleSankey extends StatefulWidget {
  /// Creates the flow network screen.
  const KumoExampleSankey({super.key});

  @override
  State<KumoExampleSankey> createState() => _KumoExampleSankeyState();
}

class _KumoExampleSankeyState extends State<KumoExampleSankey> {
  /// Nominal box the standalone solve runs in, so the readout has a size to
  /// report against without a layout pass.
  static const double _nominalWidth = 560;
  static const double _nominalHeight = 280;

  int _flowIndex = 0;
  String? _selectedNode;

  late KumoSankeySolver _solver;
  late List<KumoSankeyNodeLayout> _nodeLayouts;
  late List<KumoSankeyLinkLayout> _linkLayouts;

  SampleFlow get _flow => sampleFlows[_flowIndex];

  @override
  void initState() {
    super.initState();
    _reanalyze();
  }

  void _reanalyze() {
    final KumoSankeyGraph graph = _flow.graph;
    _solver = KumoSankeySolver(graph: graph);
    _nodeLayouts = List<KumoSankeyNodeLayout>.generate(
      graph.nodes.length,
      (_) => KumoSankeyNodeLayout(),
      growable: false,
    );
    _linkLayouts = List<KumoSankeyLinkLayout>.generate(
      graph.links.length,
      (_) => KumoSankeyLinkLayout(),
      growable: false,
    );
    _solver.layout(
      width: _nominalWidth,
      height: _nominalHeight,
      nodeLayouts: _nodeLayouts,
      linkLayouts: _linkLayouts,
    );
  }

  void _selectFlow(int index) {
    setState(() {
      _flowIndex = index;
      _selectedNode = null;
      _reanalyze();
    });
  }

  KumoSankeyNodeLayout? get _selectedLayout {
    final String? selected = _selectedNode;
    if (selected == null) {
      return null;
    }
    final List<KumoSankeyNode> nodes = _flow.graph.nodes;
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == selected) {
        return _nodeLayouts[i];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final KumoTextStyles styles = KumoTheme.textStylesOf(context);
    final SampleFlow flow = _flow;
    final KumoSankeyNodeLayout? selected = _selectedLayout;

    return KumoScaffold(
      header: const ExamplePageHeader(
        title: 'Request flow network',
        subtitle: '/charts/sankey',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          KumoSegmentedControl<int>(
            segments: <int, String>{
              for (int i = 0; i < sampleFlows.length; i++) i: sampleFlows[i].name,
            },
            selected: _flowIndex,
            onSelected: _selectFlow,
          ),
          const SizedBox(height: 10),
          Text(flow.summary, style: styles.bodyMuted),
          const SizedBox(height: 20),
          KumoSankeyChart(
            graph: flow.graph,
            selectedNodeId: _selectedNode,
            height: 300,
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Node'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final KumoSankeyNode node in flow.graph.nodes)
                KumoButton(
                  label: node.label ?? node.id,
                  variant: node.id == _selectedNode
                      ? KumoButtonVariant.primary
                      : KumoButtonVariant.secondary,
                  onPressed: () => setState(() {
                    _selectedNode = node.id == _selectedNode ? null : node.id;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const ExampleSectionLabel('Layout'),
          Text(
            'columns ${_solver.columnCount} · scale '
            '${_solver.scale.toStringAsFixed(2)} px per unit',
            style: styles.caption,
          ),
          const SizedBox(height: 6),
          if (selected == null)
            Text('Pick a node to read its flow.', style: styles.bodyMuted)
          else
            Text(
              'in ${selected.inflow.toStringAsFixed(0)} · '
              'out ${selected.outflow.toStringAsFixed(0)} · '
              'throughput ${selected.throughput.toStringAsFixed(0)} · '
              'depth ${selected.depth}',
              style: styles.bodyMuted,
            ),
          const SizedBox(height: 10),
          Text(
            'The solver writes into caller-owned layout structs, so switching a '
            'flow re-lays out the same objects instead of building a new graph '
            'of them.',
            style: styles.caption,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
