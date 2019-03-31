module condition.condition;

import laziness;
import force;
import unit;
import tec;

/*
    Conditionによる攻撃値の増減は、全て乗算・除算にする。
    Conditionによる攻撃倍率の増減は、全て乗算・除算にする。
*/
abstract class Condition: IForce{
    mixin Values!ConditionValues;
    mixin MForce;

    enum Type{
        GOOD_LV1,
        GOOD_LV2,
        GOOD_LV3,
        BAD_LV1,
        BAD_LV2,
        BAD_LV3,
    }

    const string info;
    const Type type;
    const int max_value;

    private this(string info, Type type, int max_value){
        this.info = info;
        this.type = type;
        this.max_value = max_value;
    }
}


private class ConditionValues{
    //------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------
    @Value
    static Condition empty(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("", Type.GOOD_LV1, /*max*/1);}
        override string toString(){return "";}
    });}
    //------------------------------------------------------------------------
    //
    //GOOD_LV1
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 練(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("格闘・神格・練術・銃術攻撃威力上昇", Type.GOOD_LV1, /*max*/4);}
        override void beforeDoAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!("格闘","神格","練術","銃術")){
                int value = attacker.getConditionValue(this.type);
                dmg.mul *= (1.5 * value);

                attacker.addCondition(this, -1);

                Util.msg.set(format!"＞練%s"(value));
            }
        }
    });}
    //------------------------------------------------------------------------
    //
    //GOOD_LV2
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 盾(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("被格闘・神格・練術・銃術攻撃威力減少", Type.GOOD_LV2, /*max*/4);}
        override void beforeBeAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!("格闘","神格","練術","銃術")){
                int value = target.getConditionValue(this.type);
                dmg.mul /= (1.5 * value);

                target.addCondition(this, -1);

                Util.msg.set(format!"＞盾%s"(value));
            }
        }
    });}
    //------------------------------------------------------------------------
    //
    //GOOD_LV3
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 癒(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("毎ターンの開始時にHPを20%回復", Type.GOOD_LV3, /*max*/20);}
        override void phaseStart(Unit u){
            double value = u.prm!"MAX_HP".total * 0.2;
            u.hp += value;
            u.fixPrm;

            // void flipStr(string s, const FPoint center, Color color, Font font, int over = 50) {
            import effect: Effect;
            Effect.flipStr( format!"%.0f"(value),
                u.bounds.center.move( uniform!"[]"(-20,20), uniform!"[]"(-20,20) ).to!float,
                Color.GREEN );
            Effect.回復( u.bounds );

            u.addCondition(this, -1);
        }
    });}
    //------------------------------------------------------------------------
    //
    //BAD_LV1
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 攻撃低下(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("攻撃倍率減少", Type.BAD_LV1, /*max*/6);}
        override void beforeDoAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!("格闘","魔法",
                            "神格","練術",
                            "練術","過去",
                            "銃術","弓術",
            )){
                dmg.mul *= 0.5;

                attacker.addCondition(this, -1);

                Util.msg.set("＞攻↓");
            }
        }
        override string toString(){return "攻↓";}
    });}
    //------------------------------------------------------------------------
    //
    //BAD_LV2
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 防御低下(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("被攻撃倍率増加", Type.BAD_LV2, /*max*/6);}
        override void beforeBeAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!("格闘","魔法",
                            "神格","練術",
                            "練術","過去",
                            "銃術","弓術",
            )){
                dmg.mul *= 2;

                target.addCondition(this, -1);

                Util.msg.set("＞防↓");
            }
        }
        override string toString(){return "防↓";}
    });}
    //------------------------------------------------------------------------
    //
    //BAD_LV3
    //
    //------------------------------------------------------------------------
    @Value
    static Condition 焔(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("毎ターン開始時、最大・現HP-5%", Type.BAD_LV3, /*max*/20);}
        override void phaseStart(Unit u){
            double value = u.prm!"MAX_HP".total * 0.05;
            u.prm!"MAX_HP".battle -= value;
            u.hp -= u.prm!"MAX_HP".total * 0.05;
            u.fixPrm;

            // void flipStr(string s, const FPoint center, Color color, Font font, int over = 50) {
            import effect: Effect;
            Effect.flipStr( format!"最大HP-%.0f"(value),
                u.bounds.center.move( uniform!"[]"(-20,20), uniform!"[]"(-20,20) ).to!float,
                Color.WHITE );
            Util.msg.set("＞焔", cnt=> Color.RED.bright(cnt));

            u.addCondition(this, -1);
        }
    });}
    //このConditionはBattleSceneで効果を設定している.
    @Value
    static Condition 眠(){static Condition res; return res !is null ? res : (res = new class Condition{
        this(){super("行動不能", Type.BAD_LV3, /*max*/4);}
    });}
    //------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------
}