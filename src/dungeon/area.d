module dungeon.area;

import laziness;


abstract class Area{
    mixin Values!AreaValues;

    static Area now;

    protected Img bg;

    private this(Img bg){
        this.bg = bg;
    }

    void draw(Graphics g, Rect bounds){
        g.draw( bg, bounds );
    }

    void drawNormalBattle(Graphics g, Rect bounds){
        g.clip(bounds,{
            Rect drect = bounds;
                drect.h = 1;
            Rect srect = Rect(0, 0, bg.w, 1);
            foreach(i; 0..bounds.h){
                srect.y = bg.h * i / bounds.h;
                srect.h = uniform!"[]"(1,5);

                drect.y = bounds.y + i;

                g.draw( bg, drect, srect );
            }
        });
    }

    void drawBossBattle(Graphics g, Rect bounds){
        g.clip(bounds,{
            Rect drect = bounds;
                drect.h = 1;
            Rect srect = Rect(0, 0, bg.w, 1);
            foreach(i; 0..bounds.h){
                srect.y = bg.h * i / bounds.h;
                srect.h = uniform!"[]"(1,5);

                drect.y = bounds.y + i;

                g.draw( bg, drect, srect );
            }
        });
    }

    void drawExBattle(Graphics g, Rect bounds){
        g.clip(bounds,{
            Rect drect = bounds;
                drect.h = 1;
            Rect srect = Rect(0, 0, bg.w, 1);
            foreach(i; 0..bounds.h){
                srect.y = bg.h * i / bounds.h;
                srect.h = uniform!"[]"(1,5);

                drect.y = bounds.y + i;

                g.draw( bg, drect, srect );
            }
        });
    }

}


private class AreaValues{
    //-----------------------------------------------------
    @Value
    static Area  再構成トンネル(){static Area res; return res !is null ? res : (res = new class Area{
        this(){super(new Img("img/再構成トンネル.png"));}
    });}
    //-----------------------------------------------------
    //
    //-----------------------------------------------------
}