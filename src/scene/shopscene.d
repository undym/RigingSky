module scene.shopscene;

import laziness;
import scene.abstscene;
import unit;
import widget.btn;
import widget.list;
import goods.item;
import eq.eqear;


class ShopScene: AbstScene{
    mixin ins;

    private enum ShopType{
        ITEM,
        EAR,
    }
    
    private List list;
    private Item info_item;
    private EqEar info_ear;
    private ShopType shop_type;

    private this(){
        list = new List( Util.list_draw_elm_num );
    }

    override void start(){


        setup;
        super.start;
    }

    private void setup(){
        clear;
        
        super.addEsc();
        
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT,{
            return new Layout()
                    .add((g,bounds){
                        g.set(Color.L_GRAY);
                        g.line(bounds);
                    })
                    .add(new Labels(Util.font)
                        .setOutsideMargin(2,2,2,2)
                        .add!"top"("-お店-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new BorderLayout()
                .add!("top",0.8)({
                    import widget.groupbtn;
                    import goods.building;
                    GroupBtn gb = GroupBtn.ofY;

                    
                    void add(bool delegate() visible, string name, void delegate() push_action){
                        import std.string: tr;
                        gb.add( 
                            ()=> visible() ? name : name.tr(".","？","cd")
                            ,{
                                if(!visible()){return;}
                                push_action();
                            }
                        )
                        .set!"string"(()=> visible() ? Color.WHITE : Color.GRAY);
                    }

                    gb.add("道具屋",{
                        shop_type = ShopType.ITEM;
                        list.clear;
                        setItemList();
                    });

                    add(()=> Building.耳屋.getComposition().exp > 0
                        ,"耳屋"
                        ,{
                            shop_type = ShopType.EAR;
                            list.clear;
                            setEarList();
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
        add(Bounds.Ratio.LIST_MAIN, new BorderLayout()
            .add!("center",0.55)(list)
            .add!("right",0.45)(new VariableLayout({
                static Labels item;
                static Labels ear;
                static PackedYLayout l;
                if(item is null){
                    item = new Labels(Util.font)
                            .add!"top"(()=> format!"[%s]"(info_item))
                            .add(()=> format!"<%s>"( info_item.type ))
                            .add(()=> format!"Rank:%s"( info_item.rank ))
                            .add(()=> format!"所持:%s個"( info_item.num ))
                            .add(()=> format!"値段:%s円"( info_item.getPrice() ), ()=> info_item.getPrice() <= PlayData.yen ? Color.YELLOW : Color.RED)
                            .br()
                            .addln(()=> info_item.getInfo())
                            ;
                    ear = new Labels(Util.font)
                            .add!"top"(()=> format!"[%s]"(info_ear))
                            .add(()=> format!"所持:%s個"( info_ear.num ))
                            .add(()=> format!"値段:%s円"( info_ear.getPrice() ), ()=> info_ear.getPrice() <= PlayData.yen ? Color.YELLOW : Color.RED)
                            .br()
                            .add(()=> info_ear.getInfo() )
                            ;
                }
                
                if(shop_type == ShopType.ITEM && info_item !is null){return item;}
                if(shop_type == ShopType.EAR  && info_ear !is null) {return ear;}
                return ILayout.empty;
            }))
        );

        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout());

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);

    }

    private void setItemList(){
        list.separater("アイテム");
        
        Item.values
            .filter!(item=> item.getPrice() != Item.NOT_FOR_SALE)
            .each!((item){
                list.add(()=> item.toString(), ()=> format!"%s"(item.num),{
                    if(PlayData.yen >= item.getPrice()){
                        PlayData.yen -= item.getPrice();

                        item.add(1);
                    }
                },{
                    info_item = item;
                });
            });
    }

    private void setEarList(){
        import eq.eqear;
        list.separater("耳");

        EqEar.values()
            .filter!(ear=> ear.getPrice() != EqEar.NOT_FOR_SALE)
            .each!((ear){
                list.add(()=> ear.toString(), ()=> format!"%s"(ear.num),{
                    if(PlayData.yen >= ear.getPrice()){
                        PlayData.yen -= ear.getPrice();

                        ear.add(1);
                    }
                },{
                    info_ear = ear;
                });
            });
    }
}