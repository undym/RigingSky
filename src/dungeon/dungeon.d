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
    IGoods[] getSpecialDropItems();
    protected void setBossInner();
    protected void setExInner();

    /**
        ダンジョン踏破時の効果。
        初回クリア時なら、clear_num == 1.
    */
    void runClearEvent(const int clear_num){
        
    }

    Event rndEvent(){
        if(uniform(0f,1f) < 0.002){
            return Event.TRESURE;
        }
        if(uniform(0f,1f) < 0.002){
            return Event.EX_BATTLE;
        }
        if(uniform(0f,1f) < 0.2){
            if(getRank() >= 1 && uniform(0f,1f) < 0.08){
                Event[] candidates = [Event.丸い箱];
                return candidates.choice;
            }
            return Event.BOX;
        }
        if(uniform(0f,1f) < 0.2){
            return Event.BATTLE;
        }
        if(uniform(0f,1f) < 0.08){
            return Event.REST;
        }
        if(uniform(0f,1f) < 0.04){
            if(getRank() >= 2 && uniform(0f,1f) < 0.1){return Event.TRAP_LV2;}
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

        IGoods[] special_drop_items = this.getSpecialDropItems();
        if(special_drop_items){
            foreach(i; 0..enemy_num){
                if(uniform(0f,1f) <= 0.1){Unit.enemies[i].setDropItem( special_drop_items.choice );}
            }
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
    @UniqueName(  "はじまりの街")
    static Dungeon はじまりの街(){static Dungeon res; return res !is null ? res : (res = new class Dungeon{
        this(){super(Area.再構成トンネル, /*rank*/0, /*au*/50, FRect(0.35, 0.45, 0.3, 0.1));}
        override bool isVisible()       {return true;}
        override IGoods getTresureKey() {return Item.はじまりの街の財宝の鍵;}
        override Tresure[] getTresures(){return [Tresure(Eq.良い棒, 1)];}
        override IGoods[] getSpecialDropItems(){return [Item.草, Item.枝];}
        override void setBossInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 20;
            }

            EUnit e = Unit.enemies[0];
            e.name = "ボス";
            e.prm!"MAX_HP".base = 40;
        }
        override void setExInner(){
            foreach(e; Unit.enemies){
                e.prm!"MAX_HP".base = 40;
            }

            EUnit e = Unit.enemies[0];
            e.name = "EX";
            e.prm!"MAX_HP".base = 80;
        }
        override void runClearEvent(const int clear_num){
            if(clear_num == 1){
                Util.msg.set("[合成]が解放された！！！"); cwait;
            }
        }
    });}
    //-----------------------------------------------------
    //
    //-----------------------------------------------------
}