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
    //------------------------------------------------------------------
}