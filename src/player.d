module player;

import laziness;
import unit;
import tec;
import job;

abstract class Player{
    mixin Values!PlayerValues;

    protected PUnit instance;
    PUnit ins(){
        if(instance is null){
            instance = create;
        }
        return instance;
    }

    bool member;

    private this(){
    }
    
    abstract protected void createInner(PUnit p);

    protected PUnit create(){
        PUnit p = new PUnit(this);
        p.exists = true;
        p.name = this.toString;
        p.prm!"MAX_MP".base = Unit.DEF_MAX_MP;
        p.prm!"MAX_TP".base = Unit.DEF_MAX_TP;
        
        createInner(p);

        p.hp = p.prm!"MAX_HP".total;
        
        foreach(tec; p.tecs){
            p.setLearned(tec, true);
        }

        return p;
    }
    
}


private class PlayerValues{
    //------------------------------------------------------------------
    @UniqueName( "empty")
    static Player empty(){static Player res; return res !is null ? res : (res = new class Player{
            override protected PUnit create(){return new PUnit(this);}
            override protected void createInner(PUnit){}
    });}
    //------------------------------------------------------------------
    @UniqueName( "スメラギ")
    static Player スメラギ(){static Player res; return res !is null ? res : (res = new class Player{
            override protected void createInner(PUnit p){
                p.tecs = [Tec.殴る, Tec.二刀, Tec.empty, Tec.empty, Tec.empty, Tec.empty];
                p.prm!"MAX_HP".base = 30;
                p.prm!"STR".base = 5;
            }
    });}
    //------------------------------------------------------------------
    @UniqueName( "よしこ")
    static Player よしこ(){static Player res; return res !is null ? res : (res = new class Player{
            override protected void createInner(PUnit p){
                p.job = Job.魔法使い;
                p.setJobLv( Job.魔法使い, 1 );//転職画面で表示するために
                p.tecs = [Tec.殴る, Tec.ヴァハ, Tec.empty, Tec.empty, Tec.empty, Tec.empty];
                p.prm!"MAX_HP".base = 20;
                p.prm!"STR".base = 3;
                p.prm!"MAG".base = 8;
            }
    });}
    //------------------------------------------------------------------
    //
    //------------------------------------------------------------------
}