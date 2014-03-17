library d3;

import 'dart:js';
import 'package:js/js.dart' as js;
import 'dart:async';
import 'dart:html';

class D3Graph {

  num _width;
  num _height;
  bool _showText;

  js.Proxy _force;
  js.Proxy _text;
  js.Proxy _node;
  js.Proxy _link;

  js.Proxy _jsNodes;
  js.Proxy _jsLinks;

  List<D3Node> _nodes = new List();
  List<D3Edge> _links = new List();

  D3Graph(HtmlElement element, {num width: 960, num height: 500, bool showText: true}){
    _width = width;
    _height = height;
    _showText = showText;
    _jsNodes = js.array([]);
    _jsLinks = js.array([]);

    _init(element);
  }

  void _init(HtmlElement element) {
    js.Proxy d3 = js.context['d3'];
    //var fill = d3.scale.category20();

    _force = d3.layout.force().size(js.array([_width, _height])).nodes(_jsNodes
        ).links(_jsLinks).linkDistance(60).charge(-130).on("tick", _tick);


    var svg = d3.select(element).append("svg").attr("width", _width).attr("height",
        _height);

    var g = svg.append("g");
    _node = g.selectAll(".node");
    _link = g.selectAll(".link");
    _text = g.selectAll("text");
    _restart();
  }

  void addNode(D3Node node) {
    _nodes.add(node);
    _jsNodes.push(node.proxy);
    _restart();
  }

  void addEdge(D3Node source, D3Node target){
    var edge = new D3Edge();
    edge.source = source;
    edge.target = target;
    _links.add(edge);
    _jsLinks.push(edge.proxy);
    _restart();
  }

  void removeNode(D3Node node){
     _links.where((e) => (e.source == node || e.target == node)).toList(growable: false).forEach((e) => removeEdge(e));
    _nodes.remove(node);
    _jsNodes.length = 0;
    _nodes.forEach((n)=> _jsNodes.push(n.proxy));
    _restart();
  }

  void clear(){
    _links.clear();
    _nodes.clear();
    _jsLinks.length = 0;
    _jsNodes.length = 0;

    _restart();
  }

  void removeEdge(D3Edge edge){
    _links.remove(edge);
    _jsLinks.length = 0;
    _links.forEach((e) => _jsLinks.push(e.proxy));
    _restart();
  }

  void _tick(var arg) {
    update();
  }

  void update() {
    _node.attr("transform", _getTransform)
         .attr("fill", (d, x, x1) => d.color)
         .attr("r", (d, x, x1) => d.radius);

    if(_showText) {
      _text.attr("transform", _getTransform)
           .text((d, x, x1) => d.text);
    }

    _link.attr("x1", (d, x, x1) => d['source']['x'])
         .attr("y1", (d, x, x1) => d['source']['y'])
         .attr("x2", (d, x, x1) => d['target']['x'])
         .attr("y2", (d, x, x1) => d['target']['y']);
  }

  List<D3Node> get nodes => _nodes;
  List<D3Edge> get edges => _links;

  String _getTransform(d, x, y) {
    return "translate(" + d.x.toString() + "," + d.y.toString() + ")";
  }

  void _clickNode(d, x, y) {
    D3Node node = _getD3Node(d);
    if (node != null) {
      node.fireClick();
    }
  }

  void _dblClickNode(d, x, y) {
    D3Node node = _getD3Node(d);
    if (node != null) {
      node.fireDblClick();
    }
  }

  D3Node _getD3Node(var d){
    return _nodes.firstWhere((n) => n.id == d['id'], orElse: () => null);
  }

  void _restart() {

    _link = _link.data(_jsLinks);
    _link.enter().insert("line", ".node").attr("class", "link");
    _link.exit().remove();

    _node = _node.data(_jsNodes);
    _node.enter().insert("circle", ".cursor").attr("class", "node").call(_force['drag']);
    _node.exit().remove();
    _node.on("click", _clickNode);
    _node.on("dblclick", _dblClickNode);

    if(_showText) {
      _text = _text.data(_jsNodes);
      _text.enter().append("text").attr("x", 20).attr("y", ".31em");
      _text.exit().remove();
    }

    _force.start();
  }

}

class D3Node {

  static int counter = 0;
  JsObject _jsNode;
  StreamController<D3Node> _clickStream = new StreamController();
  StreamController<D3Node> _dblClickStream = new StreamController();

  D3Node(String text, {String id, String color: "black"}) {
    if (id == null) {
      id = "node" + (counter++).toString();
    }

    _jsNode = new JsObject.jsify({
      'x': 0,
      'y': 0,
      'text': text,
      'id': id,
      'color': color,
      'radius': 5
    });
  }

  String get text => _jsNode['text'];

  String get id => _jsNode['id'];

  double get x => _jsNode['x'];

  double get y => _jsNode['y'];

  String get color => _jsNode['color'];

  void set color(String color){
    _jsNode['color'] = color;
  }

  int get radius => _jsNode['radius'];

  void set radius(int radius){
    _jsNode['radius'] = radius;
  }

  JsObject get proxy => _jsNode;

  String toString() => "node " + id + " " + text;

  Stream<D3Node> onClick() =>  _clickStream.stream;

  Stream<D3Node> onDblClick() => _dblClickStream.stream;

  void fireClick() {
     _clickStream.add(this);
  }

  void fireDblClick() {
    _dblClickStream.add(this);
  }
}

class D3Edge {

  static int counter = 0;
  JsObject _jsEdge;
  D3Node _source;
  D3Node _target;

  D3Edge({String id, String color: "black"}) {
    if (id == null) {
      id = "edge" + (counter++).toString();
    }

    _jsEdge = new JsObject.jsify({
      'source': null,
      'target': null,
      'id': id,
      'color': color,
    });
  }

  void set source(D3Node node){
    _source = node;
    _jsEdge['source'] = node.proxy;
  }

  void set target(D3Node node){
    _target = node;
    _jsEdge['target'] = node.proxy;
  }

  D3Node get source => _source;

  D3Node get target => _target;

  String get id => _jsEdge['id'];

  String get color => _jsEdge['color'];

  void set color(String color) {
    _jsEdge['color'] = color;
  }

  JsObject get proxy => _jsEdge;

  String toString() => "edge $id";

}
