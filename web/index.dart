import 'dart:html';
import 'd3graph.dart';
import 'jtda.dart';
import 'webcomponents.dart';

D3Graph chart;
SelectElement selColorNode;
List<JavaThreadDump> threadList;
Map<JavaThreadDump, D3Node> maps = new Map();
Map<String, D3Node> lockes = new Map();

void main() {
  chartPart();
  filePart();
}

void filePart() {
  InputElement inputFile = querySelector("#inputFile");
  inputFile.onChange.listen(readFile);
  inputFile.style.width = "500px";

  CheckboxInputElement inputFilter = querySelector("#hideThreadFilter");
  inputFilter.onChange.listen((e) => update());
}

void chartPart() {
  HtmlElement root = querySelector("#chartPart");
  DivElement divChart = new DivElement();
  divChart.id = "divChart";
  root.append(divChart);
  chart = new D3Graph(divChart, width: divChart.getClientRects().first.width, height: 700, showText: false);
}

void addNode(MouseEvent event) {
  var node = new D3Node("Hello World", color: selColorNode.value);

  node.onClick().listen((n) {
    if (n.color == "red") {
      n.color = "blue";
    } else {
      n.color = "red";
    }
    n.radius = n.radius + 5;
  });

  node.onDblClick().listen((n) {
    chart.removeNode(n);
  });

  chart.addNode(node);
}

void showNodes(MouseEvent event) {
  chart.nodes.forEach((f) => print(f.toString()));
  chart.nodes.forEach((f) => f.proxy['text'] = "Hello World 1");
  chart.update();
}


void addEdge(MouseEvent event) {
  var node = new D3Node("Resource", color: selColorNode.value);
  chart.addNode(node);
  chart.nodes.getRange(1, 4).forEach((n) => chart.addEdge(n, node));
  node.onDblClick().listen((n) => chart.removeNode(n));
}


void clear(MouseEvent event) {
  chart.clear();
}


void readFile(var event) {
  InputElement inputFile = querySelector("#inputFile");

  List<File> files = inputFile.files;
  if (files.length == 1) {
    File file = files[0];

    FileReader reader = new FileReader();
    reader.onLoadEnd.listen((e) {
      JtdaParser parser = new JtdaParser(reader.result);
      var threads = parser.parse();
      threads.forEach((t) => print(t));
      threadList = threads;
      update();
    });
    reader.readAsText(file);
  }
}

void update(){
  chart.clear();
  maps.clear();
  lockes.clear();

  if(threadList == null){
    print("No thread dumps available.");
    return;
  }

  updateControlPanel();
  updateChartPanel();
}

void updateChartPanel() {
  CheckboxInputElement hideThreadFilter = querySelector("#hideThreadFilter");
  var it = threadList.where((t) => !hideThreadFilter.checked || !(t.locks.isEmpty && t.waitingToLocks.isEmpty)).iterator;
  while (it.moveNext()) {
    var t = it.current;

    var node = new D3Node(t.name , color: JavaThreadDump.getColor(t.state));
    node.radius = 9;
    node.onClick().listen(showThreadDumpDetails);
    chart.addNode(node);
    maps[t] = node;
    t.locks.forEach(addLocks(lockes,node));
    t.waitingToLocks.forEach(addLocks(lockes,node));
  }
  chart.update();
}

void updateControlPanel() {
  if(querySelector("#threadList")!=null){
    querySelector("#threadList").remove();
  }

  CheckboxInputElement hideThreadFilter = querySelector("#hideThreadFilter");
  DivElement divThreadList =  querySelector("#controls").append(new DivElement());
  divThreadList.className = "panel-group";
  divThreadList.id = "threadList";

  Map<String, List<JavaThreadDump>> threadListEnties = new Map();

  threadList.where(filterThreads).forEach((t) {
    if(!threadListEnties.containsKey(t.state)){
        threadListEnties[t.state] = new List();
    }
    threadListEnties[t.state].add(t);
  });

  threadListEnties.forEach((state,tdList){
    CollapsePanel panel = new CollapsePanel(divThreadList, "Thread - $state");

    tdList.forEach((td){
      DivElement div = new DivElement();
      div.append(getThreadStatusBox(state));

       ParagraphElement p = new ParagraphElement();
       p.text = td.name;
       p.title = td.name;
       p.style.textOverflow = "ellipsis";
       p.style.whiteSpace = "nowrap";
       p.style.overflow = "hidden";

       div.onClick.listen((e){
         print("click: " + e.target.toString());
         maps.forEach((t1,n){
           if( t1 == td){
             showThreadDumpDetails(n);
           }
         });
       });

       div.append(p);
       panel.appendBody(div);
    });

  });
}

bool filterThreads(JavaThreadDump t){
  CheckboxInputElement hideThreadFilter = querySelector("#hideThreadFilter");
  return !hideThreadFilter.checked || !(t.locks.isEmpty && t.waitingToLocks.isEmpty);
}

Function addLocks(Map<String, D3Node> lockes, D3Node node){
  return (String l){
            if(!lockes.containsKey(l)){
              var lockNode = new D3Node(l, color: "black");
              lockNode.onClick().listen(showResourceDetails);
              chart.addNode(lockNode);
              lockes[l] = lockNode;
            }

            chart.addEdge(node, lockes[l]);
          };
}

void showThreadDumpDetails(D3Node event) {
  JavaThreadDump jtd = null;
  maps.forEach((td, n){
    if(n == event){
      jtd = td;
    }
  });

  DivElement chartDiv = querySelector("#divChart");

  Dialog d = new Dialog(jtd.name + " (" + jtd.state +  ")", event.x + chartDiv.getBoundingClientRect().left, event.y + chartDiv.getBoundingClientRect().top);
  DivElement body = d.setBody(new DivElement());

  UListElement list = body.append(new UListElement());
  list.className = "list-unstyled";

  for(int i = 2; i< jtd.dump.length;i++){
    var str = jtd.dump[i];
    if(str.contains(" Locked ownable synchronizers:")){
      break;
    }

    if(str.trim().startsWith("at")){
      var txtNode = document.createElement("small");
      txtNode.text = str.trim();
      list.append(new LIElement()).append(txtNode);
    } else if(str.trim().startsWith("- ")){
      var txtNode = document.createElement("small");
      txtNode.className = "lock";

      if(str.contains("owned by")){
        txtNode.text = str.substring(0, str.indexOf("owned by")).trim();
      } else {
        txtNode.text = str.trim();
      }


      list.append(new LIElement()).append(txtNode);
    } else if(str.trim() == ""){
    }else{
      var txtNode = document.createElement("small");
      txtNode.text = "???" + str.trim();
      list.append(new LIElement()).append(txtNode);
    }
  }

}

void viewThreadDumpUList(Node body, JavaThreadDump jtd){
  UListElement list = body.append(new UListElement());
  list.className = "list-unstyled";

  jtd.dump.forEach((str) {
       var txtNode = document.createElement("small");
       txtNode.text = str;
       list.append(new LIElement()).append(txtNode);
     });

  list.childNodes.first.remove();
  list.childNodes.first.remove();
}

void viewThreadDumpTextArea(Node body, JavaThreadDump jtd){
  StringBuffer sb = new StringBuffer();
  jtd.dump.forEach((str) {
    sb.writeln(str);
  });

  TextAreaElement txtNode = new TextAreaElement();
  txtNode.text = sb.toString();
  txtNode.style.width = "100%";
  body.append(txtNode);
}


void showResourceDetails(D3Node event) {
  DivElement chartDiv = querySelector("#divChart");

  var title = "Resource: " + event.text;
  maps.keys.where((td) => (td.locks.contains(event.text))).forEach((td){
    var str = td.dump.where((str) => str.contains("<" + event.text +">")).first.trim();
    str = str.substring(str.indexOf("(") + 1, str.indexOf(")"));
    if(str.startsWith("a ")){
      str = str.substring(2);
    }
    title += " (" + str + ")";
  });

  Dialog d = new Dialog(title, event.x + chartDiv.getBoundingClientRect().left, event.y + chartDiv.getBoundingClientRect().top);
  DivElement body = d.setBody(new DivElement());

  UListElement list = body.append(new UListElement());
  list.className = "list-unstyled";

  maps.keys.where((td) => (td.locks.contains(event.text))).forEach((td){
    var txtNode = document.createElement("small");
    txtNode.text = td.name + " (locked)";
    var li = list.append(new LIElement());
    li.append(getThreadStatusBox(td.state));
    li.append(txtNode);
  });

  maps.keys.where((td) => (td.waitingToLocks.contains(event.text))).forEach((td){
    var txtNode = document.createElement("small");
    txtNode.text = td.name;
    var li = list.append(new LIElement());
    li.append(getThreadStatusBox(td.state));
    li.append(txtNode);
  });

}

DivElement getThreadStatusBox(String state) {
   var box = new DivElement();
  box.style.width = "10px";
  box.style.height = "10px";
  box.style.marginRight = "10px";
  box.style.marginTop = "5px";
  box.style.backgroundColor = JavaThreadDump.getColor(state);
  box.className = "pull-left";
  return box;
}