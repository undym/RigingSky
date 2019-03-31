module scene.itemscene;

import laziness;
import scene.abstscene;
import widget.btn;
import widget.list;
import item;
import unit;

private alias ParentType = Item.ParentType;
private alias Type = Item.Type;


class ItemScene: AbstScene{
    mixin ins;

    enum Type{
        FIELD,
        DUNGEON,
        BATTLE,
    }

    protected{
        List list;
        Item info;
        Unit user;
        Item choosed_item_in_battle;
    }

    Type type;
    bool big_list = true;
    int pushed_type_btn_index;

    protected this(){
        list = new List;
    }

    void startInField(){
        type = Type.FIELD;

        foreach(u; Unit.players){
            if(u.exists && !u.dead){
                user = u;
                break;
            }
        }

        start();
    }

    void startInDungeon(){
        type = Type.DUNGEON;
        
        foreach(u; Unit.players){
            if(u.exists && !u.dead){
                user = u;
                break;
            }
        }

        start();
    }

    Item startInBattle(Unit user){
        type = Type.BATTLE;

        this.user = user;
        choosed_item_in_battle = null;

        start();
        return choosed_item_in_battle;
    }

    override protected void start(){
        pushed_type_btn_index = 0;
        setup();
        super.start;
    }

    override void cwait(){}

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
                        .add!"top"("-アイテム-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new BorderLayout()
                .add!("top",0.8)({
                    import std.traits: EnumMembers;
                    import widget.groupbtn;
                    GroupBtn gb = GroupBtn.ofY;

                    struct BtnType{
                        string name;
                        void delegate() action;
                    }

                    BtnType[] btn_types;
                        [EnumMembers!ParentType].each!((p){
                            int index = btn_types.length;
                            BtnType type = {
                                 format!"%s"(p)//name
                                ,{//action
                                    list.clear;
                                    setList(p);

                                    pushed_type_btn_index = index;
                                }
                            };

                            btn_types ~= type;
                        });

                    btn_types.each!((b){
                        gb.add( b.name, {
                            b.action();
                        });
                    });

                    gb.push( pushed_type_btn_index );

                    return gb;
                }())
                .add!"center"(
                    new Btn("＞戻る",{
                        end();
                    })
                )
            )
        );

        FRect main_ratio = big_list ? Bounds.Ratio.LIST_MAIN : Bounds.Ratio.MAIN;
        add(main_ratio, new BorderLayout()
            .add!("center",0.6)(list)
            .add!("right",0.4)(new VariableLayout({
                static Layout l;
                if(l is null){
                    l = new Layout();
                    l.add(new Labels(Util.font)
                        .add!"top"(()=> format!"[%s]"(info))
                        .add(()=> format!"<%s>"( info.type ))
                        .add(()=> format!"Rank:%s"( info.rank ))
                        .add(()=> format!"所持:%s個"( info.num ))
                        .br()
                        .addln(()=> info.getInfo())
                    );
                }
                return info is null ? ILayout.empty : l;
            }))
        );

        if(big_list){
            list.one_page_elm_num = Util.list_draw_elm_num;

            add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout()
                .add(ILayout.create((bounds){
                    if(bounds.contains( Mouse.point ) && Mouse.left == 1){
                        big_list = false;
                        setup();
                    }
                }))
            );
        }else{
            list.one_page_elm_num = cast(int)(cast(float)Util.list_draw_elm_num * Bounds.Ratio.MAIN.h / Bounds.Ratio.LIST_MAIN.h);

            add(Bounds.Ratio.ENEMY_STATUS_BOXES, new Layout()
                .add((bounds){
                    if(bounds.contains( Mouse.point ) && Mouse.left == 1){
                        big_list = true;
                        setup();
                    }
                })
                .add(DrawEnemyStatusBoxes.ins)
            );
        }


        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(g,bounds)=> drawChoosedUnitFrame(g,user));
        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);
        add((g,bounds){
            DrawUnitDetail.set( user );
        });

        if(type == Type.FIELD || type == Type.DUNGEON){
            add(Bounds.Ratio.PLAYER_STATUS_BOXES,(bounds){
                if(Mouse.left != 1){return;}
                    
                foreach(u; Unit.players){
                    if(!u.exists || u.dead){continue;}

                    if(u.bounds.contains( Mouse.point )){
                        user = u;
                        break;
                    }
                }
            });

        }
    }

    protected void setList(ParentType parent){
        foreach(type; parent){
            
            list.separater(format!"%s"(type));

            Item.getTypeValues(type)
                .filter!(item=> item.num > 0)
                .each!((item){
                    auto elm = list.add( item.toString, item.numPtr(), {
                        if(item.num <= 0){
                            Util.msg.set("所持数0");
                            return;
                        }
                        
                        pushItemList(item);
                    },{
                        info = item;
                    });

                    elm.set!"string"(()=> item.num > 0 ? Color.WHITE : Color.GRAY);
                    elm.set!"num"(()=> item.num > 0 ? Color.WHITE : Color.GRAY);
                });
        }
    }

    private void pushItemList(Item item){
        final switch(type){
            case Type.FIELD:
                if(!item.canUseIn!"FIELD"){return;}

                import force;
                Unit[] targets;
                if(item.getTargeting() & Targeting.SELECT){
                    targets = [user];
                }else{
                    targets = getTargets( item.getTargeting(), user, cast(Unit[])Unit.players, 1 );
                }

                item.useIn!"FIELD"( targets );
                break;
            case Type.DUNGEON:
                if(!item.canUseIn!"DUNGEON"){return;}

                import force;
                Unit[] targets;
                if(item.getTargeting() & Targeting.SELECT){
                    targets = [user];
                }else{
                    targets = getTargets( item.getTargeting(), user, cast(Unit[])Unit.players, 1 );
                }

                item.useIn!"DUNGEON"( targets );
                break;
            case Type.BATTLE:
                if(!item.canUseIn!"BATTLE"){return;}

                choosed_item_in_battle = item;
                end();
                break;
        }
    }
}





// class ItemSceneField: ItemSceneAbst{
//     mixin ins;

//     override void start(){
        

//         super.start;
//     }

//     override protected void pushItemList(Item item){
//         if(!item.canUseIn!"FIELD"){return;}

//         import force;
//         Unit[] targets;
//         if(item.getTargeting() & Targeting.SELECT){
//             targets = [user];
//         }else{
//             targets = getTargets( item.getTargeting(), user, cast(Unit[])Unit.players, 1 );
//         }

//         item.useIn!"FIELD"( targets );
//     }

//     override protected void setup(){
//         super.setup;

//         add(Bounds.Ratio.PLAYER_STATUS_BOXES,(bounds){
//             if(Mouse.left != 1){return;}
                
//             foreach(u; Unit.players){
//                 if(!u.exists || u.dead){continue;}

//                 if(u.bounds.contains( Mouse.point )){
//                     user = u;
//                     break;
//                 }
//             }
//         });
//     }
// }



// class ItemSceneDungeon: ItemSceneAbst{
//     mixin ins;

//     override void start(){
        
//         foreach(u; Unit.players){
//             if(u.exists && !u.dead){
//                 user = u;
//                 break;
//             }
//         }

//         super.start;
//     }

//     override protected void pushItemList(Item item){
//         if(!item.canUseIn!"DUNGEON"){return;}

//         import force;
//         Unit[] targets;
//         if(item.getTargeting() & Targeting.SELECT){
//             targets = [user];
//         }else{
//             targets = getTargets( item.getTargeting(), user, cast(Unit[])Unit.players, 1 );
//         }

//         item.useIn!"DUNGEON"( targets );
//     }

//     override protected void setup(){
//         super.setup;

//         add(Bounds.Ratio.PLAYER_STATUS_BOXES,(bounds){
//             if(Mouse.left != 1){return;}
                
//             foreach(u; Unit.players){
//                 if(!u.exists || u.dead){continue;}

//                 if(u.bounds.contains( Mouse.point )){
//                     user = u;
//                     break;
//                 }
//             }
//         });
//     }
// }



// class ItemSceneBattle: ItemSceneAbst{
//     mixin ins;

//     private Item choosed_item;

//     /**nullable*/
//     Item startChoose(Unit user){
//         this.user = user;

//         choosed_item = null;

//         super.start;

//         return choosed_item;
//     }

//     override protected void pushItemList(Item item){
//         if(!item.canUseIn!"BATTLE"){return;}

//         choosed_item = item;
//         end;
//     }
// }
