module goods;

import undym;
import util;

interface IGoods{
    static IGoods empty(){
        static IGoods res;
        if(res is null){
            res = new class IGoods{
                mixin MGoods;
                override string getInfo(){return "";}
            };
        }
        return res;
    }
    ref int num();
    int* numPtr();
    ref bool got();
    string getInfo();
    void add(int);
}


mixin template MGoods(){
    int goods_num;
    bool goods_got;

    override ref int num()      {return goods_num;}
    override int* numPtr()      {return &goods_num;}
    override ref bool got()     {return goods_got;}

    override void add(int get_num){
        if(this == IGoods.empty){return;}
        
        import util;
        import std.format: format;

        bool is_new;
        if(!got){
            got = true;
            is_new = true;
            Util.msg.set("new", cnt=> Color.rainbow(cnt));
        }else{
            Util.msg.set("");
        }

        this.num += get_num;
        Util.msg.add(format!"[%s]を%s個手に入れた(%s)"( this, get_num, this.num), cnt=>Color.GREEN.bright(cnt));

        if(is_new){
            Util.msg.set( getInfo(), cnt=> Color.GREEN.bright(cnt));
        }
    }
}



struct Material{
    private IGoods _goods;
    private int _num;

    IGoods goods(){return _goods;}
    int num(){return _num;}
}



abstract class Composition{

    enum LIMIT_INF = -1;

    static typeof(this) empty(){
        static typeof(this) res;
        if(res is null){
            res = new class Composition{
                this(){super(IGoods.empty, 0, 0, []);}
                override bool isVisible(){return false;}
            };
        }
        return res;
    }
    
    private IGoods result;
    IGoods getResult(){return result;}
    private int result_num;
    int getResultNum(){return result_num;}
    private int limit;
    int getLimit(){return limit;}
    private Material[] materials;
    Material[] getMaterials(){return materials;}

    int exp;

    this(IGoods result, int result_num, int limit, Material[] materials){
        this.result = result;
        this.result_num = result_num;
        this.limit = limit;
        this.materials = materials;
    }

    // bool isVisible(){
    //     if(materials.length == 0){return false;}
    //     return materials[0].goods.num > 0;
    // }

    bool isVisible();

    bool canRun(){
        if(exp >= getLimit() && exp != LIMIT_INF){return false;}
        foreach(m; materials){
            if(m.goods.num < m.num){return false;}
        }
        return true;
    }

    final void run(){
        if(!canRun()){return;}

        foreach(m; materials){
            m.goods.num -= m.num;
        }
        
        result.add( result_num );
        exp++;

        runInner();
    }

    void runInner(){}
}


mixin template Shop(){
    enum NOT_FOR_SALE = 0;
    int getPrice(){return NOT_FOR_SALE;}
}