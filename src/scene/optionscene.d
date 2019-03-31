module scene.optionscene;

import laziness;
import widget.btn;

class OptionScene: Scene{
    mixin ins;

    override void start(){
        setup;
        super.start;
    }

    private void setup(){
        clear;

        add((bounds){
            if(Mouse.right == 1 || Key.get!"ESC" == 1){
                end();
            }
        });

        add(FRect(0,0,1,1),(g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(FRect(0.1,0.05,0.2,0.05), Message.ins);

        add(FRect(0.1, 0.2, 0.8, 0.6),
            new XLayout()
                .add(new YLayout()
                    .add(createBtn("画面サイズx1",{
                        Window.setVisibleSize( Bounds.WINDOW.w, Bounds.WINDOW.h );
                        Message.ins.set( "WindowSize x1" );
                    }))
                    .add(createBtn("画面サイズx2",{
                        Window.setVisibleSize( Bounds.WINDOW.w * 2, Bounds.WINDOW.h * 2 );
                        Message.ins.set( "WindowSize x2" );
                    }))
                )
                // .add(new YLayout()
                //     .add(createBtn("リスト項目表示数-",{
                //         Util.list_draw_elm_num--;

                //         const int min = 16;
                //         if(Util.list_draw_elm_num <= min){
                //             Util.list_draw_elm_num = min;
                //             Message.ins.set( format!"リスト項目表示数:%s（最小）"(Util.list_draw_elm_num) );
                //         }else{
                //             Message.ins.set( format!"リスト項目表示数:%s"(Util.list_draw_elm_num) );
                //         }
                //     }))
                //     .add(createBtn("リスト項目表示数+",{
                //         Util.list_draw_elm_num++;

                //         const int max = 26;
                //         if(Util.list_draw_elm_num >= max){
                //             Util.list_draw_elm_num = max;
                //             Message.ins.set( format!"リスト項目表示数:%s（最大）"(Util.list_draw_elm_num) );
                //         }else{
                //             Message.ins.set( format!"リスト項目表示数:%s"(Util.list_draw_elm_num) );
                //         }
                //     }))
                // )
                .add(ILayout.empty)
                .add(ILayout.empty)
        );

        debug{
            add(FRect(0.1, 0.8, 0.8, 0.2),new XLayout()
                .add(new YLayout()
                    .add(createBtn("EffectTest",{
                        import effect.test;
                        EffectTest.run;
                    }))
                    .add(createBtn("アイテム入手",{
                        int num = 99;
                        import item;
                        Item.values
                            .each!((item){
                                item.num += num;
                                item.got = true;
                            });

                        Message.ins.set(format!"Item+%s"(num));
                    }))
                    .add(createBtn("お金入手",{
                        int value = 99999999;
                        PlayData.yen += value;
                        Message.ins.set(format!"yen+%s"(value));
                    }))
                    .add(createBtn("装備入手",{
                        import eq;
                        int value = 1;
                        foreach(_eq; Eq.values){
                            _eq.num += value;
                            _eq.got = true;
                        }
                        foreach(ear; EqEar.values){
                            ear.num += value;
                            ear.got = true;
                        }
                        Message.ins.set(format!"全装備+%s"(value));
                    }))
                )
                .add(new YLayout()
                    .add(createBtn("prm",{
                        import std.traits;
                        import unit;
                        foreach(p; Unit.players){
                            foreach(prm; [EnumMembers!(Unit.Prm)]){
                                p.prm(prm).base += 999;
                            }
                        }
                    }))
                    .add(createBtn("AppearBtn",{
                        Test.appear_all_btn = true;

                        Message.ins.set("ボタン出現");
                    }))
                    .add(createBtn("EnemiessHP = 0",{
                        import unit;
                        foreach(e; Unit.enemies){
                            e.hp = 0;
                        }
                    }))
                    .add(createBtn("PlayersHP = 0",{
                        import unit;
                        foreach(p; Unit.players){
                            p.hp = 0;
                        }
                    }))
                )
                .add(new YLayout()
                    .add(createBtn("技習得",{
                        import std.traits;
                        import unit;
                        import tec;
                        foreach(p; Unit.players){
                            foreach(t; Tec.values){
                                p.setLearned(t, true);
                            }
                        }
                        Message.ins.set("技習得");
                    }))
                    .add(createBtn("PlayersHPMPTP9999",{
                        import unit;
                        foreach(p; Unit.players){
                            p.hp = 9999;
                            p.mp = 9999;
                            p.tp = 9999;
                        }
                    }))
                )
                .add({
                    import scene.dungeonscene;
                    import dungeon;
                    import widget.list;

                    List l = new List(/*one_page_elm_num*/7);
                    l.separater("イベント発生(ダンジョン内)");
                    Event.values.each!((ev){
                        l.add( ev.toString,{
                            if(Dungeon.now is null){return;}
                            
                            ev.happen();
                        },{

                        });
                    });
                    return l;
                }())
            );
        }
    }

    
    private Btn createBtn(string name, void delegate() push){
        Btn btn = new Btn(name,push);
        btn.set!"frame"(Color.WHITE);
        return btn;
    }
}


private class Message: InnerLayout{
    mixin ins;

    string name;
    int color_cnt;

    this(){
        Label l = new Label(Util.font, ()=> name,{
            Color col = Color( color_cnt, color_cnt, color_cnt );
            if(color_cnt > 0){
                color_cnt -= 3;
                if(color_cnt < 0){color_cnt = 0;}
            }
            return col;
        });
        add(l);
    }

    void set(string str){
        this.name = str;
        color_cnt = 255;
    }
}
