module goods.building;

import goods.goods;
import goods.item;
import undym;

abstract class Building{
    mixin Values!BuildingValues;

    private string info;
    string getInfo(){return info;}

    private this(string info){
        this.info = info;
    }

    Composition getComposition();
    

    //----------------------------------------------------------------------------
    //
    //
    //
    //----------------------------------------------------------------------------
}


private class BuildingValues{

    @UniqueName(   "瞑想屋")
    static Building 瞑想屋(){static Building res; return res !is null ? res : (res = new class Building{
        this(){super("瞑想ができるようになる");}
        override Composition getComposition(){static Composition com; return com !is null ? com : (com = new class Composition{
            this(){super(
                /*result*/IGoods.empty
                ,/*num*/1
                ,/*limit*/1
                ,[
                     Material(Item.草, 2)
                    ,Material(Item.枝, 2)
                ]
            );}
            override bool isVisible(){return true;}
            override void runInner(){}
        });}
    });}
}