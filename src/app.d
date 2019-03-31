module app;

import undym;

void main() {
    import std.file;
    import util;
    write("dat/version.txt", Util.GameVersion.toString());

    init();

    
    import scene.titlescene;
    TitleScene.ins.start;

    import scene.fieldscene;
    FieldScene.ins.start;
}


private void init(){
    import util;
    Window.setup( Bounds.WINDOW.toSize );
    Util.setup;

    import dungeon;
    Area.now = Area.再構成トンネル;
    
    import unit;
    Unit.setup();
}
