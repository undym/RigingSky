module scene.settecscene;

import laziness;
import scene.abstscene;
import tec;
import unit;
import widget.btn;
import widget.list;

class SetTecScene: AbstScene{
    mixin ins;

    private{
        List learned_list;
        List setting_list;
        Tec info;
        //!null
        PUnit target;
        Tec.Type learned_list_type_now;
    }

    private this(){
        learned_list = new List( Util.list_draw_elm_num );
        setting_list = new List( Util.list_draw_elm_num );
    }

    override void start(){
        foreach(p; Unit.players){
            if(!p.exists){continue;}

            target = p;
            
            setting_list.clear;
            setSettingList(p);
            break;
        }

        setup;
        super.start;
    }

    protected void setup(){
        clear;
        
        super.addEsc();
        
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT,{
            return new FrameLayout()
                    .add(new Labels(Util.font)
                        .add!"top"("-技のセット-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new BorderLayout()
                .add!("top",0.8)({
                    import std.traits: EnumMembers;
                    import widget.groupbtn;
                    GroupBtn gb = GroupBtn.ofY;
                    gb.add("全て",{
                        learned_list.clear;
                        [EnumMembers!(Tec.Type)].each!((type){
                            setLearnedList(type, target);
                        });
                    });
                    [EnumMembers!(Tec.Type)].each!((type){
                        gb.add(format!"%s"(type),{
                            learned_list.clear;
                            setLearnedList(type, target);
                        });
                    });
                    gb.push(0);
                    return gb;
                }())
                .add!"center"(
                    new Btn("＞戻る",{
                        end();
                    })
                )
            )
        );
        
        add(Bounds.Ratio.LIST_MAIN, new BorderLayout()
            .add!("center",0.6)(new XLayout()
                .add(learned_list)
                .add(new Layout()
                    .setOutsideMargin(0,0,0,1)
                    .add(setting_list)
                )
            )
            .add!("right",0.4)(new VariableLayout({
                static Layout l;
                if(l is null){
                    l = new Layout();
                    l.add(new Labels(Util.font)
                        .add!"top"(()=> format!"[%s]"(info))
                        .add(()=> format!"<%s>"( info.type ))
                        .add(new XLayout()
                            .add(new Label(Util.font, ()=> info.mp_cost > 0 ? format!"MP:%.0f%%"(info.mp_cost) : "") )
                            .add(new Label(Util.font, ()=> info.tp_cost > 0 ? format!"TP:%.0f%%"(info.tp_cost) : "") )
                            .add(ILayout.empty)
                        )
                        .add(ILayout.empty)
                        .addln(()=> info.info)
                    );
                }
                return info is null ? ILayout.empty : l;
            }))
        );

        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(g,bounds)=> drawChoosedUnitFrame(g,target));
        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout());

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);
        add((g,bounds){
            DrawUnitDetail.set( target );
        });

        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(bounds){
            if(Mouse.left != 1){return;}

            foreach(p; Unit.players){
                if(!p.exists){continue;}

                if(p.bounds.contains( Mouse.point )){
                    target = p;
                    learned_list.clear;
                    setLearnedList( learned_list_type_now, p );
                    setting_list.clear;
                    setSettingList(p);
                    break;
                }
            }
        });

    }

    private void setLearnedList(Tec.Type type, PUnit p){
        learned_list_type_now = type;
        learned_list.separater( format!"%s"(type) );

        Tec.getTypeValues(type)
            .filter!(tec=> p.isLearned(tec) && tec != Tec.empty)
            .each!((tec){
                learned_list.add( tec.toString,{
                    foreach(t; p.tecs){
                        if(t == tec){
                            return;
                        }
                    }

                    foreach(i,t; p.tecs){
                        if(t == Tec.empty){
                            p.tecs[i] = tec;
                            setting_list.clear(/*keep_page*/true);
                            setSettingList(p);
                            return;
                        }
                    }

                },{
                    info = tec;
                });
            });
    }

    private void setSettingList(PUnit p){
        setting_list.separater(p.name);

        p.tecs
            .each!((tec){
                if(tec == Tec.empty){
                    setting_list.add("----",{

                    },{

                    });
                }else{
                    setting_list.add( tec.toString, {
                        foreach(i,t; p.tecs){
                            if(t == tec){
                                p.tecs[i] = Tec.empty;
                                break;
                            }
                        }

                        setting_list.clear(/*keep_page*/true);
                        setSettingList(p);
                    },{
                        info = tec;
                    });
                }
            });
    }
}
