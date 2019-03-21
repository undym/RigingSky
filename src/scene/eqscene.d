module scene.eqscene;

import laziness;
import scene.abstscene;
import eq;
import unit;
import widget.btn;
import widget.list;

class EqScene: AbstScene{
    mixin ins;

    private{
        List list;
        Eq info_eq;
        EqEar info_ear;
        //!null
        PUnit target;
        void delegate() reset_list;
    }

    private this(){
        list = new List( Util.list_draw_elm_num );
    }

    override void start(){
        foreach(p; Unit.players){
            if(!p.exists){continue;}

            target = p;
            DrawUnitDetail.set( p );
            
            break;
        }

        foreach(p; Unit.players){
            if(!p.exists){continue;}
            fullCare(p);
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
                        .add!"top"("-装備-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new BorderLayout()
                .add!("top",0.8)({
                    import std.traits: EnumMembers;
                    import widget.groupbtn;

                    GroupBtn gb = GroupBtn.ofY;

                    gb.add("全て",{
                        reset_list = {
                            list.clear;
                            setEarList(target);
                            foreach(pos; [EnumMembers!(Eq.Pos)]){
                                setEqList(pos, target);
                            }
                        };
                        reset_list();
                    });

                    gb.add("耳",{
                        reset_list = {
                            list.clear;
                            setEarList(target);
                        };
                        reset_list();
                    });

                    [EnumMembers!(Eq.Pos)].each!((pos){
                        gb.add(format!"%s"(pos),{
                            reset_list = {
                                list.clear;
                                setEqList(pos, target);
                            };
                            reset_list();
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
                .add(list)
            )
            .add!("right",0.4)(new VariableLayout({
                static Layout l_eq;
                static Layout l_ear;
                if(l_eq is null){
                    l_eq = new Layout()
                            .add(new Labels(Util.font)
                                .add!"top"(()=> format!"[%s]"(info_eq))
                                .add(()=> format!"<%s>"( info_eq.pos ))
                                .add(()=> format!"所持数:%s"( info_eq.num ))
                                .add(ILayout.empty)
                                .addln(()=> info_eq.getInfo())
                            );
                }
                if(l_ear is null){
                    l_ear = new Layout()
                            .add(new Labels(Util.font)
                                .add!"top"(()=> format!"[%s]"(info_ear))
                                .add(()=> "<耳>")
                                .add(()=> format!"所持数:%s"( info_ear.num ))
                                .add(ILayout.empty)
                                .addln(()=> info_ear.getInfo())
                            );
                }
                if(info_eq  !is null){return l_eq;}
                if(info_ear !is null){return l_ear;}
                return ILayout.empty;
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
                    reset_list();
                    break;
                }
            }
        });

    }

    private void swapEar(PUnit p, int i, EqEar new_ear){
        EqEar old_ear = p.eqEar(i);
        
        if(new_ear == old_ear){return;}

        old_ear.num++;
        new_ear.num--;

        p.setEqEar(i, new_ear);
        p.forceEquip();
        fullCare(p);

        DrawUnitDetail.setEarInfo( i );
    }

    private void swapEq(PUnit p, Eq.Pos pos, Eq new_eq){
        Eq old_eq = p.eq( pos );

        if(new_eq == old_eq){return;}

        old_eq.num++;
        new_eq.num--;

        p.setEq( pos, new_eq );
        p.forceEquip();
        fullCare(p);
        
        DrawUnitDetail.setEqInfo( pos );
    }

    private void setEarList(PUnit p){
        list.separater("耳");

        list.add("外す",{
            foreach(i; 0..EqEar.EAR_NUM){
                swapEar(p, i, EqEar.耳たぶ);
            }
        },{

        });

        EqEar.values
            .filter!((ear){
                if(ear.num > 0){return true;}
                foreach(i; 0..EqEar.EAR_NUM){
                    if(p.eqEar(i) == ear){return true;}
                }
                return false;
            })
            .each!((ear){
                auto elm = list.add( ear.toString, &ear.num, {
                    if(ear.num <= 0){return;}

                    foreach(i; 0..EqEar.EAR_NUM){
                        if(p.eqEar(i) == EqEar.耳たぶ){
                            swapEar(p, i, ear );

                            return;
                        }
                    }
                },{
                    info_eq = null;
                    info_ear = ear;
                });

                Color delegate() col = {
                    foreach(i; 0..EqEar.EAR_NUM){
                        if(p.eqEar(i) == ear){
                            return Color.YELLOW;
                        }
                    }
                    return Color.WHITE;
                };
                elm.set!"string"(col);
                elm.set!"num"(col);
            });
    }

    private void setEqList(Eq.Pos pos, PUnit p){
        list.separater( format!"%s"(pos) );
        
        Eq.getPosValues(pos)
            .filter!(eq=> eq.num > 0 || p.eq(pos) == eq)
            .each!((eq){
                auto elm = list.add( eq.toString, eq.numPtr(), {
                    if(eq.num <= 0){return;}

                    swapEq( p, eq.pos, eq );

                },{
                    info_eq = eq;
                    info_ear = null;
                });

                Color delegate() col = ()=>p.eq(pos) == eq ? Color.YELLOW : Color.WHITE;
                elm.set!"string"(col);
                elm.set!"num"   (col);
            });
    }
}

private void fullCare(Unit u){
    u.hp = u.prm!"MAX_HP".total;
    u.mp = u.prm!"MAX_MP".total;
    u.tp = u.prm!"MAX_TP".total;
}