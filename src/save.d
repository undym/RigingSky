module save;

import undym.record;
import std.json;


class Save{
    private this(){}

    private enum FILE_PATH = "dat/save";

    static:
        bool exists(){
            static import std.file;
            return std.file.exists( FILE_PATH );
        }
        void save(){
            Record rec = Record.ofSave();
            run( rec );
            rec.flush( FILE_PATH );

            debug{
                import std.file;
                import std.stdio;
                string dec = Record.decrypt( cast(char[])read( FILE_PATH ) );
                File f = File("dat/save_decrypted","w");
                f.write( dec );
                f.close;
            }
        }

        void load(){
            run( Record.ofLoad( FILE_PATH ) );
        }

        private void run(Record rec){
            import dungeon;
            import eq;
            import unit;
            import player;
            import tec;
            import job;
            import util;
            import std.format;
            import std.conv;
            import std.traits: EnumMembers;
            
            int savedata_version_major = Util.GameVersion.major;
            int savedata_version_minor = Util.GameVersion.minor;
            int savedata_version_mente = Util.GameVersion.mente;
            rec.io("version_major", savedata_version_major);
            rec.io("version_minor", savedata_version_minor);
            rec.io("version_mente", savedata_version_mente);

            rec.list("Dungeon",(io){
                foreach(d; Dungeon.values){
                    io.list( d.getUniqueName(),(io_d){
                        io_d.io("clear", d.clear_num);
                        io_d.io("ex", d.killed_ex_num);
                        io_d.io("tresure", d.opened_tresure_num);
                    });
                }
            });
            rec.list("Eq",(io){
                foreach(eq; Eq.values){
                    io.list( eq.getUniqueName(), (io2){
                        io2.io("num", eq.num);
                        io2.io("got", eq.got);
                        io2.io("com", eq.getComposition().exp);
                    });
                }
            });
            rec.list("EqEar",(io){
                foreach(ear; EqEar.values){
                    io.list( ear.getUniqueName(), (io2){
                        io2.io("num", ear.num);
                        io2.io("got", ear.got);
                        io2.io("com", ear.getComposition().exp);
                    });
                }
            });
            rec.list("Player",(io){
                foreach(player; Player.values){
                    io.list( player.getUniqueName(), (io2){
                        PUnit unit = player.ins;
                        //---------------------------------------------------
                        //tec
                        //---------------------------------------------------
                        io2.list("tecs",(io_tec){
                            long len = unit.tecs.length;
                            io_tec.io("length", len);
                            unit.tecs.length = cast(uint)len;

                            foreach(i,t; unit.tecs){
                                string tec_name = t !is null ? t.getUniqueName() : "";
                                io_tec.io( i.to!string, tec_name);
                                unit.tecs[i] = Tec.valueOf( tec_name );
                            }
                        });
                        //---------------------------------------------------
                        //job
                        //---------------------------------------------------
                        {
                            string job_name = unit.job.getUniqueName();
                            io2.io("job", job_name);
                            unit.job = Job.valueOf( job_name );
                        }
                        //---------------------------------------------------
                        //prm
                        //---------------------------------------------------
                        io2.list("prm", (io_prm){
                            foreach(prm; [EnumMembers!(Unit.Prm)]){
                                io_prm.io( prm.to!string, unit.prm(prm).base );
                            }
                        });
                        //---------------------------------------------------
                        //eq
                        //---------------------------------------------------
                        io2.list("eq", (io_eq){
                            foreach(pos; [EnumMembers!(Eq.Pos)]){
                                string eq_name = unit.eq(pos).getUniqueName();
                                io_eq.io( pos.to!string, eq_name );
                                unit.setEq( pos, Eq.valueOf( eq_name ) );
                            }
                        });
                        //---------------------------------------------------
                        //eqear
                        //---------------------------------------------------
                        io2.list("eqear", (io_ear){
                            int num = EqEar.EAR_NUM;
                            io_ear.io("num", num);

                            foreach(i; 0..num){
                                string ear_name = unit.eqEar(i).getUniqueName();
                                io_ear.io( i.to!string, ear_name );
                                unit.setEqEar( i, EqEar.valueOf( ear_name ) );
                            }
                        });
                        //---------------------------------------------------
                        //job_lvs
                        //---------------------------------------------------
                        io2.list("JobExpLv", (io_job_exp_lv){
                            foreach(job; Job.values){
                                io_job_exp_lv.list( job.getUniqueName(), (io_job){
                                    int lv = unit.getJobLv(job);
                                    int exp = unit.getJobExp(job);
                                    io_job.io("lv",  lv);
                                    io_job.io("exp", exp);

                                    unit.setJobLv(job, lv);
                                    unit.setJobExp(job, exp);
                                });
                            }
                        });
                        //---------------------------------------------------
                        //learned_tecs
                        //---------------------------------------------------
                        io2.list("learned_tecs", (io_learned){
                            foreach(tec; Tec.values){
                                bool b = unit.isLearned(tec);
                                io_learned.io( tec.getUniqueName(), b );
                                unit.setLearned( tec, b );
                            }
                        });
                    });
                }
            });
            rec.list("Unit",(io){
                foreach(i,p; Unit.players){
                    string player_name = p.getPlayer.getUniqueName();
                    io.io( i.to!string, player_name );

                    Unit.players[i] = Player.valueOf( player_name ).ins;
                }
            });

            rec.list("Item",(io){
                import item;
                foreach(_item; Item.values){
                    io.list(_item.getUniqueName(),(io_item){
                        io_item.io("num", _item.num);
                        io_item.io("got", _item.got);
                        io_item.io("com", _item.getComposition().exp);
                    });
                }
            });
            
            rec.list("Building",(io){
                import building;
                foreach(b; Building.values){
                    io.io( b.getUniqueName(), b.getComposition().exp );
                }
            });

            rec.list("PlayData",(io){
                import util;
                io.io("yen", PlayData.yen);
            });
        }
}