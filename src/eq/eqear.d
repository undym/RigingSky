module eq.eqear;

import laziness;
import unit;
import force;
import goods.goods;

/**
    EqEarによる攻撃値の増減は全て乗算・除算にする。
    EqEarによる攻撃倍率の増減は全て乗算・除算にする。
    このカテゴリの装備は全て店で買えるようにする。
*/
abstract class EqEar: IForce, IGoods{
    mixin MForce;
    mixin MGoods;
    mixin Values!EqEarValues;
    mixin Shop;

    enum EAR_NUM = 2;
    //appear_lvがこの値の場合、ランダムな敵には装備されない
    private enum NO_APPEAR_LV = -1;

    static{
        EqEar rndEnemyEar(double lv){
            foreach(i; 0..7){
                EqEar ear = values.choice;
                if(ear.appear_lv <= lv && ear.appear_lv != NO_APPEAR_LV){
                    return ear;
                }
            }
            return EqEar.耳たぶ;
        }
    }

    private string info;
    override string getInfo(){return info;}
    //敵が装備し始めるレベル
    const double appear_lv;

    int num;
    bool got;

    private this(string info, double appear_lv){
        this.info = info;
        this.appear_lv = appear_lv;
    }
    
    Composition getComposition(){return Composition.empty;}
}


private class EqEarValues{
    //------------------------------------------------------------------
    @Value
    static EqEar 耳たぶ(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super(""
            ,/*lv*/0);}
    });}
    @Value
    static EqEar 耳介筋(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super("力+7"
            ,/*lv*/40);}
        override int getPrice(){return 1000;}
        override void equip(Unit u){
            u.prm!"STR".eq += 7;
        }
    });}
    @Value
    static EqEar トンガリ(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super("魔+7"
            ,/*lv*/40);}
        override int getPrice(){return 1000;}
        override void equip(Unit u){
            u.prm!"MAG".eq += 7;
        }
    });}
    @Value
    static EqEar 魔ヶ玉のピアス(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super("ターン開始時MP+5"
            ,/*lv*/30);}
        override int getPrice(){return 2000;}
        override void phaseStart(Unit u){
            u.mp += 5;
        }
    });}
    @Value
    static EqEar 水晶のピアス(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super("戦闘終了時HP+5%"
            ,/*lv*/30);}
        override int getPrice(){return 2000;}
        override void battleEnd(Unit u){
            u.hp += u.prm!"MAX_HP".total * 0.05;
        }
    });}
    @Value
    static EqEar 現し人のピアス(){static EqEar res; return res !is null ? res : (res = new class EqEar{
        this(){super("攻撃回避率+7%"
            ,/*lv*/120);}
        override int getPrice(){return Unit.players[0].prm!"LV".total >= 80 ? 20000 : EqEar.NOT_FOR_SALE;}
        override void beforeBeAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            dmg.hit *= 0.93;
        }
    });}
    
    //------------------------------------------------------------------
}