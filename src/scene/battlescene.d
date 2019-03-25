module scene.battlescene;

import laziness;
import scene.abstscene;
import dungeon;
import unit;
import tec;

class BattleScene: AbstScene{
    mixin ins;

    enum Type{
        NORMAL,
        BOSS,
        EX,
    }

    enum Result{
        WIN,
        LOSE,
        ESCAPE,
    }

    private{
        Type type;
        Result result;
        Layout tec_btn_panel;
        bool first_turn;
    }

    private this(){
        tec_btn_panel = new Layout;
    }


    Result start(Type type){
        this.type = type;
        this.result = Result.ESCAPE;
        this.first_turn = true;

        setup;
        initBattle;

        super.start;

        finishBattle;

        return result;
    }

    private void setup(){
        clear;

        add((bounds){
            if(first_turn){
                first_turn = false;
                turnEnd;
            }
        });
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });
        
        add(Bounds.Ratio.MAIN, (g,bounds){
            final switch(type){
                case Type.NORMAL:
                    Area.now.drawNormalBattle(g,bounds);
                    break;
                case Type.BOSS:
                    Area.now.drawBossBattle(g,bounds);
                    break;
                case Type.EX:
                    Area.now.drawExBattle(g,bounds);
                    break;
            }
        });
        add(Bounds.Ratio.MAIN, DrawDungeonData.ins);
        add(Bounds.Ratio.MSG, Util.msg);
        add(Bounds.Ratio.MAIN, new RatioLayout()
            .add(FRect(0, 0, 0.5, 0.3), TecInfo.ins)
        );

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT, new FrameLayout()
            .add( (new Label(Util.font, {
                    final switch(type){
                        case Type.NORMAL: return "-戦闘-";
                        case Type.BOSS  : return "-BOSS-";
                        case Type.EX    : return "-EXTRA-";
                    }
                }).setDrawPoint!"top" )
            )
        );
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(tec_btn_panel)
        );
        

        add((g,bounds){
            void draw(Unit u, Rect r){
                if(!u.exists){return;}

                foreach(t; Battle.targets){
                    if(t == u){
                        g.clip( r.add(1,1,-2,-2) ,{
                            g.set( Color.CYAN.darker );
                            Point[] points;
                            const float w = r.w * 0.6;
                            const float h = r.h * 0.6;
                            const int sp = cast(int)w;
                            const float w_sp = w / sp;
                            const float h_sp = h / sp;
                            float x = r.xw;
                            float y = r.yh - h;
                            foreach(i; 0..sp){
                                points ~= Point(x, r.yh);
                                points ~= Point(x, y);
                                x -= w_sp;
                                y += h_sp;
                            }
                            g.lines( points );
                        });
                        break;
                    }
                }
                foreach(a; Battle.attackers){
                    if(a == u){
                        g.clip( r.add(1,1,-2,-2) ,{
                            g.set( Color.RED.darker );
                            Point[] points;
                            const float w = r.w * 0.6;
                            const float h = r.h * 0.6;
                            const int sp = cast(int)w;
                            const float w_sp = w / sp;
                            const float h_sp = h / sp;
                            float x = r.x;
                            float y = r.y + h;
                            foreach(i; 0..sp){
                                points ~= Point(x, r.y);
                                points ~= Point(x, y);
                                x += w_sp;
                                y -= h_sp;
                            }
                            g.lines( points );  
                        });
                        break;
                    }
                }
                if(u == Battle.getPhaseUnit){
                    g.set( Color.ORANGE.darker );
                    g.fill( 
                        Rect(
                            r.x + 1,
                            r.y + 1,
                            r.w - 2,
                            Util.FONT_SIZE
                        )
                    );
                }

            }
            
            foreach(u; Unit.all){
                draw(u, u.bounds);
            }
        });
        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.ENEMY_STATUS_BOXES, DrawEnemyStatusBoxes.ins);

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);
    }

    private void initBattle(){
        Battle.attackers = [];
        Battle.targets = [];
        Battle.turn = 0;

        Battle.first_phase = uniform(1, Unit.ALL_NUM);
        Battle.phase = Battle.first_phase - 1;

        Unit.all
            .filter!(u=> u.exists && !u.dead)
            .each!((u){
                u.tp = 0;
                u.forceBattleStart;
            });
    }

    private void finishBattle(){
        foreach(e; Unit.enemies){
            e.exists = false;
            e.clearDropItem();
        }

        foreach(p; Unit.players){
            import std.traits: EnumMembers;
            foreach(prm; [EnumMembers!(Unit.Prm)]){
                p.prm(prm).battle = 0;
            }
        }

        tec_btn_panel.clear;
    }

    private void turnEnd(){
        if(Battle.turn != 0){
            Unit u = Battle.getPhaseUnit;
            if(u.exists && !u.dead){
                u.forcePhaseEnd;
            }
        }
        
        Unit.all
            .filter!(u=> u.exists && !u.dead)
            .each!(u=> u.judgeDead);


        if(Unit.players.all!(p=> !p.exists || p.dead)){
            lose;
            return;
        }

        if(Unit.enemies.all!(e=> !e.exists || e.dead)){
            win;
            return;
        }
        

        Battle.phase = (Battle.phase + 1) % Unit.ALL_NUM;
        if(Battle.phase == Battle.first_phase){
            Battle.turn++;
            Util.msg.set( format!"------%sターン目------"( Battle.turn ) ); cwait;
        }


        Unit u = Battle.getPhaseUnit;
        if(!u.exists || u.dead){
            turnEnd;
            return;
        }
        
        Util.msg.set( format!"%sの行動"( u.name ) ); cwait;
        
        u.forcePhaseStart();

        u.tp += 10;
        u.fixPrm;
        if(u.ep < 1){
            u.epCharge++;
            if(u.epCharge >= Unit.MAX_EP_CHARGE){
                u.epCharge = 0;
                u.ep = 1;
            }
        }

        u.judgeDead;
        if(u.dead){
            turnEnd;
            return;
        }

        if(cast(PUnit)u){
            setTecBtn( cast(PUnit)u );
        }else{
            EUnit e = cast(EUnit)u;
            e.ai( e, Unit.all );
            turnEnd;
        }
    }

    private void setTecBtn(PUnit p){
        import force;
        import widget.btn;

        ILayout createTecBtn(Tec tec){
            if(tec == Tec.empty){return ILayout.empty;}

            Btn btn;
            if(tec.passive){
                btn =   new Btn( tec.toString,{
                        },{
                            TecInfo.ins.set( tec, p );
                        });
                btn.set!"string"(Color(100,100,150));
                btn.set!"string_on"(Color(100,100,150));
            }else{
                btn =   new Btn( tec.toString,{
                            Unit[] targets;
                            if(tec.targetings & Targeting.SELECT){
                                Unit[] choosed = ChooseTarget.ins.startChoose();
                                if(choosed.length == 0){return;}

                                foreach(i; 0..tec.rndAttackNum()){
                                    targets ~= choosed;
                                }
                            }else{
                                targets = getTargets( tec.targetings, p, Unit.all, tec.rndAttackNum() );
                            }

                            tec.use( p, targets );
                            turnEnd;
                        },{
                            TecInfo.ins.set( tec, p );
                        });
                
                if(!tec.checkCost(p)){
                    btn.set!"string"(Color(150,100,100));
                }
            }
            return btn;
        }
        
        enum DRAW_TEC_BTN_NUM = 10;

        tec_btn_panel.clear;
        tec_btn_panel.add(new Layout()
            .add((bounds){
                if(!bounds.contains( Mouse.point )){return;}

                int getPageLim(){
                    return (p.tecs.length - 1) / DRAW_TEC_BTN_NUM;
                }

                if(Mouse.wheel > 0){
                    p.tec_btn_page--;
                    if(p.tec_btn_page < 0){
                        p.tec_btn_page = getPageLim();
                    }

                    setTecBtn(p);
                }else if(Mouse.wheel < 0){
                    p.tec_btn_page++;
                    if(p.tec_btn_page > getPageLim()){
                        p.tec_btn_page = 0;
                    }

                    setTecBtn(p);
                }
            })
            .add(new BorderLayout()
                .add!("top",0.05)(new Layout()
                    .add((g,bounds){
                        g.set(Color.ORANGE.darker);
                        g.fill(bounds);
                    })
                    .add(new Label(Util.font, p.name).setDrawPoint!"center")
                )
                .add!("center",0.75)({
                    YLayout box = new YLayout();

                    for(int i = p.tec_btn_page * DRAW_TEC_BTN_NUM; i < (p.tec_btn_page + 1 ) * DRAW_TEC_BTN_NUM; i++){
                        if(i < p.tecs.length){
                            box.add( createTecBtn( p.tecs[i] ) );
                        }else{
                            box.add(ILayout.empty);
                        }
                    }
                    return box;
                }())
                .add!("bottom",0.2)({
                    YLayout box = new YLayout();

                    box.add(new Btn("アイテム",{
                        import goods.item;
                        import scene.itemscene;
                        Item use_item = ItemSceneBattle.ins.startChoose(p);
                        if(use_item is null){return;}

                        Util.msg.set(format!"[%s]を使用"( use_item ));

                        import force;
                        Targeting targeting = use_item.getTargeting();
                        Unit[] targets;
                        if(use_item.getTargeting() & Targeting.SELECT){
                            targets = ChooseTarget.ins.startChoose();
                            if(targets.length == 0){return;}
                        }else{
                            targets = getTargets( use_item.getTargeting(), p, Unit.all, /*attack_num*/1 );
                        }

                        use_item.useIn!"BATTLE"(targets);
                        turnEnd();
                    },{

                    }));
                    box.add( createTecBtn(Tec.何もしない) );
                    box.add(new Btn("逃げる",{
                        final switch(type){
                            case Type.NORMAL:
                                Util.msg.set("逃走を試みた..."); cwait;
                                if(uniform(0.0,1.0) <= 0.65){
                                    Util.msg.set("成功"); cwait;
                                    escape();
                                }else{
                                    Util.msg.set("失敗"); cwait;
                                    turnEnd();
                                }
                                break;
                            case Type.BOSS:
                                Util.msg.set("逃げられない！！");
                                break;
                            case Type.EX:
                                escape();
                                break;
                        }
                    },{

                    }));
                    return box;
                }())
            )
        );
    }


    private void win(){
        result = Result.WIN;
        Util.msg.set("勝った", cnt=> Color.CYAN.bright(cnt)); cwait;

        foreach(p; Unit.players){
            if(!p.exists){continue;}

            p.forceBattleEnd();
        }
        {//exp
            double exp = 0;

            foreach(e; Unit.enemies){
                if(!e.exists){continue;}

                exp += e.exp;
            }

            Util.msg.set(format!"%.0fの経験値を入手"(exp), cnt=> Color.SALMON.bright(cnt)); cwait;

            foreach(p; Unit.players){
                if(!p.exists){continue;}

                p.addExp( exp );
            }
        }
        {//jobexp
            int add_job_exp = 1;
            foreach(p; Unit.players){
                if(!p.exists){continue;}

                p.addJobExp( add_job_exp );
            }
        }
        {//yen
            int yen = 0;

            foreach(e; Unit.enemies){
                if(!e.exists){continue;}

                yen += e.yen;
            }

            PlayData.yen += yen;
            Util.msg.set(format!"%s円を入手"(yen), cnt=> Color.YELLOW.bright(cnt)); cwait;
        }
        {//drop_item
            import goods.goods;
            foreach(e; Unit.enemies){
                if(e.existsDropItem()){
                    IGoods drop_item = e.getDropItem();
                    Util.msg.set(format!"%sは[%s]を持っていた"( e.name, drop_item )); cwait;
                    drop_item.add(1); cwait;
                }
            }
        }

        end();
    }

    private void lose(){
        result = Result.LOSE;
        Util.msg.set("負けた...", Color.RED); cwait;

        end();
    }

    private void escape(){
        result = Result.ESCAPE;
        Util.msg.set("逃げた"); cwait;

        end();
    }
}


private class ChooseTarget: Scene{
    mixin ins;

    Unit[] targets;

    private this(){

    }

    Unit[] startChoose(){
        Util.msg.set("＞ターゲットを選択してください");
        setup;
        super.start;
        return targets;
    }

    void setup(){
        clear;

        add((g,bounds){
            Scene.getBefore.draw(g,bounds);
        });

        add((bounds){
            foreach(u; Unit.all){
                if(!u.exists){continue;}
                if(u.bounds.contains( Mouse.point )){
                    Battle.targets = [u];
                    targets = Battle.targets;
                    if(Mouse.left == 1){
                        end;
                    }
                }
            }

            if(Mouse.right == 1){
                Battle.targets = [];
                targets = Battle.targets;
                Util.msg.set("＞キャンセル");
                end;
            }
        });
    }
}


private class TecInfo: InnerLayout{
    mixin MLayout;
    mixin ins;

    Tec tec;
    PUnit user;
    bool visible;

    this(){
        Layout l = new Layout()
                    .add((g,bounds){
                        g.set(Color.BLACK);
                        g.fill(bounds);
                    })
                    .add(new FrameLayout()
                        .add(new Layout()
                            .add((g,bounds){
                                g.set(Color.BLACK);
                                g.fill(bounds);
                            })
                            .add(new YLayout()
                                .add(new Label(Util.font, ()=> format!"[%s]"(tec)))
                                .add(new XLayout()
                                    .add(new Label(Util.font
                                        ,()=> tec.mp_cost > 0 ? format!"MP:%.0f"(tec.mp_cost) : ""
                                        ,()=> tec.mp_cost <= user.mp ? Color.WHITE : Color.RED
                                    ))
                                    .add(new Label(Util.font
                                        ,()=> tec.tp_cost > 0 ? format!"TP:%.0f"(tec.tp_cost) : ""
                                        ,()=> tec.tp_cost <= user.tp ? Color.WHITE : Color.RED
                                    ))
                                    .add(new Label(Util.font
                                        ,()=> tec.getEPCost > 0 ? format!"EP:%.0f"(tec.getEPCost) : ""
                                        ,()=> tec.getEPCost <= user.ep ? Color.WHITE : Color.RED
                                    ))
                                    .add(ILayout.empty)
                                )
                                .add(new Labels(Util.font)
                                    .addln(()=> tec.info)
                                )
                                .add(ILayout.empty)
                                .add(ILayout.empty)
                                .add(ILayout.empty)
                        ))
                    );
        
        add(new VariableLayout({
            if(visible && tec !is null && user !is null){
                visible = false;
                return l;
            }
            return ILayout.empty;
        }));
    }

    void set(Tec tec, PUnit user){
        this.tec = tec;
        this.user = user;
        this.visible = true;
    }
}