module scene.meisouscene;

import laziness;
import scene.abstscene;
import unit;
import widget.btn;
import widget.list;

class MeisouScene: AbstScene{
    mixin ins;

    private{
        //!null
        PUnit target;
    }

    private this(){
    }

    override void start(){
        foreach(p; Unit.players){
            if(!p.exists){continue;}

            target = p;
            
            break;
        }

        setup;
        super.start;
    }

    protected void setup(){
        clear;
        
        super.addEsc();
        
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT,{
            return new FrameLayout()
                    .add(new Labels(Util.font)
                        .add!"top"("-瞑想-")
                    );
        }());
        add(Bounds.Ratio.BTN, new FrameLayout()
            .add(new PackedYLayout( Bounds.BTN_H )
                .add(new Btn("＞戻る",{
                    end();
                }))
            )
        );
        
        {
            ILayout createMeisouBtn(Unit.Prm prm, const int add_value){
                void meisou(){
                    if(target.bp <= 0){return;}

                    target.bp--;
                    target.prm(prm).base += add_value;
                }
                return new FrameLayout()
                        .add(ILayout.create((g,bounds){
                            if(bounds.contains( Mouse.point )){
                                g.set(Color.D_CYAN);
                                g.fill(bounds);
                            }
                        }))
                        .add(ILayout.create((bounds){
                            if(!bounds.contains( Mouse.point )){return;}

                            if(Mouse.left == 1){
                                meisou();
                            }else if(Mouse.left > 10 && Window.count % 2 == 0){
                                meisou();
                            }
                        }))
                        .add(new Label(Util.font, ()=> format!"%s:%s +%s"(getPrmName(prm), target.prm(prm).total, add_value)).setDrawPoint!"center")
                        ;
            }

            add(Bounds.Ratio.MAIN, new BorderLayout()
                .add!("top",0.1)(new Label(Util.font, ()=>format!"BP:%.0f"(target.bp)).setDrawPoint!"center")
                .add!("center")(new XLayout()
                    .add(new YLayout()
                        .add( createMeisouBtn(Unit.Prm.MAX_HP, 2) )
                        .add( createMeisouBtn(Unit.Prm.STR, 1) )
                        .add( createMeisouBtn(Unit.Prm.LIG, 1) )
                        .add( createMeisouBtn(Unit.Prm.CHN, 1) )
                        .add( createMeisouBtn(Unit.Prm.GUN, 1) )
                    )
                    .add(new YLayout()
                        .add( ILayout.empty )
                        .add( createMeisouBtn(Unit.Prm.MAG, 1) )
                        .add( createMeisouBtn(Unit.Prm.DRK, 1) )
                        .add( createMeisouBtn(Unit.Prm.PST, 1) )
                        .add( createMeisouBtn(Unit.Prm.ARR, 1) )
                    )
                )
            );
        }

        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(g,bounds)=> drawChoosedUnitFrame(g,target));
        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.ENEMY_STATUS_BOXES, DrawEnemyStatusBoxes.ins);

        add(Bounds.Ratio.UPPER_RIGHT, DrawUpperRight.ins);
        add(Bounds.Ratio.UNIT_DETAIL, DrawUnitDetail.ins);
        add((g,bounds){
            DrawUnitDetail.set( target );
        });

        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(bounds){
            if(Mouse.left != 1){return;}

            foreach(p; Unit.players){
                if(!p.exists){continue;}

                if(p.bounds.contains( Mouse.point )){
                    target = p;
                    
                    break;
                }
            }
        });

    }

}
