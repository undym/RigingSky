module tec;

import laziness;
import unit;
import force;
import condition;
import effect;

/**
    passive技による攻撃値の増減は、全て加算・減算にする。
    passive技による攻撃倍率の増減は、全て加算・減算にする。
*/
class Tec: IForce{
    mixin MForce;
    mixin Values!TecValues;
    
    enum Type{
        格闘,
        魔法,
        神格,
        暗黒,
        練術,
        過去,
        銃術,
        弓術,
        回復,
        状態,
        その他,
    }

    static{
        private Tec[][Type] type_values;
        Tec[] getTypeValues(Type type){
            static bool init;
            if(!init){
                init = true;
                import std.traits: EnumMembers;
                foreach(tec; Tec.values){
                    type_values[ tec.type ] ~= tec;
                }
            }

            return type in type_values ? type_values[type] : [];
        }
    }

    const string info;
    const Type type;
    bool isType(T...)(){
        static foreach(type_name; T){
            if(type == mixin("Type."~type_name)){
                return true;
            }
        }
        return false;
    }

    const Targeting targetings;
    const double mp_cost;
    const double tp_cost;
    private double ep_cost = 0;
    double getEPCost(){return ep_cost;}

    private int delegate() attack_num;
    int rndAttackNum(){return attack_num();}

    const double mul;
    const double hit;

    const bool passive;

    private this(string info, Type type, Targeting targetings, double mp_cost, double tp_cost, int delegate() attack_num, double mul, double hit){
        this.info = info;
        this.type = type;
        this.targetings = targetings;
        this.mp_cost = mp_cost;
        this.tp_cost = tp_cost;
        this.attack_num = attack_num;
        this.mul = mul;
        this.hit = hit;

        this.passive = false;
    }

    private this(string info, Type type){
        this.info = info;
        this.type = type;
        this.targetings = Targeting.SELF;
        this.mp_cost = 0;
        this.tp_cost = 0;
        this.attack_num = ()=>1;
        this.mul = 1;
        this.hit = 1;

        this.passive = true;
    }

    bool checkCost(Unit u){
        return (u.mp >= mp_cost && u.tp >= tp_cost && u.ep >= getEPCost);
    }

    void payCost(Unit u){
        u.mp -= mp_cost;
        u.tp -= tp_cost;
        u.ep -= getEPCost;
    }

    void use(Unit attacker, Unit[] targets){
        Battle.attackers = [attacker];

        Util.msg.set( format!"%sの[%s]"( attacker.name, this ), Color.GREEN ); cwait;

        if(!checkCost( attacker )){
            Util.msg.set("コストを支払えなかった...", Color.RED); cwait;
            return;
        }else{
            payCost( attacker );
        }


        Battle.targets = targets;

        foreach(t; targets){
            run( attacker, t );
        }
    }

    void run(Unit attacker, Unit target){
        Dmg dmg = createDmg( attacker, target );

        attacker.forceBeforeDoAtk( this, target, dmg );
        target.forceBeforeBeAtk( this, attacker, dmg );

        runInner( attacker, target, dmg );
        
        attacker.forceAfterDoAtk( this, target, dmg );
        target.forceAfterBeAtk( this, attacker, dmg );
    }

    void runInner(Unit attacker, Unit target, Dmg dmg){
        effect( attacker, target );
        doTecDmg( target, dmg.calc );
    }

    Dmg createDmg(Unit attacker, Unit target){
        Dmg dmg = createTypeDmg( this.type, attacker, target );
        dmg.mul = mul;
        dmg.hit = hit;
        return dmg;
    }

    void effect(Unit attacker, Unit target){
        typeEffect( this.type, attacker, target );
    }

    override string toString(){
        return passive ? "-"~getUniqueName()~"-" : getUniqueName();
    }
}

/**
    内部でtarget.doDmg(value)を呼び出す。
    被攻撃時のTP増加処理のためこの関数を介する。
*/
private void doTecDmg(Unit target, double value){
    target.doDmg( value );

    target.tp += 5;
    target.fixPrm;
}


private void heal(Unit target, double value){
    if(target.dead){return;}

    target.hp += value;
    target.fixPrm;
    
    import effect: Effect;
    Effect.flipStr( format!"%.0f"(value), target.rndCenter, Color.GREEN );
}


private void revive(Unit target, double hp){
    if(!target.dead){return;}

    target.dead = false;
    target.hp = hp;
    target.fixPrm;

    import effect: Effect;
    Effect.flipStr( format!"%.0f"(hp), target.rndCenter, Color.GREEN );
}


private void selfHarm(Unit target, double value){
    Util.msg.set("＞自傷", cnt=>Color.RED.bright(cnt));
    target.doDmg(value);
}

private Dmg createTypeDmg(Tec.Type type, Unit attacker, Unit target){
    alias Type = Tec.Type;

    Dmg dmg = new Dmg;

    final switch(type){
        case Type.格闘:
            dmg.pow = attacker.prm!"STR".total;
            dmg.def = target.prm!"MAG".total;
            return dmg;
        case Type.魔法:
            dmg.pow = attacker.prm!"MAG".total;
            dmg.def = target.prm!"STR".total;
            return dmg;
        case Type.神格:
            dmg.pow = attacker.prm!"LIG".total;
            dmg.def = target.prm!"DRK".total;
            return dmg;
        case Type.暗黒:
            dmg.pow = attacker.prm!"DRK".total;
            dmg.def = target.prm!"LIG".total;
            return dmg;
        case Type.練術:
            dmg.pow = attacker.prm!"CHN".total;
            dmg.def = target.prm!"PST".total;
            return dmg;
        case Type.過去:
            dmg.pow = attacker.prm!"PST".total;
            dmg.def = target.prm!"CHN".total;
            return dmg;
        case Type.銃術:
            dmg.pow = attacker.prm!"GUN".total;
            dmg.def = target.prm!"ARR".total;
            return dmg;
        case Type.弓術:
            dmg.pow = attacker.prm!"ARR".total;
            dmg.def = target.prm!"GUN".total;
            return dmg;
        case Type.回復:
            dmg.pow = attacker.prm!"LIG".total;
            return dmg;
        case Type.状態:
            return dmg;
        case Type.その他:
            return dmg;
    }
}

private void typeEffect(Tec.Type type, Unit attacker, Unit target){
    alias Type = Tec.Type;
    final switch(type){
        case Type.格闘:
            Effect.atk( target.center, Color.RED );
            break;
        case Type.魔法:
            Effect.魔法( target.center );
            break;
        case Type.神格:
            Effect.神格( target.center );
            break;
        case Type.暗黒:
            Effect.通常攻撃( target.center, Color.GRAY );
            break;
        case Type.練術:
            Effect.練術( attacker.center, target.center );
            break;
        case Type.過去:
            Effect.atk( target.center, Color.RED );
            break;
        case Type.銃術:
            Effect.atk( target.center, Color.RED );
            break;
        case Type.弓術:
            Effect.atk( target.center, Color.RED );
            break;
        case Type.回復:
            Effect.回復( target.center );
            break;
        case Type.状態:
            Effect.atk( target.center, Color.RED );
            break;
        case Type.その他:
            Effect.atk( target.center, Color.RED );
            break;
    }
}



private class TecValues{

    //----------------------------------------------------------------
    //
    //----------------------------------------------------------------
    @Value
    static Tec empty(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("empty.info"
            ,Type.格闘, Targeting.SELECT
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
        override string toString(){return "";}
    });}
    //------------------------------------------------------------------
    //
    //格闘
    //
    //------------------------------------------------------------------
    @Value
    static Tec 殴る(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に格闘攻撃"
            ,Type.格闘, Targeting.SELECT
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            dmg.pow += uniform!"[]"(1,3);
            super.runInner(attacker, target, dmg);
        }
    });}
    @Value
    static Tec 二刀(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に2回格闘攻撃"
            ,Type.格闘, Targeting.SELECT 
            ,/*mp*/0, /*tp*/20, /*num*/()=>2, /*mul*/1.0, /*hit*/1.0);}
    });}
    @Value
    static Tec 静かなる動き(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に格闘攻撃x3"
            ,Type.格闘, Targeting.SELECT 
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/3, /*hit*/1.0);
            ep_cost = 1;
        }
        override Dmg createDmg(Unit attacker, Unit target){
            Dmg dmg = super.createDmg( attacker, target );
            dmg.pow = target.prm!"STR".total / 2;
            dmg.abs = target.prm!"STR".total / 2;
            return dmg;
        }
    });}
    @Value
    static Tec タックル(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に格闘攻撃x1.2、相手を＜防↓＞化"
            ,Type.格闘, Targeting.SELECT
            ,/*mp*/0, /*tp*/30, /*num*/()=>1, /*mul*/1.2, /*hit*/1.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            super.runInner(attacker, target, dmg);

            target.addCondition( Condition.防御低下, 2 );
        }
    });}
    //------------------------------------------------------------------
    @Value
    static Tec 格闘攻撃UP(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("格闘攻撃+30%"
            ,Type.格闘);}
        override void beforeDoAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!"格闘"){
                dmg.mul += 0.3;
            }
        }
    });}
    //------------------------------------------------------------------
    //
    //魔法
    //
    //------------------------------------------------------------------
    @Value
    static Tec ヴァハ(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に魔法攻撃"
            ,Type.魔法, Targeting.SELECT
            ,/*mp*/10, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
    });}
    @Value
    static Tec エヴィン(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に魔法攻撃x1.5"
            ,Type.魔法, Targeting.SELECT
            ,/*mp*/20, /*tp*/0, /*num*/()=>1, /*mul*/1.5, /*hit*/1.0);}
    });}
    //------------------------------------------------------------------
    @Value
    static Tec 魔法攻撃UP(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("魔法攻撃+30%"
            ,Type.魔法);}
        override void beforeDoAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!"魔法"){
                dmg.mul += 0.3;
            }
        }
    });}
    //------------------------------------------------------------------
    //
    //神格
    //
    //------------------------------------------------------------------
    @Value
    static Tec 天籟(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に神格攻撃"
            ,Type.神格, Targeting.SELECT
            ,/*mp*/0, /*tp*/10, /*num*/()=>1, /*mul*/1.0, /*hit*/1.3);}
    });}
    //------------------------------------------------------------------
    //
    //暗黒
    //
    //------------------------------------------------------------------
    @Value
    static Tec 暗黒剣(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に暗黒攻撃x1.5 HP-10%"
            ,Type.暗黒, Targeting.SELECT
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.5, /*hit*/1.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            super.runInner(attacker, target, dmg);

            Effect.通常攻撃( attacker.center, Color.RED );
            selfHarm( attacker, attacker.prm!"MAX_HP".total / 10 );
        }
    });}
    @Value
    static Tec 吸血(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("[自分・闇]-[相手・光]分のHPを吸収"
            ,Type.暗黒, Targeting.SELECT
            ,/*mp*/20, /*tp*/20, /*num*/()=>1, /*mul*/1.0, /*hit*/9.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            double value = attacker.prm!"DRK".total - target.prm!"LIG".total;
            if(value < 0){value = 0;}
            
            effect( attacker, target );
            target.doDmg( value );

            Effect.回復( attacker.center );
            heal( attacker, value );
        }
    });}
    @Value
    static Tec VampireBloodyStar(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("敵全体に吸血"
            ,Type.暗黒, Targeting.ALL
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/9.0);
            ep_cost = 1;
        }
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            Tec.吸血.runInner( attacker, target, dmg );
        }
    });}
    @Value
    static Tec 宵闇(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("暗黒攻撃x2"
            ,Type.暗黒);}
        override void beforeDoAtk(Tec tec, Unit attacker, Unit target, Dmg dmg){
            if(tec.isType!"暗黒"){
                dmg.mul += 1;
            }
        }
    });}
    //------------------------------------------------------------------
    //
    //練術
    //
    //------------------------------------------------------------------
    @Value
    static Tec スネイク(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("敵全体に練術攻撃"
            ,Type.練術, Targeting.ALL
            ,/*mp*/0, /*tp*/15, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
    });}
    //------------------------------------------------------------------
    //
    //過去
    //
    //------------------------------------------------------------------
    @Value
    static Tec 念(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体に過去攻撃"
            ,Type.過去, Targeting.SELECT
            ,/*mp*/10, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.2);}
    });}
    @Value
    static Tec 念力(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("敵全体に過去攻撃"
            ,Type.過去, Targeting.ALL
            ,/*mp*/40, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.2);}
    });}
    //------------------------------------------------------------------
    //
    //回復
    //
    //------------------------------------------------------------------
    @Value
    static Tec 数珠(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("一体を光依存で回復x2"
            ,Type.回復, Targeting.SELECT | Targeting.ONLY_FRIEND
            ,/*mp*/10, /*tp*/0, /*num*/()=>1, /*mul*/2.0, /*hit*/2.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            effect( attacker, target );
            heal( target, dmg.calc );
        }
    });}
    @Value
    static Tec 良き占い(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("味方全体を光依存で回復"
            ,Type.回復, Targeting.ALL | Targeting.ONLY_FRIEND
            ,/*mp*/40, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/2.0);}
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            effect( attacker, target );
            heal( target, dmg.calc );
        }
    });}
    @Value
    static Tec ユグドラシル(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("味方全体を復活・全回復"
            ,Type.回復, Targeting.ALL | Targeting.ONLY_FRIEND
            ,/*mp*/40, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/2.0);}
        override void effect(Unit attacker, Unit target){
            Effect.復活( target.center.to!float );
        }
        override void runInner(Unit attacker, Unit target, Dmg dmg){
            effect( attacker, target );
            revive( target, target.prm!"MAX_HP".total );
        }
    });}
    @Value
    static Tec HP自動回復(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("毎ターンHP+1%"
            ,Type.回復);}
        override void phaseStart(Unit u){
            u.hp += u.prm!"MAX_HP".total / 100 + 1;
            u.fixPrm;
        }
    });}
    //------------------------------------------------------------------
    //
    //状態
    //
    //------------------------------------------------------------------
    @Value
    static Tec 練気(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("自分を＜練＞(格闘・暗黒・練術・銃術攻撃x1.5)化"
            ,Type.状態, Targeting.SELF
            ,/*mp*/0, /*tp*/10, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
        override void run(Unit attacker, Unit target){
            target.addCondition( Condition.練, 1 );

            Util.msg.set( format!"%sは＜練%s＞になった"( target.name, target.getConditionValue(Condition.練.type ) ) ); cwait;
        }
    });}
    //------------------------------------------------------------------
    //
    //その他
    //
    //------------------------------------------------------------------
    @Value
    static Tec 何もしない(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("なーんにもしない"
            ,Type.その他, Targeting.SELF
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
        override void run(Unit attacker, Unit target){
            Util.msg.set(attacker.name~"は空を眺めている..."); cwait;
        }
    });}
    //------------------------------------------------------------------
    @Value
    static Tec 体力回路(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("戦闘開始時、最大HP・現在HP+10%"
            ,Type.その他);}
        override void battleStart(Unit u){
            double value = u.prm!"MAX_HP".total / 10;
            u.prm!"MAX_HP".battle += value;
            u.hp += value;
            u.fixPrm;
        }
    });}
    //------------------------------------------------------------------
    @Value
    static Tec 魔力回路(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("戦闘開始時、最大MP・現在MP+10%"
            ,Type.その他);}
        override void battleStart(Unit u){
            double value = u.prm!"MAX_MP".total / 10;
            u.prm!"MAX_MP".battle += value;
            u.mp += value;
            u.fixPrm;
        }
    });}
    //------------------------------------------------------------------
    @Value
    static Tec 戦術回路(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("戦闘開始時、最大TP・現在TP+10%"
            ,Type.その他);}
        override void battleStart(Unit u){
            double value = u.prm!"MAX_TP".total / 10;
            u.prm!"MAX_TP".battle += value;
            u.tp += value;
            u.fixPrm;
        }
    });}
    //----------------------------------------------------------------
    //
    //----------------------------------------------------------------
    //------------------------------------------------------------------
    //
    //習得もセットもしない技。
    //
    //------------------------------------------------------------------
    @Value
    static Tec 格闘カウンター(){static Tec res; return res !is null ? res : (res = new class Tec{
        this(){super("格闘攻撃でのカウンター技。この技は習得せず、セットもしない。"
            ,Type.格闘, Targeting.SELECT
            ,/*mp*/0, /*tp*/0, /*num*/()=>1, /*mul*/1.0, /*hit*/1.0);}
        override Dmg createDmg(Unit attacker, Unit target){
            Dmg dmg = super.createDmg( attacker, target );
            dmg.counter = true;
            return dmg;
        }

    });}
}