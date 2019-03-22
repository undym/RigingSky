module goods.item;

import laziness;
import unit;
import force;
import effect;
import goods.goods;

abstract class Item: IGoods{
    mixin MGoods;
    mixin Values!ItemValues;

    enum NO_SELL = 0;

    enum Type{
        蘇生,
        HP回復,
        MP回復,
        成長,
        宝物鍵,
        財宝鍵,
        素材,
        メモ,
    }

    enum ParentType: Type[]{
        回復 = [Type.蘇生, Type.HP回復, Type.MP回復],
        成長 = [Type.成長],
        鍵 = [Type.宝物鍵, Type.財宝鍵],
        素材 = [Type.素材],
        その他 = [Type.メモ],
    }

    private enum UseType{
        FIELD,
        DUNGEON,
        BATTLE,
    }

    static{
        Item[] getTypeValues(Type type){
            static Item[][Type] type_values;
            static bool init;
            if(!init){
                init = true;
                foreach(item; values()){
                    type_values[ item.type ] ~= item;
                }
            }


            // Item[]* v = type in type_values;
            // return v !is null ? *v : [];
            return type in type_values ? type_values[type] : [];
        }

        Item rndBoxItem(int rank){
            static Item[][int] rank_values;
            static bool init;
            if(!init){
                init = true;
                foreach(item; values()){
                    rank_values[ item.rank ] ~= item;
                }
            }

            if(rank < 0){rank = 0;}
            if(rank !in rank_values){return rndBoxItem(rank-1);}

            Item[] candidates = rank_values[rank];
            foreach(i; 0..7){
                Item item = candidates.choice;
                if(
                       item.box
                    && item.num < item.getMaxNum
                ){
                    return item;
                }

            }
            return Item.石;
        }
        
        /**
            base = 10.0, range = 3.0
            [7:2.7%],[8:5.0%],[9:10.2%],[10:63.0%],[11:10.8%],[12:6.2%],[13:2.1%],
        */
        int rankFluctuate(double base, double range){
            import std.mathspecial : normalDistribution;
            import std.math : pow, abs, round;

            if(base < 0){base = 0;}

            foreach(i; 0..3){
                enum d_range = 3.5;
                const d = uniform!"[]"(-d_range , d_range);
                const nd = 1.0 - abs(0.5 - normalDistribution(d));
                if (nd.pow(3) >= uniform(0.0, 1.0)) {
                    int ret = cast(int)round(base + d / d_range * range);
                    return ret > 0 ? ret : 0;
                }
            }
            return cast(int)base;
        }
    }


    private string info;
    string getInfo(){return info;}
    const Type type;
    const int rank;
    const bool box;

    int getMaxNum(){return 9999;}

    protected Targeting targeting = Targeting.SELECT;
    Targeting getTargeting(){return targeting;};

    protected void delegate(Unit)[UseType] uses;
    void useIn(string type_name)(Unit[] targets){
        UseType type = mixin("UseType."~type_name);
        if(type !in uses){return;}

        foreach(t; targets){
            uses[type](t);
        }

        num--;
    }
    bool canUseIn(string type_name)(){
        UseType type = mixin("UseType."~type_name);
        if(type in uses){return true;}
        return false;
    }
    protected void setUseIn(T...)(void delegate(Unit) dlgt){
        static foreach(t; T){
            final switch(mixin("UseType."~t)){
                case UseType.FIELD  : uses[ UseType.FIELD ]   = dlgt; break;
                case UseType.DUNGEON: uses[ UseType.DUNGEON ] = dlgt; break;
                case UseType.BATTLE : uses[ UseType.BATTLE ]  = dlgt; break;
            }
        }
    }





    private this(string info, Type type, int rank, bool box){
        this.info = info;
        this.type = type;
        this.rank = rank;
        this.box = box;
    }

    int getPrice(){return NO_SELL;}

    Composition getComposition(){return Composition.empty;}



}


unittest{
    enum base = 10.0;
    enum range = 3.0;
    enum loop = 500;
    int[int] arr;
    foreach(i; 0..loop){
        int rank = Item.rankFluctuate(base, range);
        arr[rank] ++;
    }

    import std.format;
    import std.algorithm: sort;
    string str = " ->";
    foreach(key; arr.keys.sort){
        str ~= format!"[%s:%.1f%%],"( key, cast(float)arr[key] / loop * 100 );
    }

    format!"rankFluctuate(/*base*/%.1f, /*range*/%.1f)"(base, range).trace;
    str.trace;
}


private void healHP(Unit target, double value){
    target.hp += value;
    target.fixPrm;

    
    Effect.flipStr( format!"%.0f"(value), target.rndCenter, Color.GREEN );
    Util.msg.set(format!"%sのHPが%.0f回復した"(target.name, value));
}

private void healMP(Unit target, double value){
    target.mp += value;
    target.fixPrm;

    
    Effect.flipStr( format!"%.0f"(value), target.rndCenter, Color.PINK );
    Util.msg.set(format!"%sのMPが%.0f回復した"(target.name, value));
}



private class ItemValues{
    //-------------------------------------------------------------
    //
    //蘇生
    //
    //-------------------------------------------------------------
    @Value
    static Item  サンタクララ薬(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("一体をHP1で蘇生",
            Type.蘇生, /*rank*/0, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                if(u.dead){
                    u.dead = false;
                    u.hp = 1;
                    Util.msg.set(format!"%sは生き返った"( u.name ));
                }else{
                    Util.msg.set(format!"%s「生きてます」"( u.name ));
                }
            });
        }

        override int getPrice(){return 100;}
    });}
    //-------------------------------------------------------------
    //
    //HP回復
    //
    //-------------------------------------------------------------
    @Value
    static Item  スティックパン(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+10",
            Type.HP回復, /*rank*/0, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, 10 );
            });
        }
        override int getPrice(){return 20;}
    });}
    @Value
    static Item  ロングスティックパン(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+20",
            Type.HP回復, /*rank*/1, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, 20 );
            });
        }
        override int getPrice(){return 60;}
    });}
    @Value
    static Item  ダブルスティックパン(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+40",
            Type.HP回復, /*rank*/2, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, 40 );
            });
        }
        override int getPrice(){return 200;}
    });}
    @Value
    static Item  苺ちゃんのパン(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+80",
            Type.HP回復, /*rank*/3, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, 80 );
            });
        }
    });}
    @Value
    static Item  ドラッグ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+10%"
            ,Type.HP回復, /*rank*/3, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, u.prm!"MAX_HP".total * 0.1 + 1 );
            });
        }
    });}
    @Value
    static Item  LAドラッグ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+20%"
            ,Type.HP回復, /*rank*/4, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, u.prm!"MAX_HP".total * 0.2 + 1 );
            });
        }
        override string toString(){return "L.A.ドラッグ";}
    });}
    @Value
    static Item  ロシアドラッグ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+30%"
            ,Type.HP回復, /*rank*/5, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, u.prm!"MAX_HP".total * 0.3 + 1 );
            });
        }
    });}
    @Value
    static Item  スティックパン超キラキラ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("HP+999"
            ,Type.HP回復, /*rank*/9, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healHP( u, 999 );
            });
        }
        override string toString(){return "スティックパン（超キラキラ）";}
    });}
    //-------------------------------------------------------------
    //
    //MP回復
    //
    //-------------------------------------------------------------
    @Value
    static Item  蛍草(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("MP+10"
            ,Type.MP回復, /*rank*/0, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healMP( u, 10 );
            });
        }
    });}
    @Value
    static Item  赤葉草(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("MP+20"
            ,Type.MP回復, /*rank*/2, /*box*/true);

            setUseIn!("FIELD","DUNGEON","BATTLE")((u){
                healMP( u, 20 );
            });
        }
    });}
    //-------------------------------------------------------------
    //
    //成長
    //
    //-------------------------------------------------------------
    @Value
    static Item  いざなみの命(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("最大HP+1"
            ,Type.成長, /*rank*/9, /*box*/true);

            setUseIn!("FIELD","DUNGEON")((u){
                u.prm!"MAX_HP".base += 1;
            });
        }
    });}
    @Value
    static Item  この花の咲くや姫(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("力+1"
            ,Type.成長, /*rank*/9, /*box*/true);

            setUseIn!("FIELD","DUNGEON")((u){
                u.prm!"STR".base += 1;
            });
        }
    });}
    @Value
    static Item  つくよみの命(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("魔+1"
            ,Type.成長, /*rank*/9, /*box*/true);

            setUseIn!("FIELD","DUNGEON")((u){
                u.prm!"MAG".base += 1;
            });
        }
    });}
    @Value
    static Item  よもつおお神(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("光+1"
            ,Type.成長, /*rank*/9, /*box*/true);

            setUseIn!("FIELD","DUNGEON")((u){
                u.prm!"LIG".base += 1;
            });
        }
    });}
    //-------------------------------------------------------------
    //
    //鍵
    //
    //-------------------------------------------------------------
    //宝物鍵
    @Value
    static Item  丸い鍵(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("丸い箱を開けられる"
            ,Type.宝物鍵, /*rank*/3, /*box*/true);}
    });}
    //-------------------------------------------------------------
    //財宝鍵
    @Value
    static Item  はじまりの丘の財宝の鍵(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super(""
            ,Type.財宝鍵, /*rank*/10, /*box*/false);}
    });}
    @Value
    static Item  見知らぬ海岸の財宝の鍵(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super(""
            ,Type.財宝鍵, /*rank*/10, /*box*/false);}
    });}
    //-------------------------------------------------------------
    //
    //素材
    //
    //-------------------------------------------------------------
    @Value
    static Item  石(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("石だ"
            ,Type.素材, /*rank*/0, /*box*/true);}
    });}
    @Value
    static Item  草(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("草だ"
            ,Type.素材, /*rank*/0, /*box*/true);}
    });}
    @Value
    static Item  泥(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super(""
            ,Type.素材, /*rank*/0, /*box*/true);}
    });}
    @Value
    static Item  枝(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super(""
            ,Type.素材, /*rank*/0, /*box*/true);}
    });}
    @Value
    static Item  腐葉土(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("土"
            ,Type.素材, /*rank*/1, /*box*/true);}
    });}
    @Value
    static Item  ピートモス(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("土"
            ,Type.素材, /*rank*/1, /*box*/true);}
    });}
    //-------------------------------------------------------------
    //
    //メモ
    //
    //-------------------------------------------------------------
    @Value
    static Item  F1のメモ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("F1キーでオプション画面が開く"
            ,Type.メモ, /*rank*/0, /*box*/true);}
        override int getMaxNum(){return 1;}
    });}
    @Value
    static Item  メモのメモ(){static Item res; return res !is null ? res : (res = new class Item{
        this(){super("最強らしい"
            ,Type.メモ, /*rank*/8, /*box*/true);}
        override int getMaxNum(){return 1;}
    });}
    //-------------------------------------------------------------
    //
    //-------------------------------------------------------------
}