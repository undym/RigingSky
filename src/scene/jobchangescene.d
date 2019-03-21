module scene.jobchangescene;

import laziness;
import scene.abstscene;
import job;
import unit;
import widget.btn;
import widget.list;


class JobChangeScene: AbstScene{
    mixin ins;
    //!null
    private PUnit target;
    private Job info;
    private List list;

    private this(){
        list = new List( Util.list_draw_elm_num );
    }

    override void start(){

        foreach(p; Unit.players){
            if(!p.exists){continue;}
            target = p;
            setList( target );
            break;
        }


        setup;
        super.start;
    }

    private void setup(){
        clear;
        
        super.addEsc();
        
        add((g,bounds){
            g.set(Color.BLACK);
            g.fill(bounds);
        });

        add(Bounds.Ratio.BOTTOM, DrawBottom.ins);

        add(Bounds.Ratio.UPPER_LEFT,{
            return new Layout()
                    .add((g,bounds){
                        g.set(Color.L_GRAY);
                        g.line(bounds);
                    })
                    .add(new Labels(Util.font)
                        .setOutsideMargin(2,2,2,2)
                        .add!"top"("-ジョブ-")
                    );
        }());
        add(Bounds.Ratio.BTN, new Layout()
            .add((g,bounds){
                g.set(Color.L_GRAY);
                g.line(bounds);
            })
            .add(new PackedYLayout( Bounds.BTN_H )
                .setOutsideMargin(2,2,2,2)
                .add(new Btn("＞戻る",{
                    end;
                }))
            )
        );
        add(Bounds.Ratio.LIST_MAIN, new BorderLayout()
            .add!("center",0.55)(list)
            .add!("right",0.45)(new VariableLayout({
                static PackedYLayout l;
                static Job info_bak;
                if(info != info_bak){
                    info_bak = info;
                    l = new PackedYLayout( Util.FONT_SIZE );
                    l.add( (new Label(Util.font, format!"[%s]"(info.toString) )).setDrawPoint!"top" );

                    l.add(new Label(Util.font, "成長ボーナス"));
                    foreach(set; info.getGrowingPrms){
                        l.add(new Label(Util.font, format!"  %s:%s"( getPrmName(set.prm), set.value), Color.GREEN) );
                    }

                    l.add(new Labels(Util.font)
                        .addln(()=> info.info)
                    );
                }
                return info is null ? ILayout.empty : l;
            }))
        );

        add(Bounds.Ratio.PLAYER_STATUS_BOXES,(g,bounds)=> drawChoosedUnitFrame(g,target));
        add(Bounds.Ratio.PLAYER_STATUS_BOXES, DrawPlayerStatusBoxes.ins);
        add(Bounds.Ratio.LIST_MAIN_TOP, new FrameLayout());

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
                    setList(p);
                    break;
                }
            }
        });

    }

    private void setList(PUnit p){
        list.clear;

        list.separater(format!"%s"(p.name));
        
        Job.values
            .filter!(job=> job.canJobChange(p) || p.getJobLv(job) > 0)
            .each!((job){
                string name = job.toString;
                if(p.getJobLv(job) >= Job.MAX_LV){name = "★"~name;}

                auto elm = list.add(()=>job.toString
                ,()=> p.getJobLv(job) >= job.MAX_LV ? "★" : format!"%s"( p.getJobLv(job) )
                ,{
                    if(p.job == job){return;}

                    Util.msg.set(format!"%sは[%s]に転職した"( p.name, job ), Color.PINK);
                    p.job = job;
                    setList(p);
                },{
                    info = job;
                });

                if(p.job == job){
                    elm.set!"string"(()=>Color.YELLOW);
                    elm.set!"num"(()=>Color.YELLOW);
                }
            });
    }
}