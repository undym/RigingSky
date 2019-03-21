module unit;


import laziness;
import player;
import force;
import tec;
import condition;
import job;
import eq;
import goods.goods;

abstract class Unit{

    enum PLAYER_NUM = 4;
    enum ENEMY_NUM = 4;
    enum ALL_NUM = PLAYER_NUM + ENEMY_NUM;

    static{
        PUnit[] players;
        EUnit[] enemies;
        Unit[] all(){
            return cast(Unit[])players~cast(Unit[])enemies;
        }

        void setup(){
            foreach(i; 0..PLAYER_NUM){
                players ~= Player.empty.ins;
            }

            foreach(i; 0..ENEMY_NUM){
                enemies ~= new EUnit;
            }
        }
    }

    enum Prm{
        MAX_HP, HP,
        MAX_MP, MP,
        MAX_TP, TP,

        STR, MAG,
        LIG, DRK,
        CHN, PST,
        GUN, ARR,

        LV, EXP,
        BP,

        EP, EP_CHARGE,
        
    }

    enum DEF_MAX_MP = 100;
    enum DEF_MAX_TP = 100;
    enum MAX_EP_CHARGE = 100;

    class PrmSet{
        double base = 0;
        double eq = 0;
        double battle = 0;

        double total(){
            double ret = base + eq + battle;
            return ret > 0 ? ret : 0;
        }
    }

    class ConditionSet{
        Condition condition;
        int value;
    }

    bool exists;
    bool dead;
    string name;
    Anime anime;
    Tec[] tecs;
    Job job;
    //エフェクト用
    Rect bounds;
    //エフェクト用
    FPoint center(){return bounds.center.to!float;}
    //エフェクト用
    FPoint rndCenter(){return center.move( uniform!"[]"(-20,20), uniform!"[]"(-20,20) );}

    protected PrmSet[] prm_sets;
    protected ConditionSet[] condition_sets;
    protected Eq[] eqs;
    protected EqEar[] eq_ears;

    protected this(){
        import std.traits: EnumMembers;
        foreach(prm; EnumMembers!Prm){
            prm_sets ~= new PrmSet;
        }

        foreach(type; EnumMembers!(Condition.Type)){
            auto set = new ConditionSet;
            set.condition = Condition.empty;
            condition_sets ~= set;
        }

        job = Job.しんまい;
        
        foreach(pos; [EnumMembers!(Eq.Pos)]){
            eqs ~= Eq.getDefEq(pos);
        }

        eq_ears.length = EqEar.EAR_NUM;
        foreach(ref ear; eq_ears){
            ear = EqEar.耳たぶ;
        }

    }

    bool isFriend(Unit);

    //------------------------------------------------------
    //
    //Prm
    //
    //------------------------------------------------------
    PrmSet prm(Prm p){return prm_sets[p];}
    PrmSet prm(string p)(){
        return prm(mixin("Prm."~p));
    }
    ref double hp()         {return prm_sets[ Prm.HP ].base;}
    ref double mp()         {return prm_sets[ Prm.MP ].base;}
    ref double tp()         {return prm_sets[ Prm.TP ].base;}
    ref double exp()        {return prm_sets[ Prm.EXP ].base;}
    ref double ep()         {return prm_sets[ Prm.EP ].base;}
    ref double epCharge()   {return prm_sets[ Prm.EP_CHARGE ].base;}
    ref double bp()         {return prm_sets[ Prm.BP ].base;}

    double getLvUpExp(){return (prm!"LV".base + 1) * 49;}
    
    void fixPrm(){
        import std.math: round;

        hp = hp.round;
        if(hp < 0){hp = 0;}
        if(hp > prm!"MAX_HP".total){hp = prm!"MAX_HP".total;}

        mp = mp.round;
        if(mp < 0){mp = 0;}
        if(mp > prm!"MAX_MP".total){mp = prm!"MAX_MP".total;}

        tp = tp.round;
        if(tp < 0){tp = 0;}
        if(tp > prm!"MAX_TP".total){tp = prm!"MAX_TP".total;}
    }

    //------------------------------------------------------
    //
    //Condition
    //
    //------------------------------------------------------
    void clearCondition(Condition.Type type){
        auto set = condition_sets[ type ];
        set.condition = Condition.empty;
        set.value = 0;
    }
    void setCondition(Condition cond, int value){
        auto set = condition_sets[ cond.type ];
        set.condition = cond;
        set.value = value < cond.max_value ? value : cond.max_value;
    }
    Condition getCondition(Condition.Type type) {return condition_sets[type].condition;}
    Condition getCondition(string type)()       {return getCondition( mixin("Condition.Type."~type) );}
    int getConditionValue(Condition.Type type)  {return condition_sets[ type ].value;}
    int getConditionValue(string type)()        {return getCondition( mixin("Condition.Type."~type) );}
    //すでにそのConditionならvalueを追加、Conditionが違った場合、新しいConditionとvalueをセット。
    void addCondition(Condition cond, int value){
        auto set = condition_sets[ cond.type ];
        if(set.condition == cond){
            set.value += value;
        }else{
            set.condition = cond;
            set.value = value;
        }
        if(set.value <= 0)                          {set.condition = Condition.empty;}
        else if(set.value > set.condition.max_value){set.value = set.condition.max_value;}
    }
    //------------------------------------------------------
    //
    //Eq
    //
    //------------------------------------------------------
    Eq eq(Eq.Pos pos)   {return eqs[pos];}
    Eq eq(string pos)() {return eqs[ mixin("Eq.Pos."~pos) ];}
    void setEq(Eq.Pos pos, Eq eq)   {eqs[pos] = eq;}

    EqEar eqEar(int i){return eq_ears[i];}
    void setEqEar(int i, EqEar ear){eq_ears[i] = ear;}
    //------------------------------------------------------
    //
    //Force
    //
    //------------------------------------------------------
    void forceBattleStart(){
        foreach(set; prm_sets){
            set.battle = 0;
        }
        force(f=> f.battleStart(this));
    }
    void forcePhaseStart(){force(f=> f.phaseStart(this));}
    void forcePhaseEnd(){force(f=> f.phaseEnd(this));}
    void forceBeforeDoAtk(Tec tec, Unit target, Dmg dmg)     {force(f=> f.beforeDoAtk(tec, this, target, dmg));}
    void forceBeforeBeAtk(Tec tec, Unit attacker, Dmg dmg)   {force(f=> f.beforeBeAtk(tec, attacker, this, dmg));}
    void forceAfterDoAtk(Tec tec, Unit target, Dmg dmg)      {force(f=> f.afterDoAtk(tec, this, target, dmg));}
    void forceAfterBeAtk(Tec tec, Unit attacker, Dmg dmg)    {force(f=> f.afterBeAtk(tec, attacker, this, dmg));}
    void forceEquip() {
        import std.traits: EnumMembers;
        foreach(prm; [EnumMembers!Prm]){
            prm_sets[prm].eq = 0;
        }
        force(f=> f.equip(this));
        
    }
    void forceWalk(WalkMng walk_mng){
        force(f=> f.walk(this, walk_mng));
    }

    protected void force(void delegate(IForce) dlgt){
        foreach(tec; tecs){
            dlgt( tec );
        }
        foreach(eq; eqs){
            dlgt( eq );
        }
        foreach(ear; eq_ears){
            dlgt( ear );
        }
        foreach(set; condition_sets){
            dlgt( set.condition );
        }
    }
    //------------------------------------------------------
    //
    //
    //
    //------------------------------------------------------
    void doDmg(double dmg){
        if(!exists || dead){return;}

        import std.math: floor;
        dmg = dmg.floor;
        hp -= dmg;
        fixPrm;

        // void flipStr(string s, const FPoint center, Color color, Font font, int over = 50) {
        import effect: Effect;
        Effect.flipStr( format!"%.0f"(dmg), rndCenter, Color.WHITE );

        Util.msg.set(format!"%sに%.0fのダメージ"(name, dmg), cnt=> Color.RED.bright(cnt)); cwait;

    }

    void judgeDead(){
        if(!exists || dead){return;}

        if(hp <= 0){
            dead = true;
            Util.msg.set(format!"%sは死んだ"(name)); cwait;
        }
    }
}


class PUnit: Unit{


    private Player player;
    Player getPlayer(){return player;}
    private int[Job] job_lvs;
    private int[Job] job_exps;
    private bool[Tec] learned_tecs;
    int tec_btn_page;


    this(Player player){
        this.player = player;

        foreach(j; Job.values()){
            job_lvs[j] = 0;
            job_exps[j] = 0;
        }
        foreach(tec; Tec.values()){
            learned_tecs[tec] = false;
        }
    }

    override bool isFriend(Unit u){
        return cast(PUnit)u ? true : false;
    }

    void addExp(double value){
        exp += value;
        if(exp >= getLvUpExp){
            exp = 0;
            prm!"LV".base += 1;

            // import effect;
            // Effect.LvUp( bounds.center.to!float, Color.GREEN );
            Util.msg.set(format!"%sのLvが%.0fになった！"( name, prm!"LV".total ), cnt=> Color.YELLOW.bright(cnt)); cwait;

            double add_bp = 1;
            Util.msg.set(format!"BP+%.0f"( add_bp ), cnt=> Color.YELLOW.bright(cnt)); cwait;
            
            if(!PlayData.meisou_btn_visible){
                PlayData.meisou_btn_visible = true;
                Util.msg.set("瞑想が可能になった", cnt=> Color.ORANGE.bright(cnt));
            }

            {
                double add_hp = 1;
                prm!"MAX_HP".base += add_hp;
                Util.msg.set(format!"[最大HP]+%s"( add_hp ), cnt=> Color.SALMON.bright(cnt)); cwait;
            }
            growJobPrm();
        }
    }

    //------------------------------------------------------
    //
    //Job
    //
    //------------------------------------------------------
    void setJobLv(Job job, int value){job_lvs[ job ] = value;}
    int getJobLv()          {return job_lvs[ job ];}
    int getJobLv(Job job)   {return job_lvs[ job ];}
    bool isMastered(Job job){return job_lvs[ job ] >= Job.MAX_LV;}

    void setJobExp(Job job, int value){job_exps[ job ] = value;}
    int getJobExp()         {return job_exps[ job ];}
    int getJobExp(Job job)  {return job_exps[ job ];}

    void addJobExp(int value){
        //技欄に空きがあれば、覚えた技をセットする
        void setLearningTec(Tec tec){
            for(int j = 0; j < tecs.length; j++){
                if(tecs[j] == Tec.empty){
                    tecs[j] = tec;
                    return;
                }
            }
            //技欄に空きがなくなった時、技のセットのボタンが出現
            if(!PlayData.tec_btn_visible){
                PlayData.tec_btn_visible = true;
                Util.msg.set("技のセットが可能になった", cnt=> Color.ORANGE.bright(cnt));
            }
        }
        if(job_lvs[job] >= Job.MAX_LV){return;}

        int* exp = &job_exps[job];
        int* lv = &job_lvs[job];
        *exp += value;
        if(*exp >= job.lvup_exp){
            *exp = 0;

            *lv += 1;
            if(*lv >= Job.MAX_LV){
                *lv = Job.MAX_LV;
                Util.msg.set(format!"%sの%sLvが最大になった！"( name, job ), cnt=> Color.CYAN.bright(cnt)); cwait;

                if(!PlayData.job_btn_visible){
                    PlayData.job_btn_visible = true;
                    Util.msg.set("転職が可能になった", cnt=> Color.ORANGE.bright(cnt));
                }
            }else{
                Util.msg.set(format!"%sの%sLvが%sになった"( name, job, *lv ), cnt=> Color.CYAN.bright(cnt)); cwait;
            }

            double ratio = cast(double)*lv / Job.MAX_LV;
            Tec[] learnings = job.getLearningTecs();
            foreach(i,tec; learnings){
                if(isLearned(tec)){continue;}
                if(cast(double)(i + 1) / learnings.length <= ratio || *lv >= Job.MAX_LV){
                    setLearned(tec, true);
                    Util.msg.set(format!"%sは[%s]を覚えた！"( name, tec ), cnt=> Color.SALMON.bright(cnt)); cwait;
                    Util.msg.set(format!"-> %s"( tec.info ), cnt=> Color.WHITE.bright(cnt)); cwait;
                    
                    setLearningTec(tec);
                }
            }

            
            growJobPrm();
        }

    }
    //------------------------------------------------------
    //
    //Tec
    //
    //------------------------------------------------------
    bool isLearned(Tec tec)         {return learned_tecs[ tec ];}
    void setLearned(Tec tec, bool b){learned_tecs[ tec ] = b;}
    //------------------------------------------------------
    //
    //
    //
    //------------------------------------------------------
    private void growJobPrm(){
        auto grow = job.getGrowingPrms();
        foreach(gr; grow){
            prm(gr.prm).base += gr.value;
            Util.msg.set(format!"[%s]+%s"( getPrmName(gr.prm), gr.value ), cnt=> Color.SALMON.bright(cnt)); cwait;
        }
    }
}


class EUnit: Unit{
    alias AI = void delegate(EUnit,Unit[]);

    static AI getDefAI(){
        static AI ret;
        if(ret is null){
            ret = (e,units){

                Tec[] actives = e.tecs.filter!(t=> t.passive).array;
                int search_num = actives ? 7 : 0;
                
                foreach(i; 0..search_num){
                    Tec tec = actives.choice;
                    if(!tec.checkCost(e)){continue;}

                    Unit[] targets = getTargets( tec.targetings, e, units, tec.rndAttackNum );
                    if(targets.length == 0){continue;}

                    tec.use( e, targets );
                    return;
                }

                Tec tec = Tec.殴る;
                tec.use( e, getTargets( Tec.殴る.targetings, e, units, tec.rndAttackNum ) );
            };
        }
        return ret;
    }

    AI ai;
    //撃破時の入手金
    int yen;
    /**撃破時の入手アイテム。*/
    private IGoods drop_item;
    IGoods getDropItem()            {return drop_item;}
    void setDropItem(IGoods goods)  {drop_item = goods;}
    void clearDropItem()            {drop_item = IGoods.empty;}
    bool existsDropItem()           {return drop_item != IGoods.empty;}

    this(){
        ai = getDefAI();
        clearDropItem();
    }
    
    override bool isFriend(Unit u){
        return cast(EUnit)u ? true : false;
    }

}


string getPrmName(Unit.Prm prm){
    alias Prm = Unit.Prm;
    final switch(prm){
        case Prm.MAX_HP : return "最大HP";
        case Prm.HP     : return "HP";
        case Prm.MAX_MP : return "最大MP";
        case Prm.MP     : return "MP";
        case Prm.MAX_TP : return "最大TP";
        case Prm.TP     : return "TP";
        case Prm.STR    : return "力";
        case Prm.MAG    : return "魔";
        case Prm.LIG    : return "光";
        case Prm.DRK    : return "闇";
        case Prm.CHN    : return "鎖";
        case Prm.PST    : return "過";
        case Prm.GUN    : return "銃";
        case Prm.ARR    : return "弓";
        case Prm.LV     : return "Lv";
        case Prm.EXP    : return "exp";
        case Prm.BP     : return "BP";
        case Prm.EP     : return "EP";
        case Prm.EP_CHARGE: return "EP_CHARGE";
    }
}