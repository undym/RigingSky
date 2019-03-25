module eq.eq;

import laziness;
import unit;
import force;
import goods.goods;
import condition;
import goods.item;
/**
    Eqによる攻撃値の増減は、全て加算・減算にする。
    Eqによる攻撃倍率の増減は、全て加算・減算にする。
*/
abstract class Eq: IForce, IGoods{
    mixin MForce;
    mixin MGoods;
    mixin Values!EqValues;

    enum Pos{
        頭,
        剣,
        盾,
        体,
        腰,
        腕,
        指,
        脚,
    }
    /**このレベルが設定されたものはランダムに敵が装備しない。*/
    enum NO_APPEAR_LV = -1;

    static{
        private Eq[][Pos] pos_values;

        Eq[] getPosValues(Pos pos){
            values();
            return pos in pos_values ? pos_values[pos] : [];
        }

        Eq getDefEq(Pos pos){
            final switch(pos){
                case Pos.頭: return Eq.髪;
                case Pos.剣: return Eq.棒;
                case Pos.盾: return Eq.親指;
                case Pos.体: return Eq.襤褸切れ;
                case Pos.腰: return Eq.ひも;
                case Pos.腕: return Eq.リスト;
                case Pos.指: return Eq.肩身の指輪;
                case Pos.脚: return Eq.靴;
            }
        }

        Eq rndEnemyEq(Pos pos, double lv){
            if(getPosValues(pos).length == 0){return getDefEq(pos);}

            foreach(i; 0..7){
                Eq eq = pos_values[pos].choice;
                if(eq.appear_lv <= lv && eq.appear_lv != NO_APPEAR_LV){
                    return eq;
                }
            }

            return getDefEq(pos);
        }
    }

    private string info;
    override string getInfo(){return info;}
    const Pos pos;
    //敵が装備し始めるレベル
    const double appear_lv;

    private this(string info, Pos pos, double appear_lv){
        this.info = info;
        this.pos = pos;
        this.appear_lv = appear_lv;

        pos_values[pos] ~= this;
    }

    Composition getComposition(){return Composition.empty;}

}

private class EqValues{
    //------------------------------------------------------------------
    //
    //頭
    //
    //------------------------------------------------------------------
    @Value
    static Eq 髪(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.頭, /*lv*/0);}
    });}
    @Value
    static Eq クロワッサン(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("最大HP+50"
            ,Pos.頭, /*lv*/50);}
        override Composition getComposition(){static Composition com; return com !is null ? com : (com = new class Composition{
            this(){super(
                /*result*/Eq.クロワッサン
                ,/*num*/1
                ,/*limit*/Composition.LIMIT_INF
                ,[   
                     Material(Item.草, 5)
                    ,Material(Item.石, 5)
                    ,Material(Item.泥, 5)
                ]
            );}
            override bool isVisible(){return true;}
        });}
        override void equip(Unit u){
            u.prm!"MAX_HP".eq += 50;
        }
    });}
    //------------------------------------------------------------------
    //
    //剣
    //
    //------------------------------------------------------------------
    @Value
    static Eq 棒(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.剣, /*lv*/0);}
    });}
    @Value //はじまりの丘・財宝
    static Eq 良い棒(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("全ステータス+10"
            ,Pos.剣, /*lv*/20);}
        override void equip(Unit u){
            double v = 10;
            u.prm!"STR".eq += v; u.prm!"MAG".eq += v;
            u.prm!"LIG".eq += v; u.prm!"DRK".eq += v;
            u.prm!"CHN".eq += v; u.prm!"PST".eq += v;
            u.prm!"GUN".eq += v; u.prm!"ARR".eq += v;
        }
    });}
    //------------------------------------------------------------------
    //
    //盾
    //
    //------------------------------------------------------------------
    @Value
    static Eq 親指(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.盾, /*lv*/0);}
    });}
    @Value //はじまりの丘・EX
    static Eq 盾の盾(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("戦闘開始時＜盾＞化"
            ,Pos.盾, /*lv*/30);}
        override void battleStart(Unit u){
            if(u.getCondition!"GOOD_LV2" == Condition.empty){
                u.setCondition(Condition.盾, 1);
            }
        }
    });}
    //------------------------------------------------------------------
    //
    //体
    //
    //------------------------------------------------------------------
    @Value
    static Eq 襤褸切れ(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.体, /*lv*/0);}
    });}
    @Value //見知らぬ海岸・財宝
    static Eq 布(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("最大HP+50"
            ,Pos.体, /*lv*/30);}
        override void equip(Unit u){
            u.prm!"MAX_HP".eq += 50;
        }
    });}
    @Value
    static Eq 毛皮(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("最大HP+10%"
            ,Pos.体, /*lv*/30);}
        override void equip(Unit u){
            u.prm!"MAX_HP".eq += u.prm!"MAX_HP".base / 10;
        }
    });}
    //------------------------------------------------------------------
    //
    //腰
    //
    //------------------------------------------------------------------
    @Value
    static Eq ひも(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.腰, /*lv*/0);}
    });}
    @Value //はじまりの丘　クリア
    static Eq おめでとうのひも(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("戦闘開始時最大HP・現在HP+10%"
            ,Pos.腰, /*lv*/40);}
        override void battleStart(Unit u){
            double value = u.prm!"MAX_HP".base / 10;
            u.prm!"MAX_HP".battle += value;
            u.hp += value;
            u.fixPrm;
        }
    });}
    @Value
    static Eq 黒帯(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("格闘を受けた時、格闘攻撃で反撃する"
            ,Pos.腰, /*lv*/80);}
        override void afterBeAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(dmg.counter){return;}
            if(tec.isType!"格闘"){
                Util.msg.set("＞反撃"); cwait;
                Tec.格闘カウンター.run( target, attacker );
            }
        }
    });}
    //------------------------------------------------------------------
    //
    //腕
    //
    //------------------------------------------------------------------
    @Value
    static Eq リスト(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.腕, /*lv*/0);}
    });}
    @Value //見知らぬ海岸・EX
    static Eq 魔ヶ玉の手首飾り(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("毎ターンMP+10"
            ,Pos.腕, /*lv*/10);}
    });}
    //------------------------------------------------------------------
    //
    //指
    //
    //------------------------------------------------------------------
    @Value
    static Eq 肩身の指輪(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.指, /*lv*/0);}
    });}
    @Value //見知らぬ海岸　クリア
    static Eq ドリー(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("魔+10"
            ,Pos.指, /*lv*/30);}
        override void equip(Unit u){
            u.prm!"MAG".eq += 10;
        }
    });}
    //------------------------------------------------------------------
    //
    //脚
    //
    //------------------------------------------------------------------
    @Value
    static Eq 靴(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super(""
            ,Pos.脚, /*lv*/0);}
    });}
    @Value
    static Eq ルクシオンの尾(){static Eq res; return res !is null ? res : (res = new class Eq{
        this(){super("進む時、HP+1%"
            ,Pos.脚, /*lv*/0);}
        override void walk(Unit u, int* add_au){
            if(u.dead){return;}
            if(*add_au > 0){
                u.hp += u.prm!"MAX_HP".total / 100 + 1;
                u.fixPrm;
            }
        }
    });}
    //------------------------------------------------------------------
}