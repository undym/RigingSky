module scene.abstscene;

import laziness;
import unit;
import widget.gage;

abstract class AbstScene: Scene{

    this(){
    }

    override void ctrl(Rect bounds){
        super.ctrl(bounds);

        if(Key.get!"F1" == 1){
            import scene.optionscene;
            (new OptionScene).ins.start;
        }
    }
    override void draw(Graphics g, Rect bounds){
        super.draw(g,bounds);

        import effect;
        Effect.draw(g);
    }

    override void cwait(){
        int count;
        wait(()=> 
               Mouse.left == 1
            || (Mouse.left  > 0 && ++count % 4 == 0)
            || (Mouse.right > 0 && ++count % 4 == 0)
        );
    }

    protected void addEsc(){
        add(FRect(0,0,1,1),(bounds){
            if(Mouse.right == 1 || Key.get!"ESC" == 1){
                end();
            }
        });
    }
}

class DrawBottom: InnerLayout{
    mixin ins;

    private this(){
        add((g,bounds){
            g.set(Color.L_GRAY);
            g.line(bounds);
        });

        add(new XLayout()
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(ILayout.empty)
            .add(new YLayout()
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add( (new Label(Util.font, ()=>format!"%s円"(PlayData.yen))).setDrawPoint!"right".set(Color.YELLOW) )
            )
        );
    }
}


class DrawStatusBox: InnerLayout{
    /**nullable get_unit()*/
    this(Unit delegate() get_unit){
        // this(V delegate() now
        //     ,V delegate() max
        //     ,Color delegate() col_front
        //     ,Color delegate() col_ground
        //     ,string delegate() left_str
        //     ,string delegate() right_str
        //     ,Font font
        //     ,int gage_h = 1
        //     ) {
        import condition;
        string createConditionStr(Condition.Type[] types){
            string str;
            bool split;
            Unit u = get_unit();
            foreach(type; types){
                Condition cond = u.getCondition(type);
                if(cond == Condition.empty){continue;}

                if(!split){
                    split = true;
                    str ~= format!"%s%s"( cond, u.getConditionValue(type) );
                }else{
                    str ~= format!"/%s%s"( cond, u.getConditionValue(type) );
                }
            }
            return str;
        }

        VariableLayout job_layout = {
            import job;
            ILayout p_job =    new Gage!int(
                                     ()=> (cast(PUnit)get_unit()).getJobExp
                                    ,()=> (cast(PUnit)get_unit()).job.lvup_exp
                                    ,()=> Color.WHITE.bright( Window.count )
                                    ,()=> Color.CLEAR
                                    ,()=> get_unit().job.toString
                                    ,{
                                        PUnit p = (cast(PUnit)get_unit());
                                        if(p.getJobLv >= Job.MAX_LV){return "★";}
                                        return format!"Lv%s"( p.getJobLv );
                                    }
                                    ,Util.font
                                );
            ILayout e_job =  new Label( Util.font, ()=>get_unit().job.toString );
            return new VariableLayout({
                Unit u = get_unit();
                if(u is null){return ILayout.empty;}

                return cast(PUnit)u ? p_job : e_job;
            });
        }();

        auto box = new YLayout()
                            .add(new Label(Util.font, ()=> get_unit().name))
                            .add(
                                new Gage!double(
                                     ()=> get_unit().hp
                                    ,()=> get_unit().prm!"MAX_HP".total
                                    ,()=> Color.GREEN.bright( Window.count )
                                    ,()=> Color.CLEAR
                                    ,()=> "HP"
                                    ,()=> format!"%.0f"( get_unit().hp )
                                    ,Util.font
                                )
                            )
                            .add(
                                new Gage!double(
                                     ()=> get_unit().mp
                                    ,()=> get_unit().prm!"MAX_MP".total
                                    ,()=> Color.RED.bright( Window.count )
                                    ,()=> Color.CLEAR
                                    ,()=> "MP"
                                    ,()=> format!"%.0f%%"( get_unit().mp )
                                    ,Util.font
                                )
                            )
                            .add(
                                new Gage!double(
                                     ()=> get_unit().tp
                                    ,()=> get_unit().prm!"MAX_TP".total
                                    ,()=> Color.CYAN.bright( Window.count )
                                    ,()=> Color.CLEAR
                                    ,()=> "TP"
                                    ,()=> format!"%.0f%%"( get_unit().tp )
                                    ,Util.font
                                )
                            )
                           .add(new Label(Util.font,{
                               if(get_unit().ep > 0){return "EP";}
                               return "";
                            }, Color.CYAN))
                           .add(new Label(Util.font,{
                                alias Type = Condition.Type;
                                return createConditionStr( [Type.GOOD_LV1, Type.GOOD_LV2, Type.GOOD_LV3] );
                            }, Color.CYAN))
                            .add(new Label(Util.font,{
                                alias Type = Condition.Type;
                                return createConditionStr( [Type.BAD_LV1, Type.BAD_LV2, Type.BAD_LV3] );
                            }, Color.RED))
                            .add(job_layout)
                            .add(
                                new Gage!double(
                                     ()=> get_unit().exp
                                    ,()=> get_unit().getLvUpExp
                                    ,()=> Color.YELLOW.bright( Window.count )
                                    ,()=> Color.CLEAR
                                    ,()=> "Lv"
                                    ,()=> format!"%.0f"( get_unit().prm!"LV".total )
                                    ,Util.font
                                )
                            )
                            ;

        setOutsideMargin(2,2,2,2);
        add(new VariableLayout({
            if(get_unit() is null || !get_unit().exists){return ILayout.empty;}
            return box;
        }));

    }
}


private class DrawStatusBoxes: InnerLayout{

    protected this(int length, Unit delegate(int) get_unit){
        add((g,bounds){
            g.set(Color.L_GRAY);
            g.line(bounds);
            
            float x = bounds.x;
            float w = cast(float)bounds.w / length;
            foreach(i; 0..length){
                g.line( x ,bounds.y, x, bounds.yh - 1 );
                x += w;
            }
        });

        add({
            import std.range: iota;
            auto box = new XLayout;
            length.iota
                .each!((i){
                    box.add(new Layout()
                        .add((g,bounds){
                            Unit u = get_unit(i);
                            if(u is null || !u.exists){return;}
                            if(u.dead){
                                g.set( Color(255,0,0,100) );
                                g.fill( u.bounds );
                            }
                            if(u == DrawUnitDetail.detail_unit){
                                g.set( Color(255,255,0,30) );
                                g.fill( u.bounds );
                            }
                        })
                        .add(new DrawStatusBox(()=> get_unit(i)))
                        .add((bounds){
                            Unit u = get_unit(i);
                            if(u !is null){
                                u.bounds = bounds.add(1,1,-1,-2);
                            }
                        })
                    );
                });
            return box;
        }());
    }
}


class DrawPlayerStatusBoxes: DrawStatusBoxes{
    mixin ins;

    private this(){
        super( Unit.PLAYER_NUM, i=> Unit.players[i] );
    }
}


class DrawEnemyStatusBoxes: DrawStatusBoxes{
    mixin ins;

    private this(){
        super( Unit.ENEMY_NUM, i=> Unit.enemies[i] );
    }
}



class DrawUnitDetail: InnerLayout{
    mixin ins;

    static private Unit detail_unit;

    static void set(Unit u){
        if(u == detail_unit){return;}

        detail_unit = u;
    }

    import eq;
    static private Eq.Pos info_eq_pos;
    static private int info_ear_index;

    static void setEqInfo(Eq.Pos eq_pos){
        info_eq_pos     = eq_pos;
        info_ear_index = -1;
    }

    static void setEarInfo(int index){
        info_ear_index = index;
    }

    private this(){

        add((g,bounds){
            g.set(Color.L_GRAY);
            g.line(bounds);
        });

        add((g,bounds){
            foreach(u; Unit.all){
                if(u.exists && u.bounds.contains( Mouse.point )){
                    set(u);
                    break;
                }
            }
        });

        DrawStatusBox st_box = new DrawStatusBox(()=> detail_unit);
        auto l = new XLayout()
                        .setOutsideMargin(2,2,2,2)
                        .add(new YLayout()
                            .add(st_box)
                            .add(new XLayout()
                                .add(new Labels(Util.font)
                                    .add(()=>format!"力:%.0f"( detail_unit.prm!"STR".total ))
                                    .add(()=>format!"光:%.0f"( detail_unit.prm!"LIG".total ))
                                    .add(()=>format!"鎖:%.0f"( detail_unit.prm!"CHN".total ))
                                    .add(()=>format!"銃:%.0f"( detail_unit.prm!"GUN".total ))
                                )
                                .add(new Labels(Util.font)
                                    .add(()=>format!"魔:%.0f"( detail_unit.prm!"MAG".total ))
                                    .add(()=>format!"闇:%.0f"( detail_unit.prm!"DRK".total ))
                                    .add(()=>format!"過:%.0f"( detail_unit.prm!"PST".total ))
                                    .add(()=>format!"弓:%.0f"( detail_unit.prm!"ARR".total ))
                                )
                            )
                        )
                        .add({
                            return new BorderLayout()
                                    .add!("center",0.6)({
                                        import std.traits: EnumMembers;
                                        Labels l = new Labels(Util.font);

                                        void addEqEar(int index, EqEar delegate() get_ear){
                                            l.add(new Layout()
                                                .add((g,bounds){
                                                    if(bounds.contains( Mouse.point )){
                                                        g.set(Color.D_CYAN.darker);
                                                        g.fill(bounds);

                                                        setEarInfo( index );
                                                    }
                                                })
                                                .add(new Label(Util.font, ()=>format!"耳:%s"( get_ear() )) )
                                            );
                                        }

                                        void addEq(Eq.Pos pos, Eq delegate() get_eq){
                                            l.add(new Layout()
                                                .add((g,bounds){
                                                    if(bounds.contains( Mouse.point )){
                                                        g.set(Color.D_CYAN.darker);
                                                        g.fill(bounds);

                                                        setEqInfo( pos );
                                                    }
                                                })
                                                .add(new Label(Util.font, ()=>format!"%s:%s"( pos, get_eq() )) )
                                            );
                                        }

                                        EqEar.EAR_NUM.iota.each!((i){
                                            addEqEar( i, ()=>detail_unit.eqEar(i) );
                                        });
                                        
                                        [EnumMembers!(Eq.Pos)].each!((pos){
                                            addEq( pos, ()=>detail_unit.eq(pos) );
                                        });
                                        return l;
                                    }())
                                    .add!("bottom",0.4)(new VariableLayout({
                                        static ILayout eq;
                                        static ILayout eq_ear;
                                        if(eq is null){
                                            eq = new Labels(Util.font)
                                                    .add(()=>format!"[%s]"( detail_unit.eq(info_eq_pos) ))
                                                    .addln(()=>detail_unit.eq(info_eq_pos).getInfo());
                                            eq_ear = new Labels(Util.font)
                                                    .add(()=>format!"[%s]"( detail_unit.eqEar(info_ear_index) ))
                                                    .addln(()=>detail_unit.eqEar(info_ear_index).getInfo());
                                        }

                                        return info_ear_index != -1 ? eq_ear : eq;
                                    }))
                                    ;
                        }())
                        ;



        add(new VariableLayout({
            if(detail_unit is null || !detail_unit.exists){return ILayout.empty;}
            return l;
        }));
    }

}



class DrawDungeonData: InnerLayout{
    mixin ins;
    
    private this(){
        import dungeon;
        
        add(new BorderLayout()
            .add!("center",0.82)(ILayout.empty)
            .add!("bottom",0.18)(
                new Labels(Util.font)
                    .add(()=> format!"[%s]"(Dungeon.now))
                    .add(()=> format!"Rank:%s"( Dungeon.now.getRank ))
                    .add(new Gage!int(
                            ()=> Dungeon.now_au
                        ,()=> Dungeon.now.getAU
                        ,()=> Color.CYAN.bright( Window.count )
                        ,()=> Color.CLEAR
                        ,()=> "AU"
                        ,()=> format!"%s/%s"( Dungeon.now_au, Dungeon.now.getAU )
                        ,Util.font
                    ))
            )
        );
    }
}


class DrawUpperRight: InnerLayout{
    mixin ins;

    private this(){
        add(new FrameLayout()
            .add(new YLayout()
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
                .add(ILayout.empty)
            )
        );
    }
}


void drawChoosedUnitFrame(Graphics g, Unit target){
    if(target is null){return;}
    g.set(Color.ORANGE.darker);
    g.fill( target.bounds.x + 1 ,target.bounds.y + 1, target.bounds.w - 2, Util.FONT_SIZE );
    // g.line(target.bounds);
    // g.line(target.bounds.add(-1,-1,2,2));
}