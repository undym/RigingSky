module scene.titlescene;

import laziness;
import scene.abstscene;


class TitleScene: Scene{
    mixin ins;

    private this(){

    }

    override void start(){
        setup();
        super.start();
    }

    private void setup(){
        clear;

        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        Font small_font = Font.of(12);
        add(new YLayout()
            .add(new BorderLayout()
                .add!("left")(new PackedYLayout( small_font.size )
                    .add(new Label(small_font, "RigingSky"))
                    .add(new Label(small_font, "version:"~Util.GameVersion.toString()))
                )
                .add!("center")(ILayout.empty)
                .add!("right")(new Label(small_font, "制作:UMente").setDrawPoint!"upper_right")
            )
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(new Title("NEW GAME",{
                setNewGame();
                end();
            }))
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(new Title("CONTINUE",{
                setContinue();
                end();
            }))
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(ILayout.empty)
        );
    }

    private void setNewGame(){
        import player;
        import unit;
        Unit.players[0] = Player.スメラギ.ins;
        Unit.players[1] = Player.よしこ.ins;
        foreach(p; Unit.players){
            if(p.getPlayer != Player.empty){
                p.getPlayer.member = true;
            }
        }

        import item;
        Item.サンタクララ薬.num += 5;
        Item.スティックパン.num += 10;
        Item.蛍草.num += 10;
        PlayData.yen += 1000;
    }

    private void setContinue(){
        import save;
        Save.load();
    }
}



private class Title: InnerLayout{

    this(const string str, void delegate() push){
        import std.string: column;
        Font font = Font.of(20, Font.Style.BOLD);
        int title_column = str.column;
        bool over;

        add((bounds){
            if(bounds.contains( Mouse.point )){
                over = true;
                if(Mouse.left == 1){
                    push();
                }
            }else{
                over = false;
            }
        });
        add((g,bounds){
            g.set(font);

            float w = 20;
            FPoint fp = FPoint( bounds.cx - (w * title_column / 2), bounds.cy );
            int i;

            foreach(dchar dc; str){
                import std.math;
                import std.conv;
                string s = dc.to!string;

                if(over){
                    g.set( Color.CYAN.bright( Window.count - i * 2 ) );   
                }else{
                    g.set(Color.WHITE);
                }
                
                g.str!"center"( s, fp.to!int );

                fp.x += w;
                i++;
            }
        });
    }
}