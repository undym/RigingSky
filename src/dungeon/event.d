module dungeon.event;

import laziness;
import dungeon.dungeon;
import effect;
import unit;
import goods.item;

private alias EvDlgt = void delegate();

class Event{
    mixin Values!EventValues;

    static Event now;
    
    final void happen(){
        Event.now = this;
        happenInner();
    }

    void happenInner(){

    }

    void leftClick(){
        import unit;
        Effect.進む( Bounds.toPixelRect( Bounds.Ratio.MAIN ) );

        int add_au = 1;
        foreach(p; Unit.players){
            if(!p.exists || p.dead){continue;}
            p.forceWalk( &add_au );
        }
        Dungeon.now_au += add_au;

        if(Dungeon.now_au >= Dungeon.now.getAU){
            Dungeon.now_au = Dungeon.now.getAU;

            Event.BOSS_BATTLE.happen();
            return;
        }

        Dungeon.now.rndEvent().happen();
    }

    void rightClick(){
        Effect.戻る( Bounds.toPixelRect( Bounds.Ratio.MAIN ) );

        int add_au = -1;
        foreach(p; Unit.players){
            if(!p.exists || p.dead){continue;}
            p.forceWalk( &add_au );
        }
        Dungeon.now_au += add_au;

        if(Dungeon.now_au < 0){
            Dungeon.now_au = 0;

            Event.ESCAPE_DUNGEON.happen();
            return;
        }
        
        Dungeon.now.rndEvent().happen();
    }

    private Anime anime;
    Anime getAnime(){return anime is null ? Anime.empty : anime;}

    private bool reset_zoom;
    bool isResetZoom(){return reset_zoom;}

    private this(){
    }

}


private class KeyBoxEvent: Event{
    Item key;
    const int base_open_num;
    const int base_rank;

    this(Item delegate() key, const int base_open_num, const int base_rank){
        this.key = key();
        this.base_open_num = base_open_num;
        this.base_rank = base_rank;

        anime = new Anime("img/ev/box_closed.png",1);
        reset_zoom = true;
    }

    override void happenInner(){
        Util.msg.set(format!"%sだ！"( this.toString() ), cnt=>Color.ORANGE.bright(cnt));
        Util.msg.set(format!"%s(%s)があるなら右クリックで開ける"(key, key.num));
    }

    override void rightClick(){
        if(key.num == 0){
            Util.msg.set(format!"[%s]を持っていない"(key));
            return;
        }else{
            key.num--;
            Util.msg.set(format!"%sを開けた..."( this.toString() )); cwait();

            const int open = {
                int res = base_open_num;
                while(uniform(0.0,1.0) <= 0.5){res++;}
                return res;
            }();

            foreach(i; 0..open){
                int rank = Item.rankFluctuate(/*base*/base_rank, /*range*/1);
                Item item = Item.rndBoxItem( rank );
                item.add(1); cwait();
            }
        }
        Event.OPENED_KEY_BOX.happen();
    }
}


private void lostYen(){
    int lost_yen = PlayData.yen * 2 / 5;
    PlayData.yen -= lost_yen;
    Util.msg.set(format!"%s円を失った..."(lost_yen), cnt=> Color.RED.bright(cnt)); cwait;
}


private class EventValues{
    
    //---------------------------------------------------------------------
    //
    //---------------------------------------------------------------------
    @Value
    static Event empty(){static Event res; return res !is null ? res : (res = new class Event{
    });}
    @Value
    static Event BOX(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/box.png",1);
            reset_zoom = true;
        }
        override void happenInner(){
            //ダンジョン特有入手アイテム
            auto trend_items = Dungeon.now.getTrendItems();
            if(trend_items && uniform(0.0,1.0) <= 0.15){
                trend_items.choice.add(1); cwait;
            }
            //通常入手アイテム
            const int open = {
                int res = 1;
                while(uniform(0.0,1.0) <= 0.15){res++;}
                return res;
            }();
            foreach(i; 0..open){
                int rank = Item.rankFluctuate( /*base*/Dungeon.now.getRank, /*range*/3 );
                Item item = Item.rndBoxItem( rank );
                int num = 1;
                item.add(num);
                if(i < open - 1){cwait();}
            }
        }
    });}
    @Value
    static Event 丸い箱(){static Event res; return res !is null ? res : (res = new KeyBoxEvent(
        ()=> Item.丸い鍵
        ,/*open*/3
        ,/*rank*/4
    ));}
    @Value
    static Event OPENED_KEY_BOX(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/box.png",1);
            reset_zoom = false;
        }
    });}
    @Value
    static Event TRESURE(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/tresure_closed.png",1);
            reset_zoom = true;
        }
        override void happenInner(){
            Util.msg.set("財宝の箱だ！",cnt=>Color.CYAN.bright(cnt));
            Util.msg.set("右クリックで開こう");
        }
        override void rightClick(){
            auto key = Dungeon.now.getTresureKey();
            if(key.num == 0){
                Util.msg.set(format!"[%s]を持っていない..."(key));
            }else{
                key.num--;
                Util.msg.set(format!"[%s]を使って箱を開けた！"(key)); cwait;
                Event.TRESURE_OPEN.happen();
            }
        }
    });}
    @Value
    static Event TRESURE_OPEN(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/tresure.png",1);
            reset_zoom = false;
        }

        override void happenInner(){
            Dungeon.now.opened_tresure_num++;

            auto tresures = Dungeon.now.getTresures();

            if(tresures.length == 0){
                Util.msg.set("空だった...");
                return;
            }
            float[] probs;
            foreach(t; tresures){
                probs ~= t.prob;
            }

            int choosed_index = dice(probs);
            tresures[choosed_index].goods.add(1);
        }
    });}
    @Value
    static Event REST(){static Event res; return res !is null ? res : (res = new class Event{
        override void happenInner(){
            if(uniform(0.0,1.0) < 0.1f){
                Util.msg.set("トイレ休憩した...");
            }else{
                Util.msg.set("休憩した...");
            }

            foreach(p; Unit.players){
                if(p.exists && !p.dead){
                    double heal_hp = p.prm!"MAX_HP".total / 3;
                    double heal_mp = p.prm!"MAX_MP".total / 3;
                    p.hp += heal_hp;
                    p.mp += heal_mp;
                    p.fixPrm;

                    Effect.flipStr( format!"%.0f"(heal_hp), p.rndCenter, Color.GREEN );
                    Effect.flipStr( format!"%.0f"(heal_mp), p.rndCenter, Color.PINK );
                }
            }
        }
    });}
    @Value
    static Event TRAP_LV1(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/trap.png",1);
            reset_zoom = true;
        }
        override void happenInner(){
            Util.msg.set("罠だ！", Color.RED);
            Util.msg.add("右クリックで解除しよう！");
        }
        override void leftClick(){
            Util.msg.set("引っかかった！", Color.RED); cwait;

            foreach(p; Unit.players){
                if(!p.exists || p.dead){continue;}

                Effect.atk( p.center, Color.RED );
                double dmg = p.prm!"MAX_HP".total / 5;
                if(dmg > 99){dmg = 99;}
                p.doDmg( dmg );
                p.judgeDead;
            }
            //罠に引っかかった場合なにもイベントを発生させない
        }
        override void rightClick(){
            Util.msg.set("解除成功");
            Event.TRAP_BROKEN.happen();
        }
    });}
    @Value
    static Event TRAP_LV2(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/trap.png",1);
            reset_zoom = true;
        }
        override void happenInner(){
            Util.msg.set("罠Lv2だ！", Color.RED);
            Util.msg.add("右クリックで解除しよう！");
        }
        override void leftClick(){
            Util.msg.set("引っかかった！", Color.RED); cwait;

            foreach(p; Unit.players){
                if(!p.exists || p.dead){continue;}

                Effect.atk( p.center, Color.RED );
                double dmg = p.prm!"MAX_HP".total / 5;
                if(dmg > 199){dmg = 199;}
                p.doDmg( dmg );
                p.judgeDead;
            }

            //罠に引っかかった場合なにもイベントを発生させない
        }
        override void rightClick(){
            Util.msg.set("解除成功");
            Event.TRAP_BROKEN.happen();
        }
    });}
    @Value
    static Event TRAP_BROKEN(){static Event res; return res !is null ? res : (res = new class Event{
        this(){
            anime = new Anime("img/ev/trap_broken.png",1);
            reset_zoom = false;
        }
    });}
    @Value
    static Event BATTLE(){static Event res; return res !is null ? res : (res = new class Event{
        override void happenInner(){
            Dungeon.now.setEnemy;
            Util.msg.set("敵が現れた", Color.MAGENTA);

            import scene.battlescene;
            alias Result = BattleScene.Result;
            Result result = BattleScene.ins.start( BattleScene.Type.NORMAL );
            final switch(result){
                case Result.WIN:
                    return;
                case Result.LOSE:
                    lostYen();
                    Event.ESCAPE_DUNGEON.happen();
                    return;
                case Result.ESCAPE:
                    return;
            }
        }
    });}
    @Value
    static Event BOSS_BATTLE(){static Event res; return res !is null ? res : (res = new class Event{
        override void happenInner(){
            Dungeon.now.setBoss();
            Util.msg.set("ボスが現れた");

            import scene.battlescene;
            alias Result = BattleScene.Result;
            Result result = BattleScene.ins.start( BattleScene.Type.BOSS );
            final switch(result){
                case Result.WIN:

                    Dungeon.now.clear_num++;
                    Util.msg.set(format!"[%s]を踏破した！"( Dungeon.now ), cnt=> Color.CYAN.bright(cnt)); cwait;

                    if(Dungeon.now.clear_num == 1){
                        foreach(reward; Dungeon.now.getFirstClearRewards()){
                            reward.add(1); cwait;
                        }
                    }

                    Dungeon.now.runClearEvent( Dungeon.now.clear_num );

                    Event.ESCAPE_DUNGEON.happen();
                    return;
                case Result.LOSE:
                    lostYen();
                    Event.ESCAPE_DUNGEON.happen();
                    return;
                case Result.ESCAPE:
                    Event.ESCAPE_DUNGEON.happen();
                    return;
            }
        }
    });}
    @Value
    static Event EX_BATTLE(){static Event res; return res !is null ? res : (res = new class Event{
        override void happenInner(){
            Dungeon.now.setEx();
            Util.msg.set("エクストラエネミー！！！", cnt=>Color.WHITE.bright(cnt));

            import scene.battlescene;
            alias Result = BattleScene.Result;
            Result result = BattleScene.ins.start( BattleScene.Type.EX );
            final switch(result){
                case Result.WIN:

                    Dungeon.now.killed_ex_num++;

                    return;
                case Result.LOSE:
                    Util.msg.set("この戦いでは全滅ペナルティが発生しない"); cwait();
                    Event.ESCAPE_DUNGEON.happen();
                    return;
                case Result.ESCAPE:
                    return;
            }
        }
    });}
    @Value
    static Event ESCAPE_DUNGEON(){static Event res; return res !is null ? res : (res = new class Event{
        override void happenInner(){
            Dungeon.escape = true;
        }
    });}
    //---------------------------------------------------------------------
    //
    //---------------------------------------------------------------------
}