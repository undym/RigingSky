module scene.dungeonscene;


import laziness;
import scene.abstscene;
import effect;
import dungeon;

class DungeonScene: AbstScene{
    mixin ins;

    private this(){

    }

    override void start(){
        Util.msg.set( format!"[%s]に侵入した..."(Dungeon.now) );
        drawDungeonName( Dungeon.now.toString, Bounds.toPixelRect( Bounds.Ratio.MAIN ).center );

        Event.now = Event.empty;

        setup;
        super.start;
    }
    
    private void setup(){
        clear;
        
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT, new FrameLayout()
            .add( (new Label(Util.font, "-ダンジョン-")).setDrawPoint!"top" )
        );
        add(Bounds.Ratio.BTN, createBtn);

        add(Bounds.Ratio.MAIN, (g,bounds){
            Area.now.draw(g,bounds);
        });
        add(Bounds.Ratio.MAIN, DungeonEvent.ins);
        add(Bounds.Ratio.MAIN, DrawDungeonData.ins);

        add(Bounds.Ratio.MSG, Util.msg);

        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.ENEMY_STATUS_BOXES, DrawEnemyStatusBoxes.ins);
        
        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);

        add((bounds){
            if(Dungeon.escape){
                Dungeon.escape = false;
                Util.msg.set(format!"[%s]を脱出します..."(Dungeon.now)); ncwait; cwait;
                end;
            }
        });
    }
}


private ILayout createBtn(){
    FrameLayout l = new FrameLayout();
    l.add({
        import widget.btn;
        auto box = new PackedYLayout( Bounds.BTN_H );
        box.add(new Btn("アイテム",{
            import scene.itemscene;
            ItemSceneDungeon.ins.start;
        },{

        }));
        return box;
    }());

    return l;
}


class DungeonEvent: InnerLayout{
    mixin ins;

    Event before_ev;
    Anime anime;
    int anime_size_count;

    private this(){

        add((bounds){
            if(!bounds.contains( Mouse.point )){return;}

                 if(Mouse.left  == 1){Event.now.leftClick();}
            else if(Mouse.right == 1){Event.now.rightClick();}
        });

        add((g,bounds){
            if(before_ev != Event.now){
                before_ev = Event.now;

                anime = Event.now.getAnime;
                if(Event.now.isResetZoom){
                    anime_size_count = 0;
                }
            }

            anime_size_count++;
            const float size_mul = 1.0 - 1.0 / anime_size_count;
            const float w_ratio = cast(float)bounds.w / anime.w;
            const float h_ratio = cast(float)bounds.h / anime.h;
            const float ratio = w_ratio < h_ratio
                            ? w_ratio
                            : h_ratio
                            ;
            int w = cast(int)(anime.w * ratio * size_mul);
            int h = cast(int)(anime.h * ratio * size_mul);
            anime.draw( g, Rect(bounds.cx - w / 2, bounds.cy - h / 2, w, h) ,Window.count );
        });
    }

    // void reset(){
    //     ev = Event.empty;
    //     anime = Anime.empty;
    //     anime_size_count = 0;
    // }

}


/**

*/
private void drawDungeonName(string name, Point center){
    import effect: Effect;
    
    Font tex_font = Font.of(40 ,Font.Style.ITALIC);
    Size tex_size = getDrawSize( tex_font, name );
    Texture tex = new Texture( tex_font, name ,Color.WHITE );
    Rect bounds = Rect( center.x - tex_size.w / 2 ,center.y - tex_size.h / 2 , tex_size.w ,tex_size.h );

    void setEffect(Rect drect ,Rect srect ,int over){
        int alpha = 255;
        Effect.add((g,cnt){
            if(cnt < over){
                setImgColorMod( tex ,Color(255,255,255) ,{
                    g.draw( tex ,drect.move( uniform!"[]"(-3,3), uniform!"[]"(-3,3) ) ,srect );
                });
                return true;
            }else{
                setImgColorMod( tex ,Color(255,255,255,alpha) ,{
                    g.draw( tex ,drect ,srect );
                });
                alpha -= 10;
                return alpha > 0;
            }
        });
    }
    //偶数か奇数かで描画を調整
    int add = bounds.w % 2 + 1;
    //奇数の時だけ右端を別に描画
    if(add == 1){
        Rect drect = Rect( bounds.xw - 1 ,bounds.y ,1 ,bounds.h );
        Rect srect = Rect( bounds.xw - 1 ,0 ,1 ,bounds.h );
        setEffect( drect ,srect ,bounds.w );
    }

    Effect.add((g,cnt){
        bool reached_lim;
        int w = cnt * 20;
        if(w > bounds.w){
            w = bounds.w;
            reached_lim = true;
        }
        int over = (bounds.w - w) / 10;

        for(int i = 0; i < w; i+= 2){
            Rect drect = Rect( bounds.x + i ,bounds.y ,1 ,bounds.h );
            Rect srect = Rect( i ,0 ,1 ,bounds.h );
            setEffect( drect ,srect ,over );
        }
        for(int i = bounds.w - add; i > bounds.w - w; i-= 2){
            Rect drect = Rect( bounds.x + i ,bounds.y ,1 ,bounds.h );
            Rect srect = Rect( i ,0 ,1 ,bounds.h );
            setEffect( drect ,srect ,over );
        }
        return !reached_lim;
    });
}