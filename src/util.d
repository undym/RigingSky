module util;

import undym;

/**

*/
class Util {
    import widget.movemsg;

    private this() {
    }

    enum FONT_SIZE = 11;

    static:
        Font font;
        MoveMsg msg;
        int list_draw_elm_num = 20;
        string game_version = "1";
        /***/
        void setup() {
            font = Font.of(FONT_SIZE);
            msg = new MoveMsg(font,/*log*/30);
        }
}


class PlayData{
    private this(){}

    static:
        int yen;
}


class Test{
    private this(){}
    static:
        bool appear_all_btn;
}


class Battle{
    import unit;
    private this(){}
    static:
        Unit[] attackers;
        Unit[] targets;
        int turn;
        int phase;
        int first_phase;

        Unit getPhaseUnit(){
            return Unit.all[phase];
        }
}

/**

*/
class Bounds{
    private this(){}

    /***/
    enum WINDOW = Rect(0, 0, 640, 480);
    enum BTN_H = 28;
    static Rect toPixelRect(FRect fr){
        return Rect( 
                 fr.x * WINDOW.w
                ,fr.y * WINDOW.h
                ,fr.w * WINDOW.w
                ,fr.h * WINDOW.h);
    }
    
    /***/
    class Ratio{
        private this(){}

        private enum BOX = FSize( 0.5, 0.225 );
        private enum BOTTOM_H = 0.1;
        enum PIXEL = FSize(1.0 / (WINDOW.w - 1), 1.0 / (WINDOW.h - 1));
        enum BOTTOM = FRect( 
                         PIXEL.w
                        ,1.0 - BOTTOM_H
                        ,1.0 - PIXEL.w
                        ,BOTTOM_H );
        enum UPPER_LEFT = FRect(
                         PIXEL.w
                        ,PIXEL.h
                        ,0.15
                        ,BOX.h );
        enum BTN = FRect(
                         PIXEL.w
                        ,UPPER_LEFT.yh
                        ,UPPER_LEFT.w
                        ,1.0 - (UPPER_LEFT.yh + BOTTOM_H) - PIXEL.h);
        enum ENEMY_STATUS_BOXES = FRect( 
                         UPPER_LEFT.xw + PIXEL.w
                        ,UPPER_LEFT.y
                        ,BOX.w
                        ,BOX.h );
        enum PLAYER_STATUS_BOXES = FRect(
                         ENEMY_STATUS_BOXES.x
                        ,1.0 - BOX.h - BOTTOM_H - PIXEL.h / 2
                        ,BOX.w
                        ,BOX.h );
        enum MAIN = FRect(
                         ENEMY_STATUS_BOXES.x
                        ,ENEMY_STATUS_BOXES.yh
                        ,BOX.w
                        ,PLAYER_STATUS_BOXES.y - ENEMY_STATUS_BOXES.yh - PIXEL.h);
        enum LIST_MAIN_TOP = FRect(
                         ENEMY_STATUS_BOXES.x
                        ,ENEMY_STATUS_BOXES.y
                        ,ENEMY_STATUS_BOXES.w
                        ,BOX.h / 6);
        enum LIST_MAIN = FRect(
                         LIST_MAIN_TOP.x
                        ,LIST_MAIN_TOP.yh + PIXEL.h
                        ,LIST_MAIN_TOP.w
                        ,PLAYER_STATUS_BOXES.y - (LIST_MAIN_TOP.yh + PIXEL.h) - PIXEL.h);
        enum MSG = {
            float w = MAIN.w * 0.75;
            return FRect( MAIN.cx - w / 2, MAIN.y, w, MAIN.h * 0.75 ); 
        }();
        enum UPPER_RIGHT = FRect(
                         ENEMY_STATUS_BOXES.xw + PIXEL.w
                        ,ENEMY_STATUS_BOXES.y
                        ,1.0 - (ENEMY_STATUS_BOXES.xw + PIXEL.w)
                        ,0.5 );
        enum UNIT_DETAIL = FRect(
                         UPPER_RIGHT.x
                        ,UPPER_RIGHT.yh + PIXEL.h
                        ,UPPER_RIGHT.w
                        ,1.0 - UPPER_RIGHT.yh - BOTTOM_H - PIXEL.h * 2 );
    }
}



class FrameLayout: ILayout{
    mixin MLayout;

    private Layout layout;
    private Layout layout_inner;

    this(){
        layout_inner = new Layout()
                            .setOutsideMargin(2,2,2,2);
        layout = new Layout()
                    .add((g,bounds){
                        g.set(Color.L_GRAY);
                        g.line(bounds);
                    })
                    .add(layout_inner);
    }

    void clear(){
        layout_inner.clear;
    }

    typeof(this) add(ILayout l){
        layout_inner.add(l);
        return this;
    }

    override void ctrlInner(Rect bounds){
        layout.ctrl(bounds);
    }

    override void drawInner(Graphics g, Rect bounds){
        layout.draw(g,bounds);
    }
}