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

    @Value
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
    @Value
    static Building 着付け教室(){static Building res; return res !is null ? res : (res = new class Building{
        this(){super("装備ができるようになる");}
        override Composition getComposition(){static Composition com; return com !is null ? com : (com = new class Composition{
            this(){super(
                /*result*/IGoods.empty
                ,/*num*/1
                ,/*limit*/1
                ,[
                     Material(Item.泥, 3)
                    ,Material(Item.石, 3)
                ]
            );}
            override bool isVisible(){return Building.瞑想屋.getComposition().exp > 0;}
        });}
    });}
    @Value
    static Building 職業案内所(){static Building res; return res !is null ? res : (res = new class Building{
        this(){super("転職ができるようになる");}
        override Composition getComposition(){static Composition com; return com !is null ? com : (com = new class Composition{
            this(){super(
                /*result*/IGoods.empty
                ,/*num*/1
                ,/*limit*/1
                ,[
                     Material(Item.泥, 4)
                    ,Material(Item.枝, 4)
                ]
            );}
            override bool isVisible(){return Building.着付け教室.getComposition().exp > 0;}
        });}
    });}
    // @Value
    // static Building 耳屋(){static Building res; return res !is null ? res : (res = new class Building{
    //     this(){super("耳を買えるようになる");}
    //     override Composition getComposition(){static Composition com; return com !is null ? com : (com = new class Composition{
    //         this(){super(
    //             /*result*/IGoods.empty
    //             ,/*num*/1
    //             ,/*limit*/1
    //             ,[
    //                  Material(Item.ピートモス, 3)
    //                 ,Material(Item.腐葉土, 3)
    //             ]
    //         );}
    //         override bool isVisible(){return Building.着付け教室.getComposition().exp > 0;}
    //     });}
    // });}
}