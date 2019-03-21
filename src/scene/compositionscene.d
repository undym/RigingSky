module scene.compositionscene;

import laziness;
import scene.abstscene;
import widget.btn;
import widget.list;
import goods.goods;

class CompositionScene: AbstScene{
    mixin ins;


    private{
        ILayout main;
    }

    private this(){
        main = ILayout.empty;
    }

    override void start(){

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
                        .add!"top"("-合成-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new BorderLayout()
                .add!("top",0.8)({
                    import widget.groupbtn;
                    GroupBtn gb = GroupBtn.ofY();
                    void addBtn(bool delegate() visible, string name, void delegate() push){
                        import std.string: tr;
                        gb.add(visible() ? name : name.tr(".","？","cd"), {
                            if(!visible()){return;}
                            push();
                        });
                    }
                    gb.add("建築",{
                        BuildingList.ins.setList();
                        main = BuildingList.ins;
                    });
                    addBtn(
                        ()=>false
                        ,"武器"
                        ,{

                        }
                    );
                    addBtn(
                        ()=>false
                        ,"防具"
                        ,{
                            
                        }
                    );
                    addBtn(
                        ()=>false
                        ,"アイテム"
                        ,{
                            
                        }
                    );
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
        
        add(Bounds.Ratio.LIST_MAIN, new VariableLayout({
            return main;
        }));

        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout());

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);

    }

}

private class BuildingList: InnerLayout{
    mixin ins;

    import goods.building;

    Building info;
    List list;

    this(){
        list = new List( Util.list_draw_elm_num );

        add(new BorderLayout()
            .add!("left",0.6)(list)
            .add!("right",0.4)(new VariableLayout({
                static PackedYLayout l;
                static Building info_bak;
                if(l is null){
                    l = new PackedYLayout( Util.font.size );
                    // l.add(new Labels(Util.font)
                    //     .add!"top"(()=> format!"[%s]"(info))
                    //     .add({
                    //         if(info.getComposition().getLimit() == Composition.LIMIT_INF){
                    //             return format!"%s/-"( info.getComposition().exp );
                    //         }else{
                    //             return format!"%s/%s"( info.getComposition().exp, info.getComposition().getLimit() );
                    //         }
                    //     })
                    //     .add(ILayout.empty)
                    //     .addln(()=> info.getInfo())
                    // );
                }
                if(info !is null && info != info_bak){
                    info_bak = info;
                    l.clear;

                    l.add(new Label(Util.font, format!"[%s]"(info)).setDrawPoint!"center");
                    l.add(new Label(Util.font, {
                        if(info.getComposition().getLimit() == Composition.LIMIT_INF){
                            return format!"%s/-"( info.getComposition().exp );
                        }else{
                            return format!"%s/%s"( info.getComposition().exp, info.getComposition().getLimit() );
                        }
                    }));
                    
                    l.add(ILayout.empty);

                    int i;
                    info.getComposition().getMaterials()
                        .each!((mat){
                            int n = i;
                            i++;

                            Color delegate() create_color = ()=> mat.goods.num >= mat.num ? Color.WHITE : Color.L_GRAY;

                            l.add(new XLayout()
                                .add(
                                    new Label(Util.font
                                        ,()=>format!"%s:%s"(n, mat.goods)
                                        ,create_color
                                    ).setDrawPoint!"left"
                                )
                                .add(
                                    new Label(Util.font
                                        ,()=>format!"(%s/%s)"(mat.goods.num, mat.num)
                                        ,create_color
                                    ).setDrawPoint!"right"
                                )
                            );
                        });
                    l.add(ILayout.empty);
                    l.add(new Labels(Util.font)
                        .addln(info.getInfo())
                    );
                }
                return info is null ? ILayout.empty : l;
            }))
        );
    }

    void setList(){
        list.clear;

        list.separater("建築");
        
        Building.values()
            .filter!(b=> b.getComposition().isVisible())
            .each!((b){
                Composition com = b.getComposition();
                list.add( b.toString(), &com.exp,{
                    if(!com.canRun()){return;}
                    com.run();
                },{
                    info = b;
                });
            });
    }
}