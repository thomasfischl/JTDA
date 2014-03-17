library webcomponents;

import 'dart:html';

class Dialog {

  bool _init = false;
  String _name;
  double _left;
  double _top;

  DivElement _modalDialog;
  DivElement _body;

  Dialog(this._name, this._left, this._top){
    _initDialog();
  }

  void _initDialog(){
    _init = true;
    _modalDialog = new DivElement();
    _modalDialog.style.left = (_left+10).toString()+ "px";
    _modalDialog.style.top = "$_top" + "px";
    _modalDialog.style.position = "absolute";
    _modalDialog.style.margin = "0";
    _modalDialog.className = "modal-dialog";
    _modalDialog.style.width = "700px";

    window.onKeyUp.listen(_keyPressListener);


    DivElement content = _modalDialog.append(new DivElement());
    content.className = "modal-content";

    // ------------------ header -----------------------------------
    DivElement header = content.append(new DivElement());
    header.className = "modal-header";

    ButtonElement btnHeaderClose = header.append(new ButtonElement());
    btnHeaderClose.className = "close";
    btnHeaderClose.text = "x";
    btnHeaderClose.onClick.listen(_clickListener);

    HeadingElement title = header.append(new HeadingElement.h4());
    title.text = _name;

    // ------------------ body -----------------------------------

    _body = content.append(new DivElement());
    _body.className = "modal-body";

    // ------------------ footer -----------------------------------

    DivElement footer = content.append(new DivElement());
    footer.className = "modal-footer";

    ButtonElement btnClose = footer.append(new ButtonElement());
    btnClose.className = "btn btn-primary btn-default";
    btnClose.text = "Close";
    btnClose.onClick.listen(_clickListener);


    document.body.append(_modalDialog);
  }

  void close(){
    _modalDialog.remove();
  }

  void _clickListener(MouseEvent event) {
    close();
  }

  void _keyPressListener(KeyboardEvent event) {
    if(event.keyCode == KeyCode.ESC){
       close();
    }
  }

  Node setBody(Node body){
    _body.append(body);
    return body;
  }

}

