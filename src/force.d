module force;

import unit;
public import tec;

interface IForce{
    void battleStart(Unit);
    void battleEnd(Unit);
    void phaseStart(Unit);
    void phaseEnd(Unit);
    void beforeDoAtk(Tec, Unit attacker, Unit target, Dmg);
    void beforeBeAtk(Tec, Unit attacker, Unit target, Dmg);
    void afterDoAtk(Tec, Unit attacker, Unit target, Dmg);
    void afterBeAtk(Tec, Unit attacker, Unit target, Dmg);
    void equip(Unit);
    void walk(Unit, int* add_au);
}


template MForce(){
    override void battleStart(Unit){}
    override void battleEnd(Unit){}
    override void phaseStart(Unit){}
    override void phaseEnd(Unit){}
    override void beforeDoAtk(Tec,Unit,Unit,Dmg){}
    override void beforeBeAtk(Tec,Unit,Unit,Dmg){}
    override void afterDoAtk(Tec,Unit,Unit,Dmg){}
    override void afterBeAtk(Tec,Unit,Unit,Dmg){}
    override void equip(Unit){}
    override void walk(Unit,int*){}
}

class Dmg{
    
    static private double calcCut(double def){
        return (2000.0 + def * 1) / (2000.0 + def * 8);
    }
    //攻撃値
    double pow;
    //倍率
    double mul;
    //防御値
    double def;
    double hit;
    //絶対攻撃値
    double abs;

    double result;
    bool result_hit;
    //カウンター技
    bool counter;

    this(){
        clear;
    }

    void clear(){
        pow = 0;
        mul = 1;
        def = 0;
        hit = 0;
        abs = 0;
        result = 0;
        result_hit = false;
        counter = false;
    }

    double calc(){
        result_hit = uniform(0.0,1.0) <= hit;
        if(result_hit){
            import std.random: uniform;
            double cut = calcCut(def);
            result = pow * mul * cut * uniform!"[]";
        }else{
            result = 0;
        }

        result += abs * mul;

        if(result < 0){
            return result = 0;
        }

        return result;
    }

}




unittest{
    import std.format;
    string str;
    double def = 1;
    foreach(i; 0..6){
        double cut = Dmg.calcCut( def );

        str ~= format!"[def:%.0f, defcut:%.2f]"( def, cut );

        def *= 10;
    }
    
    import undym.util;
    str.trace;
}


enum Targeting{
    SELECT      = 1 << 0,
    SELF        = 1 << 1,
    ALL         = 1 << 2,
    ONLY_DEAD   = 1 << 3,
    WITH_DEAD   = 1 << 4,
    ONLY_FRIEND = 1 << 5,
    WITH_FRIEND = 1 << 6,
    RANDOM      = 1 << 7,
}


T[] getTargets(T:Unit)(Targeting targetings, Unit attacker, T[] targets, int attack_num){
    import std.algorithm: remove;
    import std.random: choice;

    T[] censored = {
        T[] censored = targets.dup;
        censored = censored.remove!(u=> !u.exists);   

             if(targetings & Targeting.ONLY_DEAD)   {censored = censored.remove!(u=> !u.dead);}
        else if(targetings & Targeting.WITH_DEAD)   {}
        else                                        {censored = censored.remove!(u=> u.dead);}
        
             if(targetings & Targeting.ONLY_FRIEND) {censored = censored.remove!(u=> !u.isFriend(attacker));}
        else if(targetings & Targeting.WITH_FRIEND) {}
        else                                        {censored = censored.remove!(u=> u.isFriend(attacker));}

        return censored;
    }();

    if(!censored){return [];}

    T[] ret;
    
    if(targetings & Targeting.SELECT){
        T choosed = censored.choice;
        foreach(i; 0..attack_num){
            ret ~= choosed;
        }
        return ret;
    }

    if(targetings & Targeting.SELF){
        foreach(i; 0..attack_num){
            ret ~= attacker;
        }
        return ret;
    }

    if(targetings & Targeting.RANDOM){
        foreach(i; 0..attack_num){
            ret ~= censored.choice;
        }
        return ret;
    }
        
    if(targetings & Targeting.ALL){
        foreach(i; 0..attack_num){
            ret ~= censored;
        }
        return ret;
    }

    return ret;
}


unittest{
    import std.format;
    import undym.util;
    import player;

    Unit[] units;
    foreach(i; 0..4){
        PUnit u = new PUnit( Player.スメラギ );
        u.name = format!"p%s"(i);
        units ~= u;
    }
    foreach(i; 0..4){
        EUnit u = new EUnit;
        u.name = format!"e%s"(i);
        units ~= u;
    }

    foreach(i,u; units){
        u.exists = true;
    }

    units[$-1].exists = false;
    units[3].dead = true;

    const Targeting targetings = Targeting.ALL | Targeting.ONLY_FRIEND;
    const attack_num = 2;
    Unit[] targets = getTargets( targetings, units[0], units, attack_num );
    {
        import std.traits: EnumMembers;
        string targeting_names = "Targeting.";
        foreach(t; EnumMembers!Targeting){
            if(t & targetings){
                targeting_names ~= format!"%s | "(t);
            }
        }
        targeting_names.trace;
        format!"attack_num:%s"(attack_num).trace;
    }
    {
        string str;
        foreach(t; targets){
            str ~= format!"[%s]"(t.name);
        }
        str.trace;
    }
}