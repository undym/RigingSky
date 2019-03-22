module scene.shopscene;

import laziness;
import scene.abstscene;
import unit;
import widget.btn;
import widget.list;
import goods.item;


class ShopScene: AbstScene{
    mixin ins;

    private enum ShopType{
        ITEM,
    }
    
    private List list;
    private Item info_item;
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
                    GroupBtn gb = GroupBtn.ofY;

                    
                    void add(bool delegate() visible, string name, void delegate() push_action){
                        if(visible()){
                            gb.add( name, push_action );
                        }else{
                            import std.string: tr;
                            gb.addDummy( name.tr(".","？","cd") );
                        }
                    }

                    gb.add("道具屋",{
                        shop_type = ShopType.ITEM;
                        list.clear;
                        setItemList();
                    });

                    add(()=>false, "耳屋",{
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
            .add!("center",0.55)(list)
            .add!("right",0.45)(new VariableLayout({
                static Labels item;
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
                }
                // if(info != info_bak){
                //     info_bak = info;
                //     l = new PackedYLayout( Util.FONT_SIZE );
                //     l.add( (new Label(Util.font, format!"[%s]"(info.toString) )).setDrawPoint!"top" );

                // }
                if(shop_type == ShopType.ITEM && info_item !is null){return item;}
                return ILayout.empty;
                // return info is null ? ILayout.empty : l;
            }))
        );

        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout());

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);

    }

    private void setItemList(){
        list.clear;

        list.separater("アイテム");
        
        Item.values
            .filter!(item=> item.getPrice() != Item.NO_SELL)
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
}