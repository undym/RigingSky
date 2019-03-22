module dungeon.dungeon;

import laziness;
import dungeon.area;
import dungeon.event;
import unit;
import job;
import goods.goods;
import eq;
import goods.item;

abstract class Dungeon{
    mixin Values!DungeonValues;

    private struct Tresure{
        IGoods goods;
        float prob;

        this(IGoods goods, float prob){
            this.goods = goods;
            this.prob = prob;
        }
    }

    static{
        Dungeon now;
        int now_au;
        bool escape;
    }

    private Area area;
    Area getArea(){return area;}

    private int rank;
    int getRank(){return rank;}

    private int au;
    int getAU(){return au;}
    const FRect btn_bounds;

    int clear_num;
    int killed_ex_num;
    int opened_tresure_num;

    private this(Area area, int rank, int au, FRect btn_bounds){
        this.area = area;
        this.rank = rank;
        this.au = au;
        this.btn_bounds = btn_bounds;
    }

    bool isVisible();
    IGoods getTresureKey();
    Tresure[] getTresures();
    IGoods[] getTrendItems();
    protected void setBossInner();
    protected void setExInner();

    /**
        ダンジョン踏破時の効果。
        初回クリア時なら、clear_num == 1.
    */
    void runClearEvent(const int clear_num){
        
    }

    Event rndEvent(){
        if(uniform(0.0,1.0) < 0.002){
            return Event.TRESURE;
        }
        if(uniform(0.0,1.0) < 0.002){
            return Event.EX_BATTLE;
        }
        if(uniform(0.0,1.0) < 0.2){
            if(getRank() >= 1 && uniform(0.0,1.0) < 0.08){
                Event[] candidates = [Event.丸い箱];
                return candidates.choice;
            }
            return Event.BOX;
        }
        if(uniform(0.0,1.0) < 0.2){
            return Event.BATTLE;
        }
        if(uniform(0.0,1.0) < 0.08){
            return Event.REST;
        }
        if(uniform(0.0,1.0) < 0.04){
            if(getRank() >= 2 && uniform(0.0,1.0) < 0.1){return Event.TRAP_LV2;}
            return Event.TRAP_LV1;
        }
        return Event.empty;
    }

    void setEnemy(){
        int enemy_num = uniform(1, 2 + getRank);
        enemy_num = enemy_num <= Unit.ENEMY_NUM ? enemy_num : Unit.ENEMY_NUM;
        
        setEnemy( enemy_num );
    }

    void setEnemy(int enemy_num){
        double average_lv = {
            double total_lv = 0;
            int num;
            foreach(p; Unit.players){
                if(!p.exists || p.dead){continue;}

                total_lv += p.prm!"LV".total;
                num++;
            }
            if(num == 0){return 0;}
            return total_lv / num;
        }();


        foreach(i; 0..enemy_num){
            double lv = uniform!"[]"( average_lv * 0.75, average_lv * 1.25 );
            Job job = Job.rndJob( lv );
            job.setEnemy( Unit.enemies[i], lv );
            
        }

        if(this.getTresureKey() != IGoods.empty && uniform(0.0,1.0) <= 0.003){
            Unit.enemies[0].setDropItem( this.getTresureKey() );
        }
    }
    
    void setBoss(){
        setEnemy( Unit.ENEMY_NUM );

        foreach(e; Unit.enemies){
            e.prm!"MAX_HP".base *= 10;
            e.ep = 0;
            e.epCharge = Unit.MAX_EP_CHARGE - 2;
        }

        setBossInner();

        foreach(e; Unit.enemies){
            if(!e.exists || e.dead){continue;}
            e.hp = e.prm!"MAX_HP".total;
            e.forceEquip;
        }
    }

    void setEx(){
        setEnemy( Unit.ENEMY_NUM );

        foreach(e; Unit.enemies){
            e.prm!"MAX_HP".base *= 10;
            e.ep = 0;
            e.epCharge = Unit.MAX_EP_CHARGE - 2;
        }

        setExInner();

        foreach(e; Unit.enemies){
            if(!e.exists || e.dead){continue;}
            e.hp = e.prm!"MAX_HP".total;
            e.forceEquip;
        }
    }
}


private class DungeonValues{
    
    //-----------------------------------------------------
    //
    //-----------------------------------------------------
    @Value
    static Dungeon はじまりの丘(){static Dungeon res; return res !is null ? res : (res = new class Dungeon{
        this(){super(Area.再構成トンネル, /*rank*/0, /*au*/50, FRect(0.35, 0.45, 0.3, 0.1));}
        override bool isVisible()        {return true;}
        override IGoods getTresureKey()  {return Item.はじまりの丘の財宝の鍵;}
        override Tresure[] getTresures() {return [Tresure(Eq.良い棒, 1)];}
        override IGoods[] getTrendItems(){return [Item.草, Item.枝, Item.石, Item.泥];}
        override void setBossInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 20;
            }

            EUnit e = Unit.enemies[0];
            Job.しんまい.setEnemy(e, /*lv*/2);
            e.name = "ボス";
            e.prm!"MAX_HP".base = 40;
        }
        override void setExInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 40;
            }

            EUnit e = Unit.enemies[0];
            Job.魔法使い.setEnemy(e, /*lv*/3);
            e.name = "EX";
            e.prm!"MAX_HP".base = 80;
            e.setDropItem( Eq.盾の盾 );
        }
        override void runClearEvent(const int clear_num){
            if(clear_num == 1){
                Util.msg.set("[合成]が解放された！！！"); cwait;
            }
        }
    });}
    @Value
    static Dungeon 見知らぬ海岸(){static Dungeon res; return res !is null ? res : (res = new class Dungeon{
        this(){super(Area.再構成トンネル, /*rank*/1, /*au*/100, FRect(0.7, 0.1, 0.3, 0.1));}
        override bool isVisible()        {return Dungeon.はじまりの丘.clear_num > 0;}
        override IGoods getTresureKey()  {return Item.見知らぬ海岸の財宝の鍵;}
        override Tresure[] getTresures() {return [Tresure(Eq.布, 1)];}
        override IGoods[] getTrendItems(){return [Item.ピートモス, Item.腐葉土];}
        override void setBossInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 30;
            }

            EUnit e = Unit.enemies[0];
            Job.剣士.setEnemy(e, /*lv*/3);
            e.name = "ボス";
            e.prm!"MAX_HP".base = 45;
        }
        override void setExInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 40;
            }

            EUnit e = Unit.enemies[0];
            Job.魔法使い.setEnemy(e, /*lv*/4);
            e.name = "EX";
            e.prm!"MAX_HP".base = 95;
            e.setDropItem( Eq.魔ヶ玉の手首飾り );
        }
        override void runClearEvent(const int clear_num){}
    });}
    //-----------------------------------------------------
    //
    //-----------------------------------------------------
}