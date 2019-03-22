module job;

import laziness;
import unit;
import tec;
import std.typecons: Tuple;
import eq;

private alias GrowingPrm = Tuple!(
                            Unit.Prm, "prm",
                            int, "value",
                        );

abstract class Job{
    mixin Values!JobValues;

    enum MAX_LV = 10;
    enum DEF_LVUP_EXP = 5;

    static{
        Job rndJob(double lv){
            foreach(i; 0..7){
                Job job = Job.values.choice;
                if(job.appear_lv <= lv){
                    return job;
                }
            }
            return Job.しんまい;
        }
    }

    const string info;
    //!0
    const int lvup_exp;
    const double appear_lv;
    private GrowingPrm[] growing_prms;
    GrowingPrm[] getGrowingPrms(){return growing_prms;}
    private Tec[] learning_tecs;
    Tec[] getLearningTecs(){return learning_tecs;}


    private this(string info,int lvup_exp, double appear_lv, GrowingPrm[] growing_prms, Tec[] learning_tecs){
        this.info = info;
        this.lvup_exp = lvup_exp;
        this.appear_lv = appear_lv;
        this.growing_prms = growing_prms;
        this.learning_tecs = learning_tecs;
    }

    bool canJobChange(PUnit);
    void setEnemyInner(EUnit);

    void setEnemy(EUnit e, double lv){
        e.exists = true;
        e.dead = false;
        e.name = rndEnemyName();

        enum ATK_PRMS = [
            Unit.Prm.STR, Unit.Prm.MAG,
            Unit.Prm.LIG, Unit.Prm.DRK,
            Unit.Prm.CHN, Unit.Prm.PST,
            Unit.Prm.GUN, Unit.Prm.ARR,
        ];
        
        foreach(prm; ATK_PRMS){
            e.prm(prm).base     = uniform(0, 1.0 + lv);
            e.prm(prm).battle   = 0;
            e.prm(prm).eq       = 0;
        }

        e.prm!"LV".base = lv;
        e.exp = uniform(1.0, 2.0 + lv * 10);//入手経験値
        e.yen = cast(int)(1 + lv);

        e.prm!"MAX_HP".base = 1 + lv + uniform(0, (1 + lv) * 2);
        e.prm!"MAX_MP".base = Unit.DEF_MAX_MP;
        e.prm!"MAX_TP".base = Unit.DEF_MAX_TP;
        e.mp = 0;
        e.tp = 0;

        e.ai = EUnit.getDefAI;

        //-----------------------------------------------------
        //EqEar
        foreach(i; 0..EqEar.EAR_NUM){
            e.setEqEar(i, EqEar.rndEnemyEar( lv ));
        }
        //Eq
        import std.traits: EnumMembers;
        foreach(pos; [EnumMembers!(Eq.Pos)]){
            e.setEq( pos, Eq.rndEnemyEq( pos, lv ) );
        }
        //-----------------------------------------------------

        setEnemyInner(e);

        e.forceEquip();

        e.hp = e.prm!"MAX_HP".total;
    }
    
}


private GrowingPrm createGrowingPrm(string prm_name)(int value){
    Unit.Prm prm = mixin("Unit.Prm."~prm_name);
    GrowingPrm l;
    l.prm = prm;
    l.value = value;
    return l;
}


private string rndEnemyName(){
    static string[] names;
    if(names.length == 0){
        import std.stdio;
        File file = File("dat/name.txt" ,"r");
        foreach(line; file.byLine()){
            import std.conv;
            names ~= line.to!string;
        }
    }
    return names.choice;
}


private class JobValues{
    
    //-----------------------------------------------------
    @Value
    static Job   しんまい(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("新米"
            ,/*lvup_exp*/DEF_LVUP_EXP
            ,/*appear_lv*/0
            ,[createGrowingPrm!"MAX_HP"(1)]
            ,[Tec.練気, Tec.HP自動回復, Tec.静かなる動き]
        );}
        override bool canJobChange(PUnit p){return true;}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.殴る, Tec.殴る, Tec.練気, Tec.練気, Tec.練気, Tec.何もしない, Tec.何もしない];
        }
    });}
    @Value
    static Job   見習い(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("見習い"
            ,/*lvup_exp*/DEF_LVUP_EXP * 2
            ,/*appear_lv*/10
            ,[createGrowingPrm!"MAX_HP"(1)]
            ,[Tec.体力回路, Tec.魔力回路, Tec.戦術回路]
        );}
        override bool canJobChange(PUnit p){return p.isMastered(Job.しんまい);}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.殴る, Tec.殴る, Tec.練気, Tec.戦術回路, Tec.魔力回路, Tec.体力回路, Tec.何もしない];
        }
    });}
    @Value
    static Job   剣士(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("剣士"
            ,/*lvup_exp*/DEF_LVUP_EXP * 2
            ,/*appear_lv*/2
            ,[createGrowingPrm!"MAX_HP"(1)]
            ,[Tec.二刀, Tec.格闘攻撃UP, Tec.タックル]
        );}
        override bool canJobChange(PUnit p){return p.isMastered(Job.しんまい);}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.殴る, Tec.殴る, Tec.二刀, Tec.二刀, Tec.格闘攻撃UP, Tec.殴る, Tec.殴る];
        }
    });}
    @Value
    static Job   魔法使い(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("魔法を使う"
            ,/*lvup_exp*/DEF_LVUP_EXP * 2
            ,/*appear_lv*/5
            ,[createGrowingPrm!"MAG"(1)]
            ,[Tec.ヴァハ, Tec.魔法攻撃UP, Tec.エヴィン]
        );}
        override bool canJobChange(PUnit p){return p.isMastered(Job.しんまい);}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.殴る, Tec.殴る, Tec.ヴァハ, Tec.ヴァハ, Tec.ヴァハ, Tec.エヴィン, Tec.魔法攻撃UP];
        }
    });}
    @Value
    static Job   天使(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("回復に秀でたクラス"
            ,/*lvup_exp*/DEF_LVUP_EXP * 2
            ,/*appear_lv*/10
            ,[createGrowingPrm!"LIG"(1)]
            ,[Tec.天籟, Tec.数珠, Tec.良き占い, Tec.ユグドラシル]
        );}
        override bool canJobChange(PUnit p){return p.isMastered(Job.しんまい);}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.殴る, Tec.天籟, Tec.天籟, Tec.天籟, Tec.数珠, Tec.数珠, Tec.良き占い];
        }
    });}
    @Value
    static Job   暗黒剣士(){static Job res; return res !is null ? res : (res = new class Job{
        this(){super("自分の身を削り強力な攻撃を放つ"
            ,/*lvup_exp*/DEF_LVUP_EXP * 2
            ,/*appear_lv*/10
            ,[createGrowingPrm!"DRK"(1)]
            ,[Tec.暗黒剣, Tec.宵闇, Tec.吸血, Tec.VampireBloodyStar]
        );}
        override bool canJobChange(PUnit p){return p.isMastered(Job.しんまい);}
        override void setEnemyInner(EUnit e){
            e.tecs = [Tec.殴る, Tec.暗黒剣, Tec.暗黒剣,Tec.暗黒剣,Tec.暗黒剣, Tec.暗黒剣, Tec.吸血, Tec.VampireBloodyStar];
        }
    });}
    //-----------------------------------------------------
    //
    //-----------------------------------------------------
}